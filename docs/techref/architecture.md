---
title: Architecture
description: Internal architecture and stream processing flow of docker-rtmp-multistream
audience: developers
doc_type: explanation
tags: [architecture, nginx, rtmp, technical]
lastReviewed: 2026-09-29
version: 1.x
---

# Architecture

This document explains the internal architecture of docker-rtmp-multistream and how it processes and distributes streams.

## Overview

docker-rtmp-multistream is built on nginx with the Real-Time Messaging Protocol (RTMP) module. It receives a single RTMP stream from your streaming software and simultaneously distributes it to multiple destinations with optional per-service transformations.

## Core Components

### nginx RTMP Module

The foundation is **nginx-mod-rtmp**, which provides RTMP server capabilities to nginx. This module handles:

- Receiving RTMP streams on port 1935
- Managing multiple RTMP applications
- Pushing streams to multiple destinations
- Recording streams to disk
- Executing FFmpeg transformers

### Service-Based Architecture

Each streaming destination (service) consists of modular components:

1. **RTMP Application Config** - `build/conf/nginx/http.d/apps/<SERVICE>.conf`
2. **Optional Transformer** - `build/conf/nginx/http.d/transformers/<SERVICE>.conf`
3. **Pre-init Script** - `build/scripts/pre-init.d/90_configure_<SERVICE>.sh`
4. **Environment Variables** - Configures the service and its behavior. Defined in `Dockerfile` and can be overridden in `env/relay.env`

Services are enabled/disabled dynamically at container startup based on configuration.

## Stream Flow

### High-Level Flow

```text
Streaming software (for example OBS Studio)
         ↓
    RTMP stream (port 1935)
         ↓
    relay application
         ↓
    ┌──────────────┬───────────┬───────────┐
    ↓              ↓           ↓           ↓
  Twitch        Twitch      YouTube     Archive
  non-partner   partner     (relay)     (record)
  (FFmpeg →
   twitch app)  (relay)
```

Twitch runs in one of the two modes, never both: `TWITCH_PARTNER` selects which.

### Detailed Request Flow

1. **Stream Reception**: Your streaming software connects to `rtmp://<RELAY_HOST>:1935/relay/<STREAM_NAME>`. The relay accepts any stream name. It is not a service stream key: do not put your Twitch or YouTube key here
2. **Application Routing**: The `relay` application receives the stream
3. **Authorization**: IP-based authentication checks `PUBLISH_IP_RANGE`
4. **Service Processing**:
   - **Simple Relay Services** (YouTube, Twitch partner mode): Stream pushed directly to destination
   - **Transformer Services** (Twitch non-partner mode): an `exec` directive in `relay` runs FFmpeg, which re-encodes the stream and publishes it to the local `twitch` application. That application pushes it to Twitch
   - **Archive Service**: Stream recorded to local disk

## Service Patterns

docker-rtmp-multistream supports two architectural patterns for handling streams: **Simple Relay** and **Transformer**.

For a complete comparison of these patterns (use cases, pros/cons, and examples), see **[Service Patterns Reference](service-patterns.md)**.

### Technical Implementation

**Simple Relay** (e.g., YouTube): Single `apps/<SERVICE>.conf` file, included inside `application relay`, that pushes the stream directly to the destination without modification.

**Transformer** (e.g., Twitch non-partner mode): Two-stage pipeline. `transformers/<SERVICE>.conf` (FFmpeg) is included inside `application relay`. `apps/<SERVICE>.conf` defines a separate application, outside `relay`, that receives FFmpeg's output and pushes it to the destination.

!!! note "Conditional Patterns"
    Some services support both patterns based on configuration. Twitch uses simple relay for partners (`TWITCH_PARTNER=TRUE`) and transformer for non-partners. See [Twitch Configuration](../services/twitch.md#partner-vs-non-partner-streaming).

## Configuration System

### Startup Flow

When the container starts, configuration happens in this order:

```text
1. Docker starts the container with the Dockerfile defaults, overridden by
   env/relay.env when you start it with docker compose (docker-compose.yml
   passes it as env_file)
2. build/scripts/run.sh runs each pre-init script in alphanumeric order:
   a. 89_configure_app.sh - validates PUBLISH_IP_RANGE and the log level,
      fills in app.conf and auth.conf
   b. 90_configure_*.sh - one per service
3. Each service script:
   - Exits 0 without changes if its required variable is empty
   - Validates its variables, and exits 1 if one is invalid
   - Uses sed to replace placeholders in its config
   - Calls enableService.sh to activate the service
4. If any script exits non-zero, run.sh stops the container
5. Otherwise nginx starts with the active services
```

### Configuration Files

**Main Configuration**:
- `nginx.conf` - Loads RTMP module, includes app.conf
- `app.conf` - Defines relay application, commented service includes
- `auth.conf` - IP-based publish authentication

**Service Configurations**:
- `apps/*.conf` - Individual service RTMP applications
- `transformers/*.conf` - FFmpeg transcoding pipelines

### Dynamic Service Enabling

Service includes are commented out in `build/conf/nginx/http.d/app.conf`. The Twitch non-partner lines are:

```nginx
    application relay {
      ...
      # Twitch (Non-Partner - Transformer Pattern)
      #include NGINX_CONFD_DIR/transformers/twitch.conf;
      ...
    }

    # Twitch (Non-Partner - Transformer Destination)
    #include NGINX_CONFD_DIR/apps/twitch.conf;
```

At startup, `89_configure_app.sh` replaces `NGINX_CONFD_DIR` with its value, `/etc/nginx/http.d`. `90_configure_twitch.sh` then runs:

```bash
/scripts/enableService.sh twitch
```

`enableService.sh` removes the `#` from `#include <NGINX_CONFD_DIR>/apps/twitch.conf`, and from the matching `transformers/twitch.conf` line if that file exists. Result:

```nginx
      include /etc/nginx/http.d/transformers/twitch.conf;
    ...
    include /etc/nginx/http.d/apps/twitch.conf;
```

The match is on `#include` with no space, so a new service's lines in `app.conf` must use the same form.

## Environment Variable Processing

### Template Variables

Configuration files use bare placeholder tokens, named after the variable, that are replaced at startup.

**In `build/conf/nginx/http.d/apps/twitch.conf`**:
```nginx
push rtmp://TWITCH_ENDPOINT.contribute.live-video.net/app/TWITCH_KEY;
```

**In `90_configure_twitch.sh`**, after validation, each value is escaped and substituted with `|` as the `sed` delimiter:
```bash
TWITCH_KEY_ESC=$(escape_for_sed "$TWITCH_KEY")
sed -i "s|TWITCH_KEY|$TWITCH_KEY_ESC|g" "${NGINX_CONFD_DIR}/apps/twitch.conf"
```

**After processing**, with `TWITCH_ENDPOINT=use10`:
```nginx
push rtmp://use10.contribute.live-video.net/app/live_123456789_abc;
```

### Layered Defaults

1. **Dockerfile** - Defaults for all variables
2. **env/relay.env** - User overrides, loaded by `docker compose` through `env_file` in `docker-compose.yml`. A plain `docker run` does not read it unless you pass `--env-file env/relay.env`

## Security

For publish authorization with `PUBLISH_IP_RANGE`, input validation, where stream keys end up, and what is not protected, see [Security](../security.md).

## Archive Service

The Archive service modifies the main `relay` application rather than creating a separate app. `90_configure_archive.sh` deletes `record off;` from `app.conf` and enables this include inside `application relay`:

```nginx
recorder all {
    record all;
    record_path ARCHIVE_PATH;
    record_unique on;
    record_suffix _%d%m%Y_%H%M%S.ARCHIVE_SUFFIX;
    record_notify on;
}
```

`ARCHIVE_PATH` and `ARCHIVE_SUFFIX` are replaced with their values at container start. For the resulting file names, see [File Naming](../services/archive.md#file-naming).

Every stream published to the `relay` application is archived, whichever services are enabled. Streams published directly to the `twitch` application are not.

## See Also

- [Service Patterns Reference](service-patterns.md) - Detailed comparison of architectural patterns
- [Change Relay Settings](../configuration.md) - Setup and environment variables
- [Security](../security.md) - Publish authorization, validation, and what is not protected
- [Adding New Streaming Services](../developer/adding-services/overview.md) - Implement new streaming services

---
title: Architecture
description: Internal architecture and stream processing flow of docker-rtmp-multistream
audience: developers
doc_type: explanation
tags: [architecture, nginx, rtmp, technical]
lastReviewed: 2025-10-21
version: 1.x
---

# Architecture Details

This document explains the internal architecture of docker-rtmp-multistream and how it processes and distributes streams.

## Overview

docker-rtmp-multistream is built on nginx with the RTMP module. It receives a single RTMP stream from your streaming software and simultaneously distributes it to multiple destinations with optional per-service transformations.

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

1. **RTMP Application Config** - `build/conf/nginx/http.d/apps/{service}.conf`
2. **Optional Transformer** - `build/conf/nginx/http.d/transformers/{service}.conf`
3. **Pre-init Script** - `build/scripts/pre-init.d/90_configure_{service}.sh`
4. **Environment Variables** - Configures the service and its behavior. Defined in `Dockerfile` and can be overridden in `env/relay.env`

Services are enabled/disabled dynamically at container startup based on configuration.

## Stream Flow

### High-Level Flow

```
Streaming Software (OBS)
         ↓
    RTMP Stream (port 1935)
         ↓
    relay application
         ↓
    ┌────┴────┬────────┬──────────┐
    ↓         ↓        ↓          ↓
  Twitch  YouTube  Archive    [Other]
  (trans)  (relay)  (record)
```

### Detailed Request Flow

1. **Stream Reception**: Your streaming software connects to `rtmp://localhostname:1935/relay/{stream-key}`
2. **Application Routing**: The `relay` application receives the stream
3. **Authorization**: IP-based authentication checks `PUBLISH_IP_RANGE`
4. **Service Processing**:
   - **Simple Relay Services** (YouTube, Twitch partner mode): Stream pushed directly to destination
   - **Transformer Services** (Twitch non-partner mode): Stream passed through FFmpeg, then pushed to destination
   - **Archive Service**: Stream recorded to local disk

## Service Patterns

docker-rtmp-multistream supports two architectural patterns for handling streams: **Simple Relay** and **Transformer**.

For a complete comparison of these patterns (use cases, pros/cons, and examples), see **[Service Patterns Reference](service-patterns.md)**.

### Technical Implementation

**Simple Relay** (e.g., YouTube): Single `apps/{service}.conf` file that pushes the stream directly to the destination without modification.

**Transformer** (e.g., Twitch non-partner mode): Two-stage pipeline using `transformers/{service}.conf` (FFmpeg) and `apps/{service}.conf` (destination push).

!!! note "Conditional Patterns"
    Some services support both patterns based on configuration. Twitch uses simple relay for partners (`TWITCH_PARTNER=TRUE`) and transformer for non-partners. See [Twitch Configuration](../services/twitch.md#partner-vs-non-partner-streaming).

## Configuration System

### Startup Flow

When the container starts, configuration happens in this order:

```
1. Docker starts container
2. Environment variables loaded from env/relay.env
3. Pre-init scripts run (alphanumeric order):
   a. 89_configure_app.sh - Configure main relay app
   b. 90_configure_*.sh - Each service checks config
4. Service scripts:
   - Check if required env vars are set
   - Exit if service shouldn't be enabled
   - Use sed to replace placeholders in config
   - Call enableService.sh to activate
5. nginx starts with active services
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

Services are commented out in `app.conf` by default:

```nginx
# Service: Twitch
# include /etc/nginx/http.d/transformers/twitch.conf;
# include /etc/nginx/http.d/apps/twitch.conf;
```

The `enableService.sh` script uncomments these lines when a service is configured:

```bash
/scripts/enableService.sh twitch
```

Result:
```nginx
# Service: Twitch
include /etc/nginx/http.d/transformers/twitch.conf;
include /etc/nginx/http.d/apps/twitch.conf;
```

## Environment Variable Processing

### Template Variables

Configuration files use placeholder variables (e.g., `{TWITCH_KEY}`) that are replaced at startup:

**In config file**:
```nginx
push rtmp://live-jfk.twitch.tv/app/{TWITCH_KEY};
```

**Pre-init script**:
```bash
sed -i "s#{TWITCH_KEY}#$TWITCH_KEY#g" /path/to/twitch.conf
```

**After processing**:
```nginx
push rtmp://live-jfk.twitch.tv/app/live_123456789_abc;
```

### Layered Defaults

1. **Dockerfile** - Hardcoded defaults for all variables
2. **env/relay.env** - User overrides
3. **docker-compose.yml** - Can override env file (not recommended)

## Security

### IP-Based Authentication

The `PUBLISH_IP_RANGE` variable restricts who can publish streams:

```nginx
# In auth.conf
allow publish {PUBLISH_IP_RANGE};
deny publish all;
```

Default: `192.168.0.0/16` (local network only)

### Stream Keys

Service stream keys are:
- Stored in `env/relay.env` (not committed to git)
- Injected into config at runtime
- Never logged or exposed

## Archive Service

The Archive service modifies the main `relay` application rather than creating a separate app:

```nginx
application relay {
    live on;
    record all;
    record_path {ARCHIVE_PATH};
    record_suffix _{ARCHIVE_SUFFIX};
    # ... transformer and push directives
}
```

This ensures all incoming streams are archived regardless of destination.

## See Also

- [Service Patterns Reference](service-patterns.md) - Detailed comparison of architectural patterns
- [Configuration Overview](../configuration.md) - Setup and environment variables
- [Adding New Streaming Services](../developer/adding-services/overview.md) - Implement new streaming services

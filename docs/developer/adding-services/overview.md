---
title: Add a Streaming Service
description: Add a new streaming destination to the relay, from config files to a verified end-to-end stream
audience: developers
doc_type: howto
tags: [development, services, extending, customization]
lastReviewed: 2026-09-29
version: 1.x
---

# Add a Streaming Service

This guide adds a new streaming destination to the relay. The examples add a service called `example`, with the variables `EXAMPLE_KEY` and `EXAMPLE_INGEST`. Replace these with your service's name.

For the exact rules each file must follow, see the [Service Contract Reference](configuration.md).

## Before You Begin

- Choose a pattern. **Simple Relay** forwards the stream unchanged. **Transformer** re-encodes it with FFmpeg first. See [Service Patterns](../../techref/service-patterns.md).
- Check the service's ingest protocol. nginx's `push` sends plain RTMP. If the service accepts only RTMPS, use the Transformer pattern: the image's FFmpeg supports `rtmps://` output.
- Pick a lowercase service name (`example`) and an uppercase variable prefix (`EXAMPLE_`). The name is used for file names and the `enableService.sh` argument, and they must match exactly.

## Create the Config Files

Placeholders in these files are bare uppercase tokens, which the startup script replaces with `sed`. Do not wrap them in braces: `{EXAMPLE_KEY}` becomes `{abc123}`.

### Simple Relay

Create `build/conf/nginx/http.d/apps/example.conf`. It holds directives only, with no `application` block, because it is included inside `application relay`:

```nginx
include http.d/auth.conf;

push rtmp://EXAMPLE_INGEST/app/EXAMPLE_KEY;
```

Replace `/app/` with the path your service's ingest URL uses.

### Transformer

Create two files. `build/conf/nginx/http.d/transformers/example.conf` is included inside `application relay` and runs FFmpeg for each incoming stream:

```nginx
exec ffmpeg -i rtmp://127.0.0.1/$app/$name
    -c:a aac -b:a 128k
    -c:v libx264 -preset veryfast
    -b:v EXAMPLE_VIDEO_BITRATEk
    -f flv rtmp://127.0.0.1/example/$name;
```

`build/conf/nginx/http.d/apps/example.conf` is a separate application, at server level, that receives FFmpeg's output and pushes it to the service:

```nginx
application example {
    live on;
    record off;

    include http.d/auth.conf;

    push rtmp://EXAMPLE_INGEST/app/EXAMPLE_KEY;
}
```

Keep `include http.d/auth.conf;` in every application block. Without it, the application accepts a publish from any address.

## Add the Includes to app.conf

In `build/conf/nginx/http.d/app.conf`, add commented include lines. Write `#include` with no space, and keep the literal `NGINX_CONFD_DIR` token.

For Simple Relay, add one line inside `application relay`, after the existing services:

```nginx
    application relay {
      ...
      # Example (Simple Relay)
      #include NGINX_CONFD_DIR/apps/example.conf;
    }
```

For Transformer, add the transformer line inside `application relay`, and the app line after `application relay` closes:

```nginx
    application relay {
      ...
      # Example (Transformer)
      #include NGINX_CONFD_DIR/transformers/example.conf;
    }

    # Example (Transformer Destination)
    #include NGINX_CONFD_DIR/apps/example.conf;
```

## Add the Variables

1. In `Dockerfile`, add a default for each variable. Leave the key empty so the service is off by default:

    ```dockerfile
    ENV EXAMPLE_INGEST=live.example.com
    ENV EXAMPLE_KEY=""
    ```

2. In `env/relay.env.example`, add the same variables under a comment, so users can find them. Leave the key uncommented and empty, and comment out every other variable at its default:

    ```bash
    # Example
    EXAMPLE_KEY=
    # EXAMPLE_INGEST=live.example.com
    ```

## Write the Startup Script

Create `build/scripts/pre-init.d/90_configure_example.sh`:

```bash
#!/usr/bin/env sh
set -e

# Source validation functions
. /scripts/validate_input.sh

if [ -z "$EXAMPLE_KEY" ]; then
  echo "EXAMPLE_KEY is not set. Skipping Example configuration."
  exit 0
fi

# Validate inputs
validate_stream_key "$EXAMPLE_KEY" "EXAMPLE_KEY" || exit 1
validate_identifier "$EXAMPLE_INGEST" "EXAMPLE_INGEST" || exit 1

# Escape values for safe sed substitution
EXAMPLE_KEY_ESC=$(escape_for_sed "$EXAMPLE_KEY")

sed -i "s|EXAMPLE_KEY|$EXAMPLE_KEY_ESC|g" "${NGINX_CONFD_DIR}/apps/example.conf"
sed -i "s|EXAMPLE_INGEST|$EXAMPLE_INGEST|g" "${NGINX_CONFD_DIR}/apps/example.conf"

/scripts/enableService.sh example

echo "Example configuration complete, and service enabled."
```

Choose a validator for each variable from the [Input Validation Reference](../validation.md). `validate_identifier` accepts letters, digits, `-` and `_` only; for a host name with dots, add a validator and test it (see [Test a New Service](testing.md#test-a-new-validator)).

For a Transformer, validate its encoder variables too, compute any derived values, and substitute them into the transformer file:

```bash
validate_number "$EXAMPLE_FPS" "EXAMPLE_FPS" 1 120 || exit 1
validate_number "$EXAMPLE_KBITS_PER_VIDEO_FRAME" "EXAMPLE_KBITS_PER_VIDEO_FRAME" 1 1000 || exit 1

EXAMPLE_VIDEO_BITRATE=$(( EXAMPLE_KBITS_PER_VIDEO_FRAME * EXAMPLE_FPS ))

sed -i "s|EXAMPLE_VIDEO_BITRATE|$EXAMPLE_VIDEO_BITRATE|g" "${NGINX_CONFD_DIR}/transformers/example.conf"
```

`enableService.sh example` enables `transformers/example.conf` automatically when that file exists.

Make the script executable:

```bash
chmod +x build/scripts/pre-init.d/90_configure_example.sh
```

## Add Tests

Add unit, integration and, for a new validator, validation tests. See [Test a New Service](testing.md).

## Build and Confirm

1. Run the test suites. `test.sh` builds `rtmp-multistream:test` from your working tree first:

    ```bash
    ./tests/test.sh
    ```

    The run ends with `All tests passed!`.

2. Start a container with your service enabled, then check that it enabled and that nginx accepts the config:

    ```bash
    docker run -d --name example-check -e EXAMPLE_KEY=test_key rtmp-multistream:test
    docker logs example-check 2>&1 | grep -iE "example|error"
    docker exec example-check nginx -t
    docker exec example-check grep -n "example.conf" /etc/nginx/http.d/app.conf
    docker rm -f example-check
    ```

    Expected: `Example configuration complete, and service enabled.`, `test is successful`, and each `example.conf` include line without a leading `#`. If the container has stopped with an `ERROR:` line from `enableService.sh`, the file name or the marker in `app.conf` does not match: see [Include Markers](configuration.md#include-markers).

3. Stream end to end with your real key. Build with `docker compose build`, then set `EXAMPLE_KEY` in `env/relay.env` and start with `docker compose up -d --force-recreate`. Publish a test pattern:

    ```bash
    ffmpeg -re -f lavfi -i testsrc=size=1280x720:rate=30 -f lavfi -i sine -t 60 -c:v libx264 -c:a aac -f flv rtmp://localhost:1935/relay/test
    ```

    The stream appears in your service's dashboard. `env/relay.env` is ignored by git, so the key stays out of your commit.

## Document the Service

1. Create `docs/services/example.md`, following `docs/services/youtube.md`: overview, enable steps with a confirm step, and settings.
2. Add each variable to the [Environment Variables Reference](../../techref/environment.md).
3. Add the page to the `nav` in `mkdocs.yml`.

## See Also

- [Service Contract Reference](configuration.md) - Rules for includes, placeholders, scripts and `enableService.sh`
- [Test a New Service](testing.md) - Tests to add for a new service
- [Input Validation Reference](../validation.md) - Validation functions for a new service's variables
- [Architecture](../../techref/architecture.md) - How the relay processes configuration

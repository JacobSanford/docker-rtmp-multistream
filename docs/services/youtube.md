---
title: Stream to YouTube
description: Enable the YouTube service, which forwards your stream without re-encoding
audience: users
doc_type: howto
tags: [youtube, streaming, relay, passthrough]
lastReviewed: 2026-09-25
version: 1.x
---

# Stream to YouTube

## Overview

The relay forwards your stream to YouTube unchanged, using the **simple relay pattern**. YouTube receives your original quality to reprocess.

## Enable YouTube

1. In `env/relay.env`, set `YOUTUBE_KEY` to the stream key provided by YouTube.
2. Recreate the container so it reads the new values:

    ```bash
    docker compose up -d --force-recreate
    ```

3. Confirm the service is enabled:

    ```bash
    docker compose logs relay | grep -iE "youtube|error"
    ```

    Expected output: `YouTube configuration complete, and service enabled.`

    If you see `YOUTUBE_KEY is not set. Skipping YouTube configuration.`, check step 1. If you see an `ERROR:` line, the container has stopped: correct the variable it names.

## Settings

`YOUTUBE_KEY` is the only YouTube variable. For its valid values, see [YouTube Variables](../techref/environment.md#youtube-variables).

## A Note on YouTube's Re-encoding

YouTube re-encodes every video it receives, including live streams.

A low-bitrate stream that looks acceptable on Twitch often looks distorted after YouTube re-encodes it. For the best results, send YouTube the highest quality and bitrate you can.

Refer to the [Quality Optimization Guide](../performance/quality.md) and [Bandwidth Requirements](../performance/bandwidth.md) for:

- Bitrate recommendations
- Resolution and framerate considerations
- Bandwidth requirements

## See Also

- **[Quality Optimization](../performance/quality.md)** - Stream quality optimization
- **[Bandwidth Requirements](../performance/bandwidth.md)** - Network bandwidth guidance
- **[Architecture](../techref/architecture.md)** - Learn about relay patterns
- **[Quick Start](../quickstart.md)** - Initial setup instructions

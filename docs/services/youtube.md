---
title: YouTube Service
description: Configure YouTube streaming with direct pass-through
audience: users
doc_type: howto
tags: [youtube, streaming, relay, passthrough]
lastReviewed: 2025-10-21
version: 1.x
---

# YouTube

## Overview

The relay streams to YouTube using direct pass-through. To enable this feature, set the `YOUTUBE_KEY` environment variable in the `env/relay.env` file to the stream key provided by YouTube.

The YouTube relay uses a **simple relay pattern** - it forwards your stream directly to YouTube without any re-encoding or modification. This preserves your original stream quality for YouTube's reprocessing.

## Configuration

The YouTube service can be configured by setting the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `YOUTUBE_KEY` | The stream key provided by YouTube. | `` |

## A Note on YouTube's Re-encoding

YouTube reprocesses every video it receives, including live streams. This means YouTube applies its own encoding to your stream after receiving it.

Streams that appear acceptable at lower bitrates on platforms like Twitch will often appear distorted on YouTube after YouTube's re-encoding process. Ensure you send YouTube as high-quality/bitrate of a stream as possible to obtain the best results.

Refer to the [Quality Optimization Guide](../performance/quality.md) and [Bandwidth Requirements](../performance/bandwidth.md) for:

- Bitrate recommendations
- Resolution and framerate considerations
- Bandwidth requirements

## See Also

### Related Documentation

- **[Quality Optimization](../performance/quality.md)** - Stream quality optimization
- **[Bandwidth Requirements](../performance/bandwidth.md)** - Network bandwidth guidance
- **[Architecture](../techref/architecture.md)** - Learn about relay patterns
- **[Quick Start Guide](../quickstart.md)** - Initial setup instructions

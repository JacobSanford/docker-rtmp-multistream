---
title: Service Patterns
description: Understanding Simple Relay and Transformer patterns for RTMP streaming
audience: developers
doc_type: explanation
tags: [architecture, patterns, relay, transformer]
lastReviewed: 2026-09-25
version: 1.x
---

# Service Patterns

This document explains the two primary architectural patterns used in docker-rtmp-multistream for handling RTMP streams to different platforms.

## Pattern Comparison

Choose the appropriate pattern for your service:

|                      | Simple Relay                | Transformer                                      |
|----------------------|-----------------------------|--------------------------------------------------|
| **Use for**          | Services that accept streams as-is (e.g., YouTube) | Services requiring specific encoding (e.g., Twitch non-partner mode) |
| **How it works**     | Stream forwarded directly without modification | Two-stage pipeline with FFmpeg transformation     |
| **Pros**             | No decoding or encoding, so little CPU use and the original quality is preserved | Per-service quality control, downscaling for bandwidth limits |
| **Cons**             | No per-service quality control | Decodes and re-encodes every frame: CPU use scales with `TWITCH_HEIGHT`, `TWITCH_FPS` and `TWITCH_X264_PRESET`. Encoding adds delay before the stream reaches the service. |
| **Example**          | YouTube service              | Twitch service in non-partner mode (720p60 downscaling) |

!!! tip "Advanced: Conditional Patterns"
    Services can support both patterns based on configuration. The Twitch service implements a conditional pattern: partners use simple relay (`TWITCH_PARTNER=TRUE`), non-partners use transformer mode. See Twitch implementation for an advanced example.

## Implementation Examples

### Simple Relay (YouTube)
- Config: [`apps/youtube.conf`](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/conf/nginx/http.d/apps/youtube.conf){target="_blank"}
- Script: [`90_configure_youtube.sh`](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/scripts/pre-init.d/90_configure_youtube.sh){target="_blank"}
- Docs: [YouTube Configuration](../services/youtube.md)

### Transformer (Twitch)
- Transformer: [`transformers/twitch.conf`](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/conf/nginx/http.d/transformers/twitch.conf){target="_blank"}
- App: [`apps/twitch.conf`](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/conf/nginx/http.d/apps/twitch.conf){target="_blank"}
- Script: [`90_configure_twitch.sh`](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/scripts/pre-init.d/90_configure_twitch.sh){target="_blank"}
- Docs: [Twitch Configuration](../services/twitch.md)

## See Also

- [Architecture Overview](architecture.md) - Detailed technical implementation
- [Adding Services Overview](../developer/adding-services/overview.md) - Step-by-step implementation guide
- [Service Configuration](../developer/adding-services/configuration.md) - Configuration details

---
title: Choose a Streaming Service
description: Comparison of supported streaming services and their characteristics
audience: users
doc_type: reference
tags: [services, twitch, youtube, archive, comparison]
lastReviewed: 2026-09-25
version: 1.x
---

# Choose a Streaming Service

docker-rtmp-multistream supports multiple streaming destinations with different performance characteristics.

## Supported Services

| Service | Pattern | CPU Usage | Bandwidth | Quality Control | Best For |
|---------|---------|-----------|-----------|-----------------|----------|
| [Twitch](twitch.md) | Conditional¹ | Minimal/High | High/Moderate | Passthrough/Full control | Partners: max quality. Non-partners: optimization |
| [YouTube](youtube.md) | Simple Relay | Minimal | High | Source passthrough | Maximum quality, leveraging YouTube's re-encoding |
| [Archive](archive.md) | Recorder² | Minimal | None (disk I/O) | Source passthrough | Local backup, video on demand (VOD) creation |

¹ Twitch pattern depends on `TWITCH_PARTNER` setting - see [Twitch Configuration](twitch.md#partner-vs-non-partner-streaming)

² Archive is not a relay. It records every stream the `relay` application receives to disk, with no re-encoding. See [Archive Service](../techref/architecture.md#archive-service).

## Service Patterns

Destination services use one of two architectural patterns: **Simple Relay** (direct forwarding) or **Transformer** (FFmpeg re-encoding). Archive is a recorder and uses neither.

For a detailed comparison of these patterns, see **[Service Patterns Reference](../techref/service-patterns.md)**.

## Adding Custom Services

Want to add support for another streaming platform? See the [Add a Streaming Service](../developer/adding-services/overview.md).

## See Also

- [Service Patterns Reference](../techref/service-patterns.md) - Detailed comparison of architectural patterns
- [Architecture](../techref/architecture.md) - Technical system overview

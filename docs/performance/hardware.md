---
title: Hardware Requirements
description: CPU and processing requirements for stream encoding
audience: users
doc_type: explanation
tags: [performance, cpu, hardware, encoding, ffmpeg]
lastReviewed: 2025-11-05
version: 1.x
---

# Hardware Requirements

This page covers CPU and processing requirements for docker-rtmp-multistream.

## CPU Considerations

### General Guidance

Stream encoding performance depends on available CPU resources:

- **More cores/threads = better performance** for video encoding
- **Higher clock speeds** improve encoding efficiency
- **Relay-only services** (no encoding) require minimal CPU

### Encoding Impact

Services that re-encode video are CPU-intensive. Re-encoding processes your entire stream in real-time, which requires substantial processing power.

**Simple relay** (no encoding): Minimal CPU usage - nginx forwards streams without processing them.

**With encoding**: Moderate to high CPU usage - FFmpeg re-encodes the video, which is computationally expensive.

!!! example "Service Patterns"
    **Twitch** uses FFmpeg re-encoding for non-partners. Partners can use simple relay mode (no encoding). See [Twitch Configuration](../services/twitch.md) for details.

    **YouTube** uses simple relay (no encoding). See [YouTube Configuration](../services/youtube.md) for details.

## FFmpeg Thread Management

The `TWITCH_FFMPEG_THREADS` environment variable controls how many CPU threads FFmpeg uses:

- `0` (default): FFmpeg automatically optimizes thread usage based on available CPU
- `N` (specific number): Limits FFmpeg to N threads

**When to limit threads**:

- Running multiple encoding services simultaneously
- Sharing CPU with other applications
- Preventing one service from monopolizing CPU resources

## Encoder Presets

The x264 encoder preset controls the balance between encoding speed and output quality:

- **Faster presets** (`ultrafast`, `veryfast`, `fast`): Lower CPU usage, slightly reduced quality
- **Slower presets** (`medium`, `slow`, `slower`): Higher CPU usage, better quality

!!! tip "CPU-Constrained Systems"
    If encoding causes CPU bottlenecks, switch to faster presets. The quality difference is often minimal for streaming content.

For Twitch encoding settings, see [Twitch Configuration](../services/twitch.md).

## See Also

- [Bandwidth Requirements](bandwidth.md) - Network considerations
- [Quality Optimization](quality.md) - Stream quality tuning
- [Twitch Configuration](../services/twitch.md) - Twitch-specific encoding settings
- [Services Overview](../services/overview.md) - Service pattern comparison

---
title: Twitch Service
description: Configure Twitch streaming with automatic transcoding and optimization
audience: users
doc_type: howto
tags: [twitch, streaming, transformer, transcoding, quality, partner, relay]
lastReviewed: 2025-11-06
version: 1.x
---

# Twitch

## Overview
The relay streams to Twitch. To enable this feature, set the `TWITCH_KEY` environment variable in the `env/relay.env` file to the stream key provided by Twitch. How you configure the Twitch service depends on whether you are a Twitch Partner or not.

## Partner vs. Non-Partner Streaming
Twitch partners with transcoding services should send higher-bitrate streams to take advantage of Twitch's multi-bitrate transcoding. Non-partners should use the relay's built-in transcoding to optimize their streams for Twitch.

## Partner Streaming
For Twitch Partners, the Twitch relay uses a **simple relay pattern** - it forwards your stream directly to Twitch without any re-encoding or modification. This preserves your original stream quality for Twitch's transcoding services.

### Configuration (Partners)

| Variable | Description | Default |
|----------|-------------|---------|
| `TWITCH_KEY` | The stream key provided by Twitch. | `` |
| `TWITCH_PARTNER` | Boolean flag to indicate if the user is a Twitch Partner. | `FALSE` |
| `TWITCH_ENDPOINT` | The Twitch ingest server slug to use. See the [Recommended Ingest Endpoints](https://help.twitch.tv/s/twitch-ingest-recommendation?language=en_US){target="_blank"} or the [complete endpoint list](../techref/environment.md#twitch_endpoint). | `jfk` |

All other Twitch-related environment variables are ignored when using the partner configuration.

## Non-Partner Streaming
For non-partners, the Twitch relay uses a **transformer pattern** - it re-encodes the incoming stream using FFmpeg before forwarding it to Twitch. This allows you to send a high-quality stream from your streaming software while the relay optimizes it for Twitch's requirements.

### Configuration (Non-Partners)

The Twitch service can be configured by setting the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `TWITCH_KEY` | The stream key provided by Twitch. | `` |
| `TWITCH_AUDIO_BITRATE` | The audio bitrate for the stream. 160k is the Maximum audio bit rate supported by Twitch. | `160k` |
| `TWITCH_CODEC` | The codec to use for the stream. This is unlikely to change. | `libx264` |
| `TWITCH_ENDPOINT` | The Twitch ingest server slug to use. See the [Recommended Ingest Endpoints](https://help.twitch.tv/s/twitch-ingest-recommendation?language=en_US){target="_blank"} or the [complete endpoint list](../techref/environment.md#twitch_endpoint). | `jfk` |
| `TWITCH_FFMPEG_THREADS` | The number of CPU threads to use for encoding. The default `0` instructs FFmpeg to auto-optimize. | `0` |
| `TWITCH_FPS` | The frames per second for the stream. | `60` |
| `TWITCH_HEIGHT` | The height of the video stream in pixels. | `720` |
| `TWITCH_KBITS_PER_VIDEO_FRAME` | The number of kilobits per video frame. Change this to control the bitrate of the video stream. See `TWITCH_KBITS_PER_VIDEO_FRAME` below. | `75` |
| `TWITCH_X264_PRESET` | The x264 preset to use for encoding. A list of options is available [in the x264 documentation](https://trac.ffmpeg.org/wiki/Encode/H.264){target="_blank"}. 'Slower' presets increase computational costs but typically provide higher quality output at the same bitrate. Slower than `medium` generally offers rapidly diminishing returns. | `medium` |

### Optimizing Twitch Quality

For non-partners, viewers may only be able to watch your stream at the quality you transmit. High-bandwidth streams may be unwatchable for viewers with slower connections.

Twitch provides a [guide](https://help.twitch.tv/s/article/broadcasting-guidelines?language=en_US){target="_blank"} on encoding settings. Key points:

- **Maximum video bitrate**: 6000 kbps (even for 1080p/60fps)
- **Transcoding availability**: [Twitch does not reliably transcode streams for non-partners](https://help.twitch.tv/s/article/transcoding-options-faq?language=en_US){target="_blank"}

### Recommended Bitrates

#### TWITCH_KBITS_PER_VIDEO_FRAME

This setting controls the video bitrate using the formula: `bitrate = TWITCH_KBITS_PER_VIDEO_FRAME * FPS`

Recommended starting values:
- **1080p streams**: `100`
- **720p streams**: `75`

If your stream is pixelated or blurry, increase this value. If you are dropping frames, decrease it.

#### Bitrate Reference Table

| Resolution | FPS | Video Bitrate | TWITCH_KBITS_PER_VIDEO_FRAME |
|------------|-----|---------------|------------------------------|
| 1920x1080 | 60 | 6000 Kbps | `100` |
| 1920x1080 | 50 | 5000 Kbps | `100` |
| 1920x1080 | 30 | 3000 Kbps | `100` |
| 1920x1080 | 25 | 2500 Kbps | `100` |
| 1280x720 | 60 | 4500 Kbps | `75` |
| 1280x720 | 50 | 3750 Kbps | `75` |
| 1280x720 | 30 | 2250 Kbps | `75` |
| 1280x720 | 25 | 1875 Kbps | `75` |

## See Also

- [Architecture](../techref/architecture.md) - Learn more about the transformer pattern
- [Environment Variables Reference](../techref/environment.md) - Complete variable reference
- [Troubleshooting](../troubleshooting/index.md) - Common quality and performance issues

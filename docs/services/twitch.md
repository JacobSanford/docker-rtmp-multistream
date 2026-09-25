---
title: Stream to Twitch
description: Enable the Twitch service in partner or non-partner mode and tune its output
audience: users
doc_type: howto
tags: [twitch, streaming, transformer, transcoding, quality, partner, relay]
lastReviewed: 2026-09-25
version: 1.x
---

# Stream to Twitch

## Overview
The relay streams to Twitch. How you configure the Twitch service depends on whether you are a Twitch Partner or not.

## Enable Twitch

1. In `env/relay.env`, set `TWITCH_KEY` to the stream key provided by Twitch.
2. Partners only: set `TWITCH_PARTNER=TRUE`.
3. Recreate the container so it reads the new values:

    ```bash
    docker compose up -d --force-recreate
    ```

4. Confirm the service is enabled:

    ```bash
    docker compose logs relay | grep Twitch
    ```

    Non-partner output: `Twitch Non-Partner configuration complete, and service enabled.`

    Partner output: `Twitch Partner configuration complete, and service enabled.`

    If you see `TWITCH_KEY is not set. Skipping Twitch configuration.`, check step 1.

## Partner vs. Non-Partner Streaming

Twitch partners with transcoding services should send higher-bitrate streams to take advantage of Twitch's multi-bitrate transcoding. Non-partners should use the relay's built-in transcoding to optimize their streams for Twitch.

- **Partner mode** (`TWITCH_PARTNER=TRUE`) uses the **simple relay pattern**: the relay forwards your stream to Twitch without re-encoding it. Only `TWITCH_KEY` and `TWITCH_ENDPOINT` apply; all other Twitch variables are ignored.
- **Non-partner mode** (the default) uses the **transformer pattern**: the relay re-encodes the stream with FFmpeg before forwarding it, so you can send a high-quality stream from your streaming software while the relay produces one suited to Twitch.

## Settings

Choose `TWITCH_ENDPOINT` from the [current endpoint list](../techref/environment.md#twitch_endpoint). In non-partner mode, the encoder settings (`TWITCH_HEIGHT`, `TWITCH_FPS`, `TWITCH_KBITS_PER_VIDEO_FRAME`, `TWITCH_X264_PRESET`, `TWITCH_AUDIO_BITRATE`, `TWITCH_AUDIO_CHANNELS`, `TWITCH_FFMPEG_THREADS`) control the output.

For every Twitch variable's default and valid values, see [Twitch Variables](../techref/environment.md#twitch-variables).

### Fixed Output Settings

The transformer always applies these settings. No variable changes them.

| Property | Value |
|----------|-------|
| Audio codec | AAC, 44.1 kHz |
| Video codec | H.264, Main profile, 4:2:0 (`yuv420p`) |
| Rate control | Constant bitrate (CBR) |
| Keyframe interval | 2 seconds (`2 × TWITCH_FPS` frames), no scene-cut keyframes |

### Optimizing Twitch Quality

For non-partners, viewers may only be able to watch your stream at the quality you transmit. High-bandwidth streams may be unwatchable for viewers with slower connections, and [Twitch does not reliably transcode streams for non-partners](https://help.twitch.tv/s/article/transcoding-options-faq?language=en_US){target="_blank"}.

Twitch publishes its bitrate and encoder limits in its [Broadcasting Guidelines](https://help.twitch.tv/s/article/broadcasting-guidelines?language=en_US){target="_blank"}. Check them before raising `TWITCH_KBITS_PER_VIDEO_FRAME` or `TWITCH_AUDIO_BITRATE` above the defaults.

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

---
title: Quality Optimization
description: Choose resolution, frame rate and bitrate for each service, and what each relay setting changes
audience: users
doc_type: explanation
tags: [quality, optimization, resolution, bitrate, frame-rate]
lastReviewed: 2026-09-29
version: 1.x
---

# Quality Optimization

This page explains which settings control the quality each service receives, and how to choose them for your content.

## Where Quality Is Set

- **YouTube, Twitch partner mode (`TWITCH_PARTNER=TRUE`) and Archive** receive your streaming software's output unchanged. Set resolution, frame rate and bitrate in your streaming software. No relay variable changes them.
- **Twitch non-partner mode** (the default) re-encodes the stream. Four variables set its output: `TWITCH_HEIGHT`, `TWITCH_FPS`, `TWITCH_KBITS_PER_VIDEO_FRAME` and `TWITCH_X264_PRESET`.

The rest of this page covers Twitch non-partner mode.

## How the Twitch Settings Interact

The video bitrate is:

```text
video kbps = TWITCH_KBITS_PER_VIDEO_FRAME × TWITCH_FPS
```

The encoder holds this rate constant. From that:

- **`TWITCH_HEIGHT` does not change the bitrate.** A higher resolution spreads the same bits over more pixels, so each frame gets less detail per pixel.
- **`TWITCH_FPS` changes the bitrate.** Halving it with the same `TWITCH_KBITS_PER_VIDEO_FRAME` halves the bitrate.
- **The relay scales to `TWITCH_HEIGHT` whatever your source is.** With a 720p source, `TWITCH_HEIGHT=1080` upscales, which adds no detail.
- **`TWITCH_X264_PRESET`** changes CPU use and how efficiently the bitrate is used, not the bitrate. See [Encoder Presets](hardware.md#encoder-presets).

## Content-Specific Settings

### Fast Motion

**Examples**: first-person shooters, racing games, fast-paced action, streaming from a phone or camera on the move

Keep the frame rate high and accept a lower resolution. The defaults do this: `TWITCH_HEIGHT=720`, `TWITCH_FPS=60`, `TWITCH_KBITS_PER_VIDEO_FRAME=75`, for 4500 kbps.

### Fine Detail, Little Motion

**Examples**: strategy games, puzzle games, art streams, slow-paced content

Raise the resolution and lower the frame rate. Raise `TWITCH_KBITS_PER_VIDEO_FRAME` at the same time, or the bitrate falls:

| `TWITCH_HEIGHT` | `TWITCH_FPS` | `TWITCH_KBITS_PER_VIDEO_FRAME` | Video bitrate |
|---|---|---|---|
| 720 | 60 | 75 (defaults) | 4500 kbps |
| 1080 | 30 | 75 | 2250 kbps: half the default bitrate for 2.25 times the pixels per frame |
| 1080 | 30 | 100 | 3000 kbps |
| 1080 | 30 | 150 | 4500 kbps: the same bitrate as the defaults |

Before raising the bitrate above the default, check Twitch's limits in its [Broadcasting Guidelines](https://help.twitch.tv/s/article/broadcasting-guidelines?language=en_US){target="_blank"}. For more combinations, see the [Bitrate Reference Table](../services/twitch.md#bitrate-reference-table).

## Balancing Quality and Resources

- **Upload-constrained**: lower `TWITCH_KBITS_PER_VIDEO_FRAME` or `TWITCH_FPS`. Lowering `TWITCH_HEIGHT` alone does not reduce upload. See [Bandwidth Requirements](bandwidth.md).
- **CPU-constrained**: use a faster `TWITCH_X264_PRESET`, or lower `TWITCH_HEIGHT` or `TWITCH_FPS`. See [CPU Considerations](hardware.md).

## See Also

- [Bandwidth Requirements](bandwidth.md) - Upload and disk space
- [CPU Considerations](hardware.md) - CPU cost of Twitch re-encoding
- [Stream to Twitch](../services/twitch.md) - Twitch settings and bitrate reference table
- [Services Overview](../services/overview.md) - Service pattern comparison

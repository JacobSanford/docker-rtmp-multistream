---
title: CPU Considerations
description: Which services use CPU, and the settings that change how much Twitch re-encoding uses
audience: users
doc_type: explanation
tags: [performance, cpu, hardware, encoding, ffmpeg]
lastReviewed: 2026-09-29
version: 1.x
---

# CPU Considerations

This page explains which services use CPU and the settings that change how much Twitch re-encoding uses. It gives no minimum CPU figure: the load depends on your resolution, frame rate, preset and processor. To see the load on your host, run `docker stats` while you stream.

## Which Services Use CPU

Only Twitch non-partner mode (the default) re-encodes video. It runs FFmpeg with the x264 encoder for as long as you publish, and this is where nearly all of the relay's CPU use comes from.

These services forward the stream without re-encoding it, and use little CPU:

- YouTube
- Twitch partner mode (`TWITCH_PARTNER=TRUE`)
- Archive

For the two Twitch modes, see [Partner vs. Non-Partner Streaming](../services/twitch.md#partner-vs-non-partner-streaming).

## Settings That Change CPU Use

These apply to Twitch non-partner mode only.

- **`TWITCH_HEIGHT` and `TWITCH_FPS`**: the encoder processes every output pixel of every frame, so a higher resolution or frame rate costs more CPU.
- **`TWITCH_X264_PRESET`**: see [Encoder Presets](#encoder-presets).
- **`TWITCH_FFMPEG_THREADS`**: see [FFmpeg Thread Management](#ffmpeg-thread-management).

## FFmpeg Thread Management

The `TWITCH_FFMPEG_THREADS` environment variable controls how many threads the libx264 encoder uses in Twitch non-partner mode:

- `0` (default): x264 chooses based on the CPU count
- `N` (1 to 64): x264 uses N threads

Limit threads when the relay shares a host with other CPU-heavy work. Only Twitch non-partner mode encodes; YouTube, Archive and Twitch partner mode use almost no CPU, so there is nothing to balance between services.

## Encoder Presets

`TWITCH_X264_PRESET` sets the x264 preset. From fastest to slowest, the valid values are:

`ultrafast`, `superfast`, `veryfast`, `faster`, `fast`, `medium` (default), `slow`, `slower`, `veryslow`, `placebo`

A faster preset uses less CPU. The encoder runs at a constant bitrate, so a faster preset does not lower the bitrate: it compresses less efficiently, and quality at that bitrate drops.

If FFmpeg cannot keep up with your settings, try one preset faster, then lower `TWITCH_HEIGHT` or `TWITCH_FPS`.

!!! warning "Preset typos are not caught at startup"
    The relay checks only that the preset contains letters, digits, `-` and `_`. A misspelled preset such as `mediun` passes the startup check, and FFmpeg fails with `invalid preset 'mediun'` when you first publish. See [Twitch Issues](../troubleshooting/services/twitch.md).

## See Also

- [Bandwidth Requirements](bandwidth.md) - Upload and disk space
- [Quality Optimization](quality.md) - Choosing Twitch resolution, frame rate and bitrate
- [Stream to Twitch](../services/twitch.md) - Twitch-specific encoding settings
- [Services Overview](../services/overview.md) - Service pattern comparison

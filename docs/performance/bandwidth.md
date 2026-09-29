---
title: Bandwidth Requirements
description: Work out the upload bandwidth and disk space your enabled services need
audience: users
doc_type: explanation
tags: [performance, bandwidth, network, upload, disk]
lastReviewed: 2026-09-29
version: 1.x
---

# Bandwidth Requirements

This page shows how to work out the upload bandwidth the relay host needs for the services you enable, and the disk space Archive uses.

!!! warning "The relay sends one stream per service"
    The relay sends a separate copy of your stream to each enabled service at the same time. The relay host's upload must carry the sum of all of them.

## What Counts as Upload

Your streaming software sends one stream to the relay. The relay sends one stream to each enabled service.

- **Relay on your local network** (the default: `PUBLISH_IP_RANGE` admits the Docker networks and `192.168.0.0/16`): the stream from your streaming software to the relay stays on your local network. Only the relay's outgoing streams use your internet upload.
- **Relay on a remote host**: your streaming software's stream to the relay also crosses your internet upload, and the relay host's own upload carries the outgoing streams.

## Bitrate per Service

The source bitrate is the video plus audio bitrate set in your streaming software.

| Service | Bitrate sent |
|---|---|
| YouTube | Source bitrate. The stream is passed through unchanged |
| Twitch partner mode (`TWITCH_PARTNER=TRUE`) | Source bitrate. The stream is passed through unchanged |
| Twitch non-partner mode (the default) | `TWITCH_KBITS_PER_VIDEO_FRAME × TWITCH_FPS` kbps of video, plus `TWITCH_AUDIO_BITRATE`. With the defaults, `75 × 60 = 4500` kbps plus `160` kbps: 4660 kbps |
| Archive | No network traffic, unless `ARCHIVE_PATH` is on a network mount |

`TWITCH_HEIGHT` does not change the Twitch bitrate. The encoder uses constant bitrate, so the rate depends only on `TWITCH_KBITS_PER_VIDEO_FRAME` and `TWITCH_FPS`.

These figures exclude RTMP and TCP overhead.

## Example Calculation

Source: 6000 kbps video and 160 kbps audio, 6160 kbps in all. YouTube and Twitch (non-partner, default settings) are enabled.

- **Relay on your local network**: 6160 (YouTube) + 4660 (Twitch) = 10820 kbps, about 10.8 Mbps of upload.
- **Relay on a remote host**: add the 6160 kbps source stream on your side: about 17 Mbps of upload from your network. The relay host needs about 10.8 Mbps of upload.

## Disk Space for Archive

Archive writes every stream published to the `relay` application at its source bitrate.

```text
GB per hour = source kbps × 0.00045
```

A 6160 kbps source uses about 2.8 GB per hour. A 20000 kbps source uses about 9 GB per hour.

## Measure Your Upload

1. Run an upload test, for example at [Speedtest.net](https://www.speedtest.net/){target="_blank"}, from the network the relay's outgoing streams leave from.
2. Compare the upload figure with your total from [Example Calculation](#example-calculation).

## Reduce Upload

- **Lower the source bitrate** in your streaming software. This lowers the bitrate sent to YouTube and to Twitch in partner mode, and the Archive file size. It does not change Twitch non-partner mode, which re-encodes to its own bitrate.
- **Lower the Twitch non-partner bitrate** with `TWITCH_KBITS_PER_VIDEO_FRAME` or `TWITCH_FPS`. Lowering `TWITCH_HEIGHT` does not reduce the bitrate. See [Quality Optimization](quality.md).
- **Disable a service** by leaving its key empty in `env/relay.env`.

## See Also

- [Quality Optimization](quality.md) - Choosing Twitch resolution, frame rate and bitrate
- [CPU Considerations](hardware.md) - CPU cost of Twitch re-encoding
- [Stream to Twitch](../services/twitch.md) - Twitch settings and bitrate reference table
- [Stream to YouTube](../services/youtube.md) - YouTube settings

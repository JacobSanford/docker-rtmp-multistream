---
title: Bandwidth Requirements
description: Network bandwidth requirements and optimization for multi-streaming
audience: users
doc_type: explanation
tags: [performance, bandwidth, network, upload, optimization]
lastReviewed: 2025-11-05
version: 1.x
---

# Bandwidth Requirements

This page covers network bandwidth requirements for streaming to multiple services simultaneously.

!!! warning "Stream Relays Use Significant Bandwidth"
    Unlike single-destination streaming, a relay sends your stream to **multiple services at once**. Your total upload bandwidth must support the sum of all enabled destinations. This can easily exceed typical residential upload speeds.

## Understanding Bandwidth Usage

When streaming through docker-rtmp-multistream, you send:

1. **One stream to the relay** (your source stream from OBS/streaming software)
2. **Multiple streams from the relay** (one to each enabled service)

Your upload connection must handle **all outgoing streams simultaneously**.

## Bandwidth Calculation

Total upload bandwidth = Sum of all enabled service streams:

```
Total Upload = Source to Relay + Relay to Service 1 + Relay to Service 2 + ...
```

### Example Calculation

**Scenario**: Streaming to YouTube and Twitch

- **Source stream** (OBS → relay): 20 Mbps
- **YouTube** (relay → YouTube): 20 Mbps (passthrough - uses full source bitrate)
- **Twitch** (relay → Twitch): 4.5 Mbps (transcoded - uses configured lower bitrate)

**Total upload needed**: ~44.5 Mbps (20 + 20 + 4.5)

!!! example "Service Bandwidth Patterns"
    - **YouTube**: Uses passthrough (full source bandwidth) - see [YouTube Configuration](../services/youtube.md)
    - **Twitch**: Partners use passthrough (full source). Non-partners use transcoded stream (configurable, typically lower) - see [Twitch Configuration](../services/twitch.md)
    - **Archive**: Local disk I/O only (no network bandwidth)

## Testing Your Connection

Before multi-streaming, test your upload speed:

1. Visit [Speedtest.net](https://www.speedtest.net/){target="_blank"}
2. Run the test and note your **upload speed**
3. Compare against your calculated total bandwidth requirement

!!! tip "Upload vs Download"
    Your **upload** speed is typically much lower than download speed. Most residential connections have asymmetric bandwidth (e.g., 100 Mbps download / 10 Mbps upload).

## Optimization Strategies

If your upload bandwidth is limited, consider these approaches:

### 1. Reduce Source Bitrate

Lower the bitrate in your streaming software (OBS, etc.). This reduces bandwidth for all services.

**Tradeoff**: Lower source quality affects all destinations.

### 2. Use Service-Specific Transcoding

Configure services like Twitch to use lower transcoded settings rather than passthrough.

**Tradeoff**: Additional CPU usage for encoding.

### 3. Selective Service Enable

Only enable services that fit within your bandwidth constraints. Disable less critical destinations.

### 4. Content-Aware Settings

Adjust settings based on your content type (see [Quality Optimization](quality.md)):

- **High motion content**: Lower resolution, maintain frame rate
- **High detail content**: Lower frame rate, maintain resolution

## See Also

- [Quality Optimization](quality.md) - Stream quality tuning strategies
- [Hardware Requirements](hardware.md) - CPU considerations for encoding
- [Twitch Configuration](../services/twitch.md) - Twitch bandwidth and transcoding
- [YouTube Configuration](../services/youtube.md) - YouTube bandwidth requirements

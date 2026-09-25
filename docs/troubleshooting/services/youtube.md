---
title: YouTube Troubleshooting
description: Troubleshooting YouTube-specific streaming issues
audience: users
doc_type: howto
tags: [troubleshooting, youtube, streaming, latency]
lastReviewed: 2025-11-07
version: 1.x
---

# YouTube Troubleshooting

Troubleshooting issues specific to streaming to YouTube.

## Common Issues

| Issue | Description |
|-------|-------------|
| **[Stream Not Visible](#stream-not-visible)** | Stream connects but is not visible on your YouTube channel |
| **[Stream Latency](#stream-latency)** | Excessive delay between OBS and YouTube viewers |
| **[Encoding Warnings](#encoding-warnings)** | YouTube Studio shows encoding or quality warnings |
| **[Stream Not Appearing](#stream-not-appearing)** | OBS shows streaming but nothing appears on YouTube |
| **[Debug Logs](#debug-logs)** | How to check YouTube-specific logs and error messages |

---

## Stream Not Visible

**Issue**: Stream connects but not visible on channel

**Check**:
1. YouTube Studio → Live dashboard
2. Verify "Stream status" shows "Live"
3. Check stream visibility settings (Public/Unlisted/Private)

**Solution**:
- Set visibility to "Public" in YouTube Studio
- Wait 30-60 seconds for stream to appear
- Refresh browser page

## Stream Latency

**Issue**: Excessive delay between OBS and YouTube

**Check**: YouTube Studio → Stream settings → Latency

**Options**:
- **Normal latency**: 8-12 seconds (default)
- **Low latency**: 4-8 seconds
- **Ultra-low latency**: 2-4 seconds

**Note**: Lower latency may affect stream quality for viewers with slow connections.

## Encoding Warnings

**Issue**: YouTube shows encoding warnings

**Check**: YouTube Studio → Live dashboard → Stream health

**Common warnings**:
- "Audio not synced with video" - Check OBS audio settings
- "Resolution mismatch" - Ensure OBS output matches expected resolution
- "Bitrate too low" - Increase OBS bitrate

**Solution**: YouTube prefers high bitrate for best quality (15-20 Mbps recommended).

## Stream Not Appearing

### Symptoms
- OBS shows "Streaming" but stream doesn't appear on YouTube
- No errors in OBS

### Possible Causes

#### 1. Service Not Enabled

**Check**: Look at container logs during startup:

```bash
docker compose logs relay | grep -E "service enabled|Skipping|ERROR"
```

When YouTube is enabled, this line appears:

```text
YouTube configuration complete, and service enabled.
```

If YouTube is not enabled, this line appears instead: `YOUTUBE_KEY is not set. Skipping YouTube configuration.`

**Solution**: If YouTube is missing:
- Verify `YOUTUBE_KEY` is set in `env/relay.env`

Recreate the container so it reads the new value:

```bash
docker compose up -d --force-recreate
```

Confirm the service is enabled:

```bash
docker compose logs relay | grep -E "service enabled|Skipping|ERROR"
```

#### 2. Wrong Stream Key

A key that is well-formed but wrong is accepted by the relay. The relay cannot tell it is wrong, and the log may show nothing.

**Check**: Confirm the relay can reach YouTube:

```bash
docker compose exec relay nc -zv a.rtmp.youtube.com 1935
```

Then start streaming and open YouTube Studio → Go Live. If the command above prints `open` and YouTube Studio → Go Live shows no incoming stream, the key is the likely cause.

**Solution**: Copy the key again from YouTube Studio into `env/relay.env`.

Recreate the container so it reads the new value:

```bash
docker compose up -d --force-recreate
```

Confirm the service is enabled:

```bash
docker compose logs relay | grep -E "service enabled|Skipping|ERROR"
```

#### 3. Platform-Specific Issues

- Verify you've scheduled a live stream or enabled "Stream now"
- Check YouTube Studio for stream health warnings
- Confirm account is verified for live streaming

## Debug Logs

### Enable Detailed Logging

For YouTube-specific issues, check logs:

```bash
# YouTube-specific logs
docker compose logs relay | grep -i youtube
```

### Common Log Messages

**Success messages**:
```text
YouTube configuration complete, and service enabled.
```

**Service skipped** — the relay keeps running without this service:
```text
YOUTUBE_KEY is not set. Skipping YouTube configuration.
```

**Invalid value** — the container stops. The last lines of `docker compose logs relay` name the variable to correct:
```text
ERROR: YOUTUBE_KEY contains invalid characters. Only alphanumeric, dash, underscore, period, and colon are allowed.
[!] pre-init.d - 90_configure_youtube.sh failed. Stopping container.
```

## See Also

- **[Troubleshooting Overview](../index.md)** - Main troubleshooting guide
- **[Connection Issues](../connection-issues.md)** - Network and connectivity problems
- **[YouTube Service](../../services/youtube.md)** - YouTube configuration details

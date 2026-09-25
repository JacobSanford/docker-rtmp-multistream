---
title: YouTube Troubleshooting
description: Troubleshooting YouTube-specific streaming issues
audience: users
doc_type: howto
tags: [troubleshooting, youtube, streaming, latency]
lastReviewed: 2026-09-25
version: 1.x
---

# YouTube Troubleshooting

Troubleshooting issues specific to streaming to YouTube.

## Common Issues

| Issue | Description |
|-------|-------------|
| **[Encoding Warnings](#encoding-warnings)** | YouTube Studio shows encoding or quality warnings |
| **[Stream Not Appearing](#stream-not-appearing)** | OBS shows streaming but nothing appears on YouTube |
| **[Debug Logs](#debug-logs)** | How to check YouTube-specific logs and error messages |

---

## Encoding Warnings

**Issue**: YouTube Studio shows stream health warnings

The relay passes the YouTube stream through unchanged, so the warnings describe what OBS sends. Fix them in OBS. For YouTube's recommended settings, see [Choose live encoder settings, bitrates, and resolutions](https://support.google.com/youtube/answer/2853702){target="_blank"}.

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
- Check the stream's visibility (Public/Unlisted/Private) in YouTube Studio
- Confirm account is verified for live streaming

## Debug Logs

### View YouTube Log Lines

For more detail, see [Increase Log Verbosity](../connection-issues.md#increase-log-verbosity).

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

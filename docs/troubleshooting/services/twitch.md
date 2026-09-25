---
title: Twitch Troubleshooting
description: Troubleshooting Twitch-specific streaming issues
audience: users
doc_type: howto
tags: [troubleshooting, twitch, streaming, quality]
lastReviewed: 2025-11-07
version: 1.x
---

# Twitch Troubleshooting

Troubleshooting issues specific to streaming to Twitch.

## Common Issues

| Issue | Description |
|-------|-------------|
| **[Transcoding Quality](#transcoding-quality)** | Stream looks worse on Twitch than expected, poor video quality |
| **[Ingest Server Issues](#ingest-server-issues)** | Stream works intermittently, connection failures |
| **[Stream Not Appearing](#stream-not-appearing)** | OBS shows streaming but nothing appears on Twitch |
| **[Debug Logs](#debug-logs)** | How to check Twitch-specific logs and error messages |

---

## Transcoding Quality

**Issue**: Stream looks worse on Twitch than expected

**Check**: Verify transcoding settings:

```bash
grep TWITCH env/relay.env
```

**Solution**: Adjust quality settings:
```bash
# Increase bitrate
TWITCH_KBITS_PER_VIDEO_FRAME=100  # From 75

# Better encoding quality (more CPU)
TWITCH_X264_PRESET=slow  # From medium
```

See [Twitch Configuration](../../services/twitch.md) for detailed settings.

## Ingest Server Issues

**Issue**: Stream works sometimes, fails other times

**Check**: Test different ingest servers:

```bash
# Try different endpoints
TWITCH_ENDPOINT=lax  # Los Angeles
TWITCH_ENDPOINT=ord  # Chicago
TWITCH_ENDPOINT=iad  # Ashburn
```

**Verify connectivity**: Test that the relay can open an RTMP connection (TCP port 1935) to Twitch:

```bash
docker compose exec relay nc -zv <TWITCH_ENDPOINT>.contribute.live-video.net 1935
```

Replace `<TWITCH_ENDPOINT>` with your `TWITCH_ENDPOINT` value (default `jfk`). A working connection prints `open` (the IP address will differ):

```text
jfk.contribute.live-video.net (35.55.32.14:1935) open
```

If the command does not print `open`, outbound port 1935 is blocked between the relay and Twitch.

## Stream Not Appearing

### Symptoms
- OBS shows "Streaming" but stream doesn't appear on Twitch
- No errors in OBS

### Possible Causes

#### 1. Service Not Enabled

**Check**: Look at container logs during startup:

```bash
docker compose logs relay | grep -E "service enabled|Skipping|ERROR"
```

When Twitch is enabled, one of these lines appears, depending on `TWITCH_PARTNER`:

```text
Twitch Partner configuration complete, and service enabled.
Twitch Non-Partner configuration complete, and service enabled.
```

If Twitch is not enabled, this line appears instead: `TWITCH_KEY is not set. Skipping Twitch configuration.`

**Solution**: If Twitch is missing:
- Verify `TWITCH_KEY` is set in `env/relay.env`

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

**Check**: Confirm the relay can reach Twitch:

```bash
docker compose exec relay nc -zv <TWITCH_ENDPOINT>.contribute.live-video.net 1935
```

Then start streaming and open Stream Manager. If the command above prints `open` and Stream Manager shows no incoming stream, the key is the likely cause.

**Solution**: Copy the key again from Twitch dashboard into `env/relay.env`.

Recreate the container so it reads the new value:

```bash
docker compose up -d --force-recreate
```

Confirm the service is enabled:

```bash
docker compose logs relay | grep -E "service enabled|Skipping|ERROR"
```

#### 3. Platform-Specific Issues

- Verify stream key hasn't expired
- Check Twitch dashboard for account status
- Ensure you're not already streaming from another source

## Debug Logs

### Enable Detailed Logging

For Twitch-specific issues, check logs:

```bash
# Twitch-specific logs
docker compose logs relay | grep -i twitch
```

### Common Log Messages

**Success messages**:
```text
Twitch Partner configuration complete, and service enabled.
Twitch Non-Partner configuration complete, and service enabled.
```

**Service skipped** — the relay keeps running without this service:
```text
TWITCH_KEY is not set. Skipping Twitch configuration.
```

**Invalid value** — the container stops. The last lines of `docker compose logs relay` name the variable to correct:
```text
ERROR: TWITCH_KEY contains invalid characters. Only alphanumeric, dash, underscore, period, and colon are allowed.
ERROR: TWITCH_PARTNER must be TRUE or FALSE (case insensitive).
[!] pre-init.d - 90_configure_twitch.sh failed. Stopping container.
```

## See Also

- **[Troubleshooting Overview](../index.md)** - Main troubleshooting guide
- **[Connection Issues](../connection-issues.md)** - Network and connectivity problems
- **[Twitch Service](../../services/twitch.md)** - Twitch configuration details

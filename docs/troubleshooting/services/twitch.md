---
title: Stream Not Reaching Twitch
description: Troubleshooting Twitch-specific streaming issues
audience: users
doc_type: howto
tags: [troubleshooting, twitch, streaming, quality]
lastReviewed: 2026-09-25
version: 1.x
---

# Stream Not Reaching Twitch

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

These settings apply only when `TWITCH_PARTNER=FALSE` (the default). In partner mode the relay passes the stream through unchanged, so set quality in OBS instead.

**Solution**: In `env/relay.env`, raise the bitrate or use a slower encoder preset:

```bash
# Video bitrate is TWITCH_KBITS_PER_VIDEO_FRAME × TWITCH_FPS: 100 × 60 = 6000 kbps (default 75 × 60 = 4500)
TWITCH_KBITS_PER_VIDEO_FRAME=100

# Better quality per bit, but uses more CPU (default: medium)
TWITCH_X264_PRESET=slow
```

Recreate the container so it reads the new values:

```bash
docker compose up -d --force-recreate
```

While streaming, check the relay's CPU use:

```bash
docker stats --no-stream
```

If `CPU %` stays near the machine's limit, set `TWITCH_X264_PRESET` back to `medium`.

Watch the stream on Twitch to confirm the quality changed.

See [Twitch Configuration](../../services/twitch.md) for all settings.

## Ingest Server Issues

**Issue**: Stream works sometimes, fails other times

**Check**: Try a different ingest server. Set `TWITCH_ENDPOINT` in `env/relay.env` to a region code from [Twitch's ingest list](https://ingest.twitch.tv/ingests){target="_blank"}. The code is the first part of each `url_template` host, for example `use20` from `rtmp://use20.contribute.live-video.net/app/{stream_key}`:

```bash
TWITCH_ENDPOINT=use20
```

Other examples: `usw20` (US West, Oregon), `euc10` (Europe, Frankfurt). Set one value only, with no comment on the same line. The default is `use10` (US East, N. Virginia). For older names such as `jfk`, see [`TWITCH_ENDPOINT`](../../techref/environment.md#twitch_endpoint).

Recreate the container so it reads the new value:

```bash
docker compose up -d --force-recreate
```

**Verify connectivity**: Test that the relay can open a Real-Time Messaging Protocol (RTMP) connection (TCP port 1935) to Twitch:

```bash
docker compose exec relay nc -zv <TWITCH_ENDPOINT>.contribute.live-video.net 1935
```

Replace `<TWITCH_ENDPOINT>` with your `TWITCH_ENDPOINT` value (default `use10`). A working connection prints `open` (the IP address will differ):

```text
use10.contribute.live-video.net (35.55.30.14:1935) open
```

If the command does not print `open`, outbound port 1935 is blocked between the relay and Twitch. If it prints `open`, stream for a while on the new endpoint to confirm the drops have stopped.

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

### Confirm the Fix

Start streaming in OBS and open Twitch Stream Manager. The stream shows as live.

## Debug Logs

For the startup lines every service prints, and which ones mean the container stopped, see [Check Service Status](../index.md#check-service-status). For more detail while streaming, see [Increase Log Verbosity](../connection-issues.md#increase-log-verbosity).

## See Also

- **[Troubleshooting Overview](../index.md)** - Main troubleshooting guide
- **[Connection Issues](../connection-issues.md)** - Network and connectivity problems
- **[Twitch Service](../../services/twitch.md)** - Twitch configuration details

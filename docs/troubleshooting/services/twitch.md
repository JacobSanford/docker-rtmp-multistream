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

**Verify connectivity**:
```bash
docker compose exec relay ping -c 5 live-<endpoint>.twitch.tv
```

Replace `<endpoint>` with your chosen endpoint (e.g., `jfk`, `lax`, `ord`).

## Stream Not Appearing

### Symptoms
- OBS shows "Streaming" but stream doesn't appear on Twitch
- No errors in OBS

### Possible Causes

#### 1. Service Not Enabled

**Check**: Look at container logs during startup:

```bash
docker compose logs relay | grep -i "configured and enabled"
```

**Expected output**:
```
Twitch configured and enabled.
```

**Solution**: If Twitch is missing:
- Verify `TWITCH_KEY` is set in `env/relay.env`
- Restart container after setting the key

#### 2. Invalid Stream Key

**Check**: Look for authentication errors in logs:

```bash
docker compose logs relay | grep -i "error\|auth\|publish"
```

**Solution**:
- Verify stream key is correct in `env/relay.env`
- Check for extra spaces or quotes around key
- Get fresh key from Twitch dashboard

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
```
Twitch configured and enabled.
```

**Error messages**:
```
ERROR: TWITCH_KEY is not set
ERROR: Failed to validate TWITCH_KEY
```

## See Also

- **[Troubleshooting Overview](../index.md)** - Main troubleshooting guide
- **[Connection Issues](../connection-issues.md)** - Network and connectivity problems
- **[Twitch Service](../../services/twitch.md)** - Twitch configuration details

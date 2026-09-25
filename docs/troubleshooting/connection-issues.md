---
title: Connection Issues
description: Troubleshooting connection problems and container startup issues
audience: users
doc_type: howto
tags: [troubleshooting, connection, network, docker]
lastReviewed: 2025-10-21
version: 1.x
---

# Connection Issues

Troubleshooting connection problems between OBS and the relay, and container startup issues.

## Cannot Connect from OBS

### Symptoms
- OBS shows "Failed to connect to server"
- Connection timeout

### Possible Causes

#### 1. Port Not Accessible

**Check**: Verify port 1935 is exposed:

```bash
docker compose ps
```

Look for `0.0.0.0:1935->1935/tcp`

**Solution**: Ensure `docker-compose.yml` has correct port mapping:
```yaml
ports:
  - "1935:1935"
```

#### 2. IP Address Mismatch

**Check**: Verify you're using the correct IP address:

```bash
ip addr show | grep inet
```

**Solution**:
- Use the relay PC's local network IP (e.g., `192.168.1.100`)
- Don't use `127.0.0.1` or `localhost` from another machine

#### 3. Firewall Blocking

**Check**: Test if port is reachable:

```bash
# From gaming PC
telnet <relay-ip> 1935
```

**Solution**:
- Open port 1935 in firewall
- Ubuntu: `sudo ufw allow 1935/tcp`
- Check if Docker networking is working

#### 4. IP Range Restriction

**Check**: Look for "deny publish" in logs:

```bash
docker compose logs relay | grep "deny\|publish"
```

**Solution**: Adjust `PUBLISH_IP_RANGE` in `env/relay.env`:
```bash
# Allow entire local network
PUBLISH_IP_RANGE=192.168.0.0/16

# Allow specific IP
PUBLISH_IP_RANGE=192.168.1.50/32
```

### Network Connectivity Test

If relay can't reach streaming services:

**Check**: Test that the relay can open an RTMP connection (TCP port 1935) to each service:

```bash
docker compose exec relay nc -zv <TWITCH_ENDPOINT>.contribute.live-video.net 1935
docker compose exec relay nc -zv a.rtmp.youtube.com 1935
```

Replace `<TWITCH_ENDPOINT>` with your `TWITCH_ENDPOINT` value (default `jfk`). A working connection prints `open` (the IP address will differ):

```text
jfk.contribute.live-video.net (35.55.32.14:1935) open
```

If the command does not print `open`, outbound port 1935 is blocked between the relay and the service.

**Solution**:
- Check firewall settings
- Verify outbound RTMP (port 1935) is allowed
- Try different Twitch ingest endpoint (change `TWITCH_ENDPOINT`)

## Container Won't Start

### Symptoms
- `docker compose up` exits immediately
- Container status shows "Exited (1)"

### Possible Causes

#### 1. Invalid Environment Value

**Check**: Read the last lines of the log:

```bash
docker compose logs relay | grep -E "ERROR|\[!\]"
```

An invalid value prints the variable name and the script that stopped:

```text
ERROR: TWITCH_FPS must be a number.
[!] pre-init.d - 90_configure_twitch.sh failed. Stopping container.
```

**Solution**: Correct the named variable in `env/relay.env`, then run `docker compose up -d --force-recreate`.

#### 2. Port Already in Use

**Check**: Error message about port binding:

```bash
docker compose up
```

Look for: `bind: address already in use`

**Solution**:
- Stop other processes using port 1935
- Find process: `sudo lsof -i :1935`
- Kill it: `sudo kill <PID>`

#### 3. Outdated Image

**Solution**: Rebuild the image against the latest base image, then recreate the container:
```bash
docker compose build --pull
docker compose up -d --force-recreate
```

## Advanced Diagnostics

### Increase Log Verbosity

!!! warning
    At `info`, the log includes your full stream URLs, **including stream keys**. Do not paste these logs into an issue or chat without removing the keys, and set the level back to `error` when you're done.

Set the log level in `env/relay.env`:

```bash
NGINX_ERROR_LOG_LEVEL=info
```

Recreate the container:

```bash
docker compose up -d --force-recreate
```

When you start streaming, a line like this appears for each destination:

```text
relay: create push name='<STREAM_NAME>' ... url='a.rtmp.youtube.com/live2/<YOUTUBE_KEY>' ...
```

Valid values, least to most verbose: `emerg`, `alert`, `crit`, `error` (default), `warn`, `notice`, `info`. `debug` is also accepted, but this image's nginx gives no more output at `debug` than at `info`.

### Check nginx Configuration

```bash
# Test nginx config syntax
docker compose exec relay nginx -t

# View active configuration
docker compose exec relay cat /etc/nginx/nginx.conf
```

## See Also

- **[Troubleshooting Overview](index.md)** - Main troubleshooting guide
- **Service-Specific Issues** - [Twitch](services/twitch.md), [YouTube](services/youtube.md), [Archive](services/archive.md)
- **[Configuration](../configuration.md)** - Setup and environment variables
- **[Security](../security.md)** - IP-based access control

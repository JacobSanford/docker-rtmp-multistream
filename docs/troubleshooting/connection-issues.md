---
title: Connection Issues
description: Troubleshooting connection problems and container startup issues
audience: users
doc_type: howto
tags: [troubleshooting, connection, network, docker]
lastReviewed: 2026-09-25
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

**Check**: From the machine running OBS, test whether the relay's port is reachable. Replace `<RELAY_IP>` with the relay machine's LAN address (see the previous check).

Windows (PowerShell):

```powershell
Test-NetConnection <RELAY_IP> -Port 1935
```

A reachable port shows `TcpTestSucceeded : True`. TODO(verify: Test-NetConnection output on Windows)

Linux or macOS:

```bash
nc -zv <RELAY_IP> 1935
```

A reachable port prints a line containing `succeeded` or `open`.

**Solution**:
- Open port 1935 in firewall
- Ubuntu: `sudo ufw allow 1935/tcp`
- Check if Docker networking is working

#### 4. IP Range Restriction

**Check**: Look for a denied connection in the logs:

```bash
docker compose logs relay | grep "access forbidden"
```

A denied connection logs the address the relay saw:

```text
[error] 89#89: *1 access forbidden by rule, client: 172.17.0.1, server: 0.0.0.0:1935
```

**Solution**: Follow the steps in [IP Authentication](ip_authentication.md#solution) to add the refused `client:` address to `PUBLISH_IP_RANGE`.

### Network Connectivity Test

If relay can't reach streaming services:

**Check**: Test that the relay can open a Real-Time Messaging Protocol (RTMP) connection (TCP port 1935) to each service:

```bash
docker compose exec relay nc -zv <TWITCH_ENDPOINT>.contribute.live-video.net 1935
docker compose exec relay nc -zv a.rtmp.youtube.com 1935
```

Replace `<TWITCH_ENDPOINT>` with your `TWITCH_ENDPOINT` value (default `use10`). A working connection prints `open` (the IP address will differ):

```text
use10.contribute.live-video.net (35.55.30.14:1935) open
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

If you can't tell what's wrong and need the relay back quickly, undo your last change to `env/relay.env` and recreate the container the same way.

#### 2. Port Already in Use

**Check**: `docker compose up -d` prints one of these:

```text
Bind for 0.0.0.0:1935 failed: port is already allocated
failed to bind host port 0.0.0.0:1935/tcp: address already in use
```

**Solution**:

- **`port is already allocated`**: another container holds the port, often an older copy of the relay. Find it and stop it:

    ```bash
    docker ps --filter publish=1935
    docker stop <CONTAINER_NAME>
    ```

- **`address already in use`**: another program holds the port. Find it:

    ```bash
    sudo ss -ltnp 'sport = :1935'
    ```

    Close that program normally (for example, another streaming server). Only kill it if you know what it is.

Then start the relay: `docker compose up -d`.

#### 3. Outdated Image

**Solution**: Rebuild the image against the latest base image, then recreate the container:
```bash
docker compose build --pull
docker compose up -d --force-recreate
```

## Advanced Diagnostics

### Increase Log Verbosity

!!! warning
    The log can contain your full stream URLs, **including stream keys**, at any level. At `info`, it does whenever you stream. Do not paste these logs into an issue or chat without removing the keys, and set the level back to `error` when you're done.

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

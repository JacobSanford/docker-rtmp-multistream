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

**Check**: Test if relay can reach the service:

```bash
docker compose exec relay ping -c 3 live-jfk.twitch.tv
docker compose exec relay ping -c 3 a.rtmp.youtube.com
```

**Solution**:
- Check firewall settings
- Verify outbound RTMP (port 1935) is allowed
- Try different Twitch ingest endpoint (change `TWITCH_ENDPOINT`)

## Container Won't Start

### Symptoms
- `docker compose up` exits immediately
- Container status shows "Exited (1)"

### Possible Causes

#### 1. Configuration Syntax Error

**Check**: Look for nginx errors:

```bash
docker compose logs relay | grep -i "error\|failed\|emergency"
```

**Solution**:
- Check for typos in manually edited config files
- Rebuild container: `docker compose build --no-cache`

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

#### 3. Missing Dependencies

**Solution**: Pull latest base image:
```bash
docker compose pull
docker compose build --no-cache
```

## Advanced Diagnostics

### Increase Log Verbosity

Edit `build/conf/nginx/nginx.conf` and change:
```nginx
error_log /var/log/nginx/error.log warn;
```

to:
```nginx
error_log /var/log/nginx/error.log debug;
```

Rebuild: `docker compose build`

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

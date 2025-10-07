# Troubleshooting

Common issues and their solutions.

## Stream Not Appearing on Service

### Symptoms
- OBS shows "Streaming" but stream doesn't appear on Twitch/YouTube
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
YouTube configured and enabled.
```

**Solution**: If service is missing:
- Verify environment variables are set in `env/relay.env`
- For Twitch: Check `TWITCH_KEY` is set
- For YouTube: Check `YOUTUBE_KEY` is set
- For Archive: Check `ARCHIVE_PATH` is set and writable

#### 2. Invalid Stream Key

**Check**: Look for authentication errors in logs:

```bash
docker compose logs relay | grep -i "error\|auth\|publish"
```

**Solution**:
- Verify stream keys are correct in `env/relay.env`
- Check for extra spaces or quotes around keys
- Get fresh keys from Twitch/YouTube dashboards

#### 3. Network Connectivity

**Check**: Test if relay can reach the service:

```bash
docker compose exec relay ping -c 3 live-jfk.twitch.tv
docker compose exec relay ping -c 3 a.rtmp.youtube.com
```

**Solution**:
- Check firewall settings
- Verify outbound RTMP (port 1935) is allowed
- Try different Twitch ingest endpoint (change `TWITCH_ENDPOINT`)

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

## Archive Not Recording

### Symptoms
- Stream works on Twitch/YouTube
- No files appearing in archive directory

### Possible Causes

#### 1. Archive Not Enabled

**Check**: Look for archive configuration in logs:

```bash
docker compose logs relay | grep -i archive
```

**Solution**: Set `ARCHIVE_PATH` in `env/relay.env`:
```bash
ARCHIVE_PATH=/archive
```

#### 2. Permission Denied

**Check**: Look for permission errors:

```bash
docker compose logs relay | grep -i "permission\|denied"
```

**Solution**: Fix directory permissions on host:
```bash
chown 100:101 ./stream_archive
chmod o+w ./stream_archive
```

#### 3. Volume Not Mounted

**Check**: Verify volume is mapped:

```bash
docker compose exec relay ls -la /archive
```

**Solution**: Add volume to `docker-compose.yml`:
```yaml
volumes:
  - ./stream_archive:/archive
```

#### 4. Disk Space

**Check**: Verify available space:

```bash
df -h ./stream_archive
```

**Solution**: Free up disk space or use a different directory with more space.

## High CPU Usage

### Symptoms
- System becomes slow during streaming
- Fans running at high speed
- Stream stuttering

### Possible Causes

#### 1. Multiple Transformers Active

**Check**: See which services are enabled:

```bash
docker compose logs relay | grep "configured and enabled"
```

**Explanation**: Each transformer (Twitch, etc.) runs a separate FFmpeg process that re-encodes your entire stream.

**Solution**:
- Use only services you need
- For YouTube, disable Twitch if not needed (YouTube uses simple relay, no CPU overhead)

#### 2. x264 Preset Too Slow

**Check**: Current preset in `env/relay.env`:

```bash
grep TWITCH_X264_PRESET env/relay.env
```

**Solution**: Use faster preset (trades quality for speed):
```bash
TWITCH_X264_PRESET=veryfast  # or: ultrafast, superfast, faster
```

#### 3. Thread Contention

**Check**: If running multiple transformers, threads may be competing

**Solution**: Limit threads per service:
```bash
TWITCH_FFMPEG_THREADS=4  # Limit Twitch to 4 threads
```

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

## Poor Stream Quality

### Symptoms
- Pixelation or blurriness
- Viewers complaining about quality

### Diagnosis

#### Check Source Quality

Ensure your streaming software (OBS) is sending high-quality stream:

**OBS Settings**:
- Bitrate: 15000-20000 kbps minimum
- Encoder: NVENC H.264 (if available) or x264
- Rate Control: CBR

#### Check Bandwidth

**Test upload speed**:
```bash
# Use https://www.speedtest.net/
```

**Calculate required bandwidth**:
```
Total Upload Needed = Source Bitrate + All Service Bitrates
```

Example:
- OBS Source: 20 Mbps
- Twitch (transcoded): 4.5 Mbps
- YouTube (passthrough): 20 Mbps
- Total: ~24.5 Mbps upload needed

### Solutions

#### For Twitch (Transformer Services)

Increase `TWITCH_KBITS_PER_VIDEO_FRAME`:
```bash
# From default 75 to higher
TWITCH_KBITS_PER_VIDEO_FRAME=100  # 720p60 = 6000 kbps
```

#### For YouTube (Relay Services)

Increase OBS bitrate - the relay passes it through unchanged.

#### For All Services

See the [Quality & Performance Guide](quality.md) for detailed optimization.

## Logs and Debugging

### View Container Logs

```bash
# All logs
docker compose logs relay

# Follow logs in real-time
docker compose logs -f relay

# Last 100 lines
docker compose logs --tail=100 relay

# Filter for errors
docker compose logs relay | grep -i error
```

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

## Getting Help

If you're still experiencing issues:

1. **Check existing issues**: [GitHub Issues](https://github.com/JacobSanford/docker-rtmp-multistream/issues)
2. **Gather information**:
   - Container logs: `docker compose logs relay > logs.txt`
   - Environment: `docker compose config > config.txt`
   - System info: `uname -a; docker --version`
3. **Open a new issue** with:
   - Clear description of the problem
   - Steps to reproduce
   - Logs and configuration (redact stream keys!)
   - System information

## See Also

- [Architecture](architecture.md) - Understand how the system works
- [Quality & Performance](quality.md) - Optimization guidance
- [Configuration Overview](configuration.md) - Setup details

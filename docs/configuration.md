# Configuration Overview

This guide explains how to configure docker-rtmp-multistream, covering environment variables, Docker volumes, and the overall configuration system.

## Configuration Layers

The system uses a layered configuration approach:

1. **Dockerfile** - Default values for all settings
2. **env/relay.env** - User customizations (this is what you edit)
3. **docker-compose.yml** - Docker setup and volume mappings
4. **Runtime** - Configuration files generated at container startup

## Environment Variables

### Configuration File

All user configuration happens in **`env/relay.env`**. This file contains environment variables that control service enablement and behavior.

!!! warning "Security"
    Never commit `env/relay.env` to version control if it contains stream keys or secrets. The included `.gitignore` prevents this by default.

### File Structure

The `env/relay.env` file is organized by service:

```bash
# System Configuration
PUBLISH_IP_RANGE=192.168.0.0/16

# Twitch Service
TWITCH_KEY=
TWITCH_HEIGHT=720
TWITCH_FPS=60
# ... more Twitch settings

# YouTube Service
YOUTUBE_KEY=

# Archive Service
ARCHIVE_PATH=
ARCHIVE_SUFFIX=flv
```

### Required vs Optional Variables

**Required for service enablement**:
- `TWITCH_KEY` - Enables Twitch streaming
- `YOUTUBE_KEY` - Enables YouTube streaming
- `ARCHIVE_PATH` - Enables local archiving

If these are empty or unset, the corresponding service is disabled.

**Optional variables**:
- All other variables have sensible defaults
- Only override when you need different behavior

## Service Enablement

Services are automatically enabled or disabled based on configuration:

### Example: Enabling Twitch Only

**env/relay.env**:
```bash
TWITCH_KEY=live_123456789_abcdefghijklmnopqrstuvwxyz
# YOUTUBE_KEY=   (commented out or empty)
# ARCHIVE_PATH=  (commented out or empty)
```

Result: Only Twitch streams, YouTube and Archive are disabled.

### Example: Enabling All Services

**env/relay.env**:
```bash
TWITCH_KEY=live_123456789_abcdefghijklmnopqrstuvwxyz
YOUTUBE_KEY=abcd-efgh-ijkl-mnop-qrst
ARCHIVE_PATH=/archive
```

**docker-compose.yml** (add volume for archive):
```yaml
volumes:
  - ./stream_archive:/archive
```

Result: All services active.

## Docker Compose Configuration

### Basic Setup

The minimal `docker-compose.yml`:

```yaml
services:
  relay:
    build:
      context: .
    ports:
      - "1935:1935"
    env_file:
      - ./env/relay.env
```

### Adding Persistent Archive

To save archived streams permanently:

```yaml
services:
  relay:
    build:
      context: .
    ports:
      - "1935:1935"
    env_file:
      - ./env/relay.env
    volumes:
      - ./stream_archive:/archive  # Host directory : Container path
```

Then set permissions:
```bash
mkdir -p stream_archive
chown 100:101 stream_archive
chmod o+w stream_archive
```

And configure in `env/relay.env`:
```bash
ARCHIVE_PATH=/archive
```

### Port Mapping

The relay listens on **port 1935** (RTMP standard port).

**Default mapping**:
```yaml
ports:
  - "1935:1935"  # Host:Container
```

**Custom host port** (if 1935 is already in use):
```yaml
ports:
  - "1936:1935"  # Access via port 1936 on host
```

Then stream to: `rtmp://<relay-ip>:1936/relay/<key>`

## Security Configuration

### IP-Based Access Control

The `PUBLISH_IP_RANGE` variable controls which IP addresses can publish streams to the relay.

**Default** (entire local network):
```bash
PUBLISH_IP_RANGE=192.168.0.0/16
```

**Single IP** (only one specific machine):
```bash
PUBLISH_IP_RANGE=192.168.1.50/32
```

**Multiple networks** (combine in nginx config):
```bash
# Requires custom configuration in auth.conf
PUBLISH_IP_RANGE=192.168.1.0/24
```

!!! info "CIDR Notation"
    - `/32` = single IP address
    - `/24` = 256 addresses (192.168.1.0 - 192.168.1.255)
    - `/16` = 65,536 addresses (192.168.0.0 - 192.168.255.255)

### Stream Key Security

Your streaming software uses a stream key that's independent of service keys:

**OBS Stream Settings**:
```
Server: rtmp://192.168.1.100:1935/relay
Key: mystream  (can be any identifier)
```

This key is **not** your Twitch/YouTube key - it's just an identifier for your stream on the relay.

## Configuration Flow

Understanding how configuration is processed:

```
1. Container starts
   ↓
2. Docker loads env/relay.env
   ↓
3. Pre-init scripts execute in order:
   - Check which services should be enabled
   - Replace placeholder variables in config files
   - Enable services by uncommenting includes
   ↓
4. nginx starts with active configuration
   ↓
5. Ready to receive streams
```

### Pre-init Script Order

Scripts in `build/scripts/pre-init.d/` run in alphanumeric order:

- `89_configure_app.sh` - Main relay application
- `90_configure_twitch.sh` - Twitch service
- `90_configure_youtube.sh` - YouTube service
- `90_configure_archive.sh` - Archive service

### Template Variables

Configuration files use placeholders like `{TWITCH_KEY}` that are replaced at runtime:

**Before** (`apps/twitch.conf`):
```nginx
push rtmp://live-jfk.twitch.tv/app/{TWITCH_KEY};
```

**After processing**:
```nginx
push rtmp://live-jfk.twitch.tv/app/live_123456789_abc;
```

## Common Configuration Patterns

### Pattern 1: Stream to Twitch and YouTube

```bash
# env/relay.env
TWITCH_KEY=live_123456789_abcdefghijklmnopqrstuvwxyz
TWITCH_HEIGHT=720
TWITCH_FPS=60

YOUTUBE_KEY=abcd-efgh-ijkl-mnop-qrst
```

### Pattern 2: Stream and Archive

```bash
# env/relay.env
YOUTUBE_KEY=abcd-efgh-ijkl-mnop-qrst
ARCHIVE_PATH=/archive
ARCHIVE_SUFFIX=mp4  # or flv (default)
```

```yaml
# docker-compose.yml
volumes:
  - ./stream_archive:/archive
```

### Pattern 3: Test/Development (Archive Only)

```bash
# env/relay.env
ARCHIVE_PATH=/archive
# No service keys set
```

Useful for testing without actually streaming to services.

## Applying Configuration Changes

After editing `env/relay.env` or `docker-compose.yml`:

### Method 1: Restart (Recommended)

```bash
docker compose down
docker compose up
```

### Method 2: Rebuild (If Dockerfile changed)

```bash
docker compose down
docker compose build --no-cache
docker compose up
```

### Method 3: Quick Restart (Existing build)

```bash
docker compose restart
```

!!! note "When to Rebuild"
    Rebuild is only needed if you modified:
    - Dockerfile
    - Config files in `build/conf/`
    - Scripts in `build/scripts/`

    Changing `env/relay.env` only requires restart.

## Configuration Reference

For complete details on all environment variables, see:

- [Twitch Configuration](services/twitch.md)
- [YouTube Configuration](services/youtube.md)
- [Archive Configuration](services/archive.md)
- [Environment Variables Reference](developer/environment.md)

## Validation

### Check Active Services

After starting, verify which services are enabled:

```bash
docker compose logs relay | grep "configured and enabled"
```

Expected output:
```
Twitch configured and enabled.
YouTube configured and enabled.
```

### Test Configuration Syntax

```bash
docker compose exec relay nginx -t
```

Should show: `nginx: configuration file /etc/nginx/nginx.conf test is successful`

### View Active Configuration

```bash
docker compose exec relay cat /etc/nginx/http.d/app.conf
```

Look for uncommented `include` directives for your enabled services.

## See Also

- [Architecture](architecture.md) - How configuration is processed
- [Quick Start Guide](quickstart.md) - Step-by-step setup
- [Troubleshooting](troubleshooting.md) - Configuration issues
- [Environment Variables Reference](developer/environment.md) - Complete variable listing

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
This is a lightweight nginx-based RTMP relay/encoder that simultaneously streams to multiple services (Twitch, YouTube) and optionally archives streams to local disk. It's designed to complement OBS/streaming software by providing a single endpoint that distributes the stream to multiple platforms.

## Build and Run

### Local Development/Testing
```bash
./start.sh
```
This script pulls the latest image, rebuilds, and starts the service via docker compose.

### Manual Docker Compose
```bash
docker compose up
docker compose down
```

### Building Docker Image
```bash
docker build -t rtmp-multistream .
```

## Architecture

### Core Components

**nginx RTMP Module**: The foundation is nginx with the RTMP module (`nginx-mod-rtmp`), configured to receive RTMP streams on port 1935.

**Service-Based Architecture**: The system uses a modular service pattern where each streaming destination (Twitch, YouTube, Archive) is:
1. Defined in `build/conf/nginx/http.d/apps/{service}.conf` - RTMP application config
2. Optionally has a transformer in `build/conf/nginx/http.d/transformers/{service}.conf` - FFmpeg encoding pipeline
3. Configured by a pre-init script in `build/scripts/pre-init.d/90_configure_{service}.sh`
4. Enabled/disabled dynamically via `build/scripts/enableService.sh`

### Configuration Flow

1. **Dockerfile**: Defines default environment variables for all services
2. **env/relay.env**: User overrides environment variables (stream keys, quality settings)
3. **Pre-init Scripts** (run at container start, alphanumeric order):
   - `89_configure_app.sh`: Replaces placeholder variables in nginx config
   - `90_configure_*.sh`: Each service checks if required env vars are set, configures service-specific settings via sed, and calls `enableService.sh`
4. **enableService.sh**: Uncomments the service's include directives in `app.conf` to activate it

### Main nginx Config Structure

- `build/conf/nginx/nginx.conf`: Loads RTMP module, includes app.conf
- `build/conf/nginx/http.d/app.conf`: Defines RTMP server with `relay` application and commented service includes
- `build/conf/nginx/http.d/auth.conf`: IP-based publish authentication using PUBLISH_IP_RANGE
- `build/conf/nginx/http.d/apps/*.conf`: Individual service RTMP applications
- `build/conf/nginx/http.d/transformers/*.conf`: FFmpeg transcoding pipelines (currently only Twitch uses this)

### Service Patterns

**YouTube** (Simple Relay): Direct RTMP push without transcoding - just forwards the stream as-is to YouTube's ingest server.

**Twitch** (Transformer Pattern): Two-stage process:
1. `relay` application receives stream and uses FFmpeg transformer to transcode/downscale
2. Transcoded stream pushes to internal `twitch` application
3. `twitch` application pushes to Twitch ingest

**Archive**: Modifies the main `relay` application to enable recording, saves to local disk with configurable path and format.

## Adding New Services

Follow the pattern in `docs/services/new.md`:

1. Create `build/conf/nginx/http.d/apps/{service}.conf` (and optional transformer)
2. Add environment variables to `Dockerfile` (defaults) and `env/relay.env` template
3. Add commented includes to `build/conf/nginx/http.d/app.conf`
4. Create `build/scripts/pre-init.d/90_configure_{service}.sh`:
   - Check if service should be enabled (required env vars present)
   - Use sed to replace placeholders in config files
   - Call `/scripts/enableService.sh {service}`
5. Make script executable: `chmod +x build/scripts/pre-init.d/90_configure_{service}.sh`

## Environment Variables

### Required for Services
- `TWITCH_KEY`: Twitch stream key (enables Twitch when set)
- `YOUTUBE_KEY`: YouTube stream key (enables YouTube when set)
- `ARCHIVE_PATH`: Local path for archived streams (enables Archive when set and writable)

### Twitch Quality Settings
- `TWITCH_HEIGHT`: Video height (default: 720)
- `TWITCH_FPS`: Frame rate (default: 60)
- `TWITCH_KBITS_PER_VIDEO_FRAME`: Video bitrate calculation factor (default: 75)
- `TWITCH_AUDIO_BITRATE`: Audio bitrate (default: 160k)
- `TWITCH_CODEC`: Video codec (default: libx264)
- `TWITCH_X264_PRESET`: Encoding preset (default: medium)
- `TWITCH_ENDPOINT`: Twitch ingest endpoint (default: jfk)

### System
- `PUBLISH_IP_RANGE`: IP range allowed to publish streams (default: 192.168.0.0/16)

## Testing

### Running Tests Locally

```bash
./test.sh
```

The test suite includes 28 tests across 4 categories:
- **Build Tests**: Verify Docker image builds and contains required components
- **Configuration Tests**: Validate service enabling/disabling and env var substitution
- **Startup Tests**: Ensure container starts correctly in various configurations
- **RTMP Functional Tests**: Test actual streaming, archiving, and authorization

Individual test suites can be run separately:
```bash
bash tests/01_build_tests.sh  # Build tests
bash tests/02_config_tests.sh # Config tests
bash tests/03_startup_tests.sh # Startup tests
bash tests/04_rtmp_tests.sh   # RTMP tests (requires ffmpeg)
```

Tests automatically clean up containers and temporary files. Exit code 0 = all passed, 1 = failures.

See `tests/README.md` for detailed testing documentation.

## Key Files

- `Dockerfile`: Image definition, base: ghcr.io/unb-libraries/nginx:3.18.x
- `docker-compose.yml`: Simple service definition exposing port 1935
- `start.sh`: Development convenience script
- `test.sh`: Main test runner
- `build/scripts/enableService.sh`: Core script to uncomment service includes
- `build/conf/nginx/http.d/app.conf`: Main RTMP config with service include placeholders

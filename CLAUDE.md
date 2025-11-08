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

The system supports two patterns (see `docs/techref/service-patterns.md` for detailed comparison):

- **Simple Relay**: Direct RTMP push without transcoding (YouTube, Archive, Twitch partner mode)
- **Transformer**: Two-stage FFmpeg transcoding pipeline (Twitch non-partner mode)

**Twitch** uses a conditional dual-mode pattern based on `TWITCH_PARTNER` setting - partners use simple relay, non-partners use transformer for downscaling/optimization.

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
./tests/test.sh
```

The test suite includes **146 tests** across 5 categories:
- **Validation Tests** (113 tests): Comprehensive input validation and security testing
- **Smoke Tests**: Quick sanity checks (Docker build, required components)
- **Unit Tests**: Configuration and environment variable handling (including security validation)
- **Integration Tests**: Container startup with various service combinations
- **Functional Tests**: End-to-end RTMP streaming, archiving, and authorization

Individual test suites can be run separately:
```bash
bash tests/00_validation_tests.sh  # Validation tests (113 tests)
bash tests/01_smoke_tests.sh       # Smoke tests
bash tests/02_unit_tests.sh        # Unit tests
bash tests/03_integration_tests.sh # Integration tests
bash tests/04_functional_tests.sh  # Functional tests (requires ffmpeg)
```

Tests automatically clean up containers and temporary files. Exit code 0 = all passed, 1 = failures.

See `tests/README.md` for detailed testing documentation.

### Input Validation & Security

All environment variables are validated before being used in configurations via `build/scripts/validate_input.sh`:

**Validation Functions:**
- `validate_stream_key()` - Prevents command injection in stream keys
- `validate_path()` - Ensures safe file paths, blocks shell metacharacters
- `validate_ip_range()` - Validates CIDR notation
- `validate_number()` - Enforces numeric types with optional min/max bounds
- `validate_identifier()` - Validates alphanumeric identifiers (codecs, presets)
- `validate_bitrate()` - Validates bitrate format (numeric or with k/K suffix)
- `validate_log_level()` - Whitelist validation for nginx log levels
- `validate_suffix()` - Validates file extensions
- `escape_for_sed()` - Safely escapes values for sed substitution

**Security Protections:**
- Command injection prevention (blocks `;|&$\`{}[]<>`)
- Path traversal protection (blocks `../` sequences)
- Configuration injection prevention (blocks newlines, null bytes)
- Buffer overflow mitigation (length limits on all inputs)
- Fail-fast behavior (`set -e` in all scripts)

All configuration scripts validate inputs before use, preventing malicious values from reaching nginx configs or shell commands.

### CI/CD

GitHub Actions automatically runs all test suites on every push and PR via `.github/workflows/ci.yml`. Each test type runs as a separate job:
- Validation Tests (runs first, builds image)
- Smoke Tests (after validation tests pass)
- Unit Tests (parallel with smoke tests)
- Integration Tests (parallel with smoke tests)
- Functional Tests (parallel with smoke tests)
- Build and Push (after all tests pass)

## Key Files

- `Dockerfile`: Image definition, base: ghcr.io/unb-libraries/nginx:3.18.x
- `docker-compose.yml`: Simple service definition exposing port 1935
- `start.sh`: Development convenience script
- `tests/test.sh`: Main test runner
- `build/scripts/enableService.sh`: Core script to uncomment service includes
- `build/conf/nginx/http.d/app.conf`: Main RTMP config with service include placeholders

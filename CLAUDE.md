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
1. Defined in `build/conf/nginx/http.d/apps/<service>.conf` - directives included inside `application relay` (Simple Relay), or an `application <service>` block at server level (Transformer destination)
2. Optionally has a transformer in `build/conf/nginx/http.d/transformers/<service>.conf` - FFmpeg encoding pipeline
3. Configured by a pre-init script in `build/scripts/pre-init.d/90_configure_<service>.sh`
4. Enabled/disabled dynamically via `build/scripts/enableService.sh`

### Configuration Flow

1. **Dockerfile**: Defines default environment variables for all services
2. **env/relay.env**: User overrides (stream keys, quality settings), copied from the tracked `env/relay.env.example` template and ignored by git
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

- **Simple Relay**: Direct RTMP push without transcoding (YouTube, Twitch partner mode)
- **Transformer**: Two-stage FFmpeg transcoding pipeline (Twitch non-partner mode)

Archive is neither: it is a `recorder` block inside the `relay` application that writes every incoming stream to disk.

**Twitch** uses a conditional dual-mode pattern based on `TWITCH_PARTNER` setting - partners use simple relay, non-partners use transformer for downscaling/optimization.

## Adding New Services

Follow `docs/developer/adding-services/overview.md`; the rules are in `docs/developer/adding-services/configuration.md`:

1. Create `build/conf/nginx/http.d/apps/<service>.conf` (and optional transformer). Placeholders are bare uppercase tokens (`EXAMPLE_KEY`), never `{EXAMPLE_KEY}`. Every `application` block includes `http.d/auth.conf`
2. Add environment variables to `Dockerfile` (defaults) and the `env/relay.env.example` template
3. Add commented includes to `build/conf/nginx/http.d/app.conf` as `#include NGINX_CONFD_DIR/apps/<service>.conf;` - no space after `#`, or `enableService.sh` fails
4. Create `build/scripts/pre-init.d/90_configure_<service>.sh` (must sort after `89_`):
   - If the required variable is empty, echo `<VAR> is not set. Skipping ...` and exit 0
   - Validate every variable; exit 1 on failure (stops the container)
   - Use sed to replace placeholders in config files
   - Call `/scripts/enableService.sh <service>` (argument = app file basename; it exits 1, stopping the container, if the file or its `#include` line is missing)
5. Make script executable: `chmod +x build/scripts/pre-init.d/90_configure_<service>.sh`

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
- `TWITCH_AUDIO_CHANNELS`: Audio channels, 1 (mono) or 2 (stereo) (default: 2)
- `TWITCH_CODEC`: Video codec (default: libx264)
- `TWITCH_X264_PRESET`: Encoding preset (default: medium)
- `TWITCH_ENDPOINT`: Twitch ingest endpoint (default: use10)
- `TWITCH_PARTNER`: TRUE relays unchanged, FALSE transcodes (default: FALSE)
- `TWITCH_FFMPEG_THREADS`: x264 encoder threads, 0 = auto (default: 0)

### Archive Settings
- `ARCHIVE_SUFFIX`: File extension; files are always FLV (default: flv)

### System
- `PUBLISH_IP_RANGE`: IP ranges allowed to publish streams, comma-separated (default: 172.16.0.0/12,192.168.0.0/16)
- `NGINX_ERROR_LOG_LEVEL`: nginx error log level (default: error)

## Testing

### Running Tests Locally

```bash
./tests/test.sh
```

The test suite has 5 categories:
- **Validation Tests**: Comprehensive input validation and security testing
- **Smoke Tests**: Quick sanity checks (Docker build, required components)
- **Unit Tests**: Configuration and environment variable handling (including security validation)
- **Integration Tests**: Container startup with various service combinations
- **Functional Tests**: End-to-end RTMP streaming, archiving, and authorization

Individual test suites can be run separately:
```bash
bash tests/00_validation_tests.sh  # Validation tests
bash tests/01_smoke_tests.sh       # Smoke tests
bash tests/02_unit_tests.sh        # Unit tests
bash tests/03_integration_tests.sh # Integration tests
bash tests/04_functional_tests.sh  # Functional tests (requires ffmpeg)
```

Tests automatically clean up containers and temporary files. `tests/test.sh` and each suite run on its own exit 0 when all tests pass and 1 on any failure.

See `tests/README.md` for detailed testing documentation.

### Input Validation & Security

All environment variables are validated before being used in configurations via `build/scripts/validate_input.sh`:

**Validation Functions:**
- `validate_stream_key()` - Prevents command injection in stream keys
- `validate_path()` - Ensures safe file paths, blocks spaces, `..` segments and shell metacharacters
- `validate_ip_range()` / `validate_ip_ranges()` - Validates CIDR notation (single / comma-separated)
- `validate_number()` - Enforces non-negative integers of at most 9 digits with optional min/max bounds
- `validate_identifier()` - Validates alphanumeric identifiers (codecs, presets)
- `validate_bitrate()` - Validates bitrate format (numeric or with k/K suffix)
- `validate_log_level()` - Whitelist validation for nginx log levels
- `validate_suffix()` - Validates file extensions
- `validate_boolean()` - Validates TRUE/FALSE, case insensitive
- `escape_for_sed()` - Safely escapes values for sed substitution

**Security Protections:**
- Command injection prevention (stream keys and identifiers are whitelisted; `validate_path` blocks `` ;|&$`(){}<>#'" ``)
- Path traversal protection (`validate_path` rejects `..` path segments)
- Configuration injection prevention (blocks newlines, null bytes)
- Length limits on stream keys, paths, identifiers, suffixes and numbers
- Fail-fast behavior (`set -e` in the pre-init scripts; `build/scripts/run.sh` stops the container when one fails)

All configuration scripts validate inputs before use, preventing malicious values from reaching nginx configs or shell commands.

### CI/CD

GitHub Actions automatically runs all test suites on every push and PR via `.github/workflows/ci.yml`. Each test type runs as a separate job:
- Validation Tests (runs first, builds image)
- Smoke Tests (after validation tests pass)
- Unit Tests (parallel with smoke tests)
- Integration Tests (after smoke and unit tests pass)
- Functional Tests (after smoke and unit tests pass)
- Build and Push (after all tests pass)

## Key Files

- `Dockerfile`: Image definition, base: ghcr.io/unb-libraries/nginx:3.18.x
- `docker-compose.yml`: Simple service definition exposing port 1935
- `start.sh`: Development convenience script
- `tests/test.sh`: Main test runner
- `build/scripts/enableService.sh`: Core script to uncomment service includes
- `build/conf/nginx/http.d/app.conf`: Main RTMP config with service include placeholders

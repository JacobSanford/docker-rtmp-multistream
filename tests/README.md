# Test Suite for docker-rtmp-multistream

This directory contains automated tests for the RTMP multistream relay.

## Running Tests Locally

### Prerequisites
- Docker installed and running
- `ffmpeg` installed (for RTMP streaming tests)
- Bash shell

### Quick Start

Run all tests:
```bash
./test.sh
```

### Test Suites

The test suite is organized into four categories:

#### 1. Build Tests (`tests/01_build_tests.sh`)
Verifies the Docker image builds correctly and contains required components:
- Docker build succeeds
- Image contains nginx, ffmpeg, and RTMP module
- Configuration files and scripts are present

#### 2. Configuration Tests (`tests/02_config_tests.sh`)
Validates service configuration and environment variable handling:
- Services remain disabled without keys
- Services enable when keys are provided
- Environment variables correctly replace placeholders
- Twitch transformer configuration
- IP range authorization

#### 3. Startup Tests (`tests/03_startup_tests.sh`)
Ensures container starts correctly under various configurations:
- Container starts with no services
- Container starts with individual services
- Container starts with all services enabled
- nginx process runs correctly
- Port 1935 is listening
- No startup errors in logs

#### 4. RTMP Functional Tests (`tests/04_rtmp_tests.sh`)
Tests actual RTMP streaming functionality:
- RTMP connections are accepted
- Streams are logged
- Archive recording works
- IP-based authorization
- Multiple simultaneous streams

## Running Individual Test Suites

You can run individual test suites directly:

```bash
# Build tests only
bash tests/01_build_tests.sh

# Configuration tests only
bash tests/02_config_tests.sh

# Startup tests only
bash tests/03_startup_tests.sh

# RTMP functional tests only
bash tests/04_rtmp_tests.sh
```

## Test Output

Tests provide colored output:
- ✓ (Green) - Test passed
- ✗ (Red) - Test failed

Example output:
```
=== Docker Build Tests ===
✓ Docker image builds successfully
✓ Image contains nginx
✓ Image contains ffmpeg
✓ Image has RTMP module

=== Test Summary ===
Total tests run: 32
Passed: 32
```

## Cleanup

The test suite automatically cleans up:
- Test containers
- Temporary files in `tests/tmp/`

Cleanup happens automatically on exit, even if tests fail.

## Adding New Tests

To add new tests:

1. Create a new test function in the appropriate suite file:
```bash
test_my_new_feature() {
  # Your test logic here
  return 0  # Success
  return 1  # Failure
}
```

2. Add it to the test suite using `run_test`:
```bash
run_test "Description of test" test_my_new_feature
```

3. Use the helper functions in `tests/test_helpers.sh`

## CI/CD Integration

These tests are designed to run in CI/CD pipelines. They:
- Exit with code 0 on success
- Exit with code 1 on any failure
- Provide clear output for debugging
- Clean up all resources

## Troubleshooting

### Tests fail with "Cannot connect to Docker daemon"
Ensure Docker is running: `docker ps`

### RTMP tests fail
Ensure `ffmpeg` is installed: `ffmpeg -version`

### Port conflicts
If port 11935 is in use, kill processes using it:
```bash
lsof -ti:11935 | xargs kill -9
```

### Permission issues with archive tests
Ensure Docker has permission to mount volumes:
```bash
chmod 777 tests/tmp/archive
```

## Test Coverage

Current test coverage:
- ✓ Docker build process
- ✓ Service configuration (Twitch, YouTube, Archive)
- ✓ Container startup and health
- ✓ RTMP streaming functionality
- ✓ IP-based authorization
- ✓ Archive recording
- ✓ Multi-stream support

Not yet covered:
- End-to-end streaming to actual Twitch/YouTube (requires keys)
- Performance/stress testing
- Network failure scenarios
- Transcoding quality verification

# Test Suite for docker-rtmp-multistream

This directory contains automated integration tests for the RTMP multistream relay.

## Running Tests Locally

### Prerequisites
- Docker installed and running
- `ffmpeg` installed (for functional tests)
- Bash shell

### Quick Start

Run all tests:
```bash
./tests/test.sh
```

### Test Suites

The test suite is organized into four categories:

#### 1. Smoke Tests (`tests/01_smoke_tests.sh`)
Quick sanity checks that verify the Docker image builds correctly and contains required components:
- Docker build succeeds
- Image contains nginx, ffmpeg, and RTMP module
- Configuration files and scripts are present

#### 2. Unit Tests (`tests/02_unit_tests.sh`)
Validates service configuration and environment variable handling in isolation:
- Services remain disabled without keys
- Services enable when keys are provided
- Environment variables correctly replace placeholders
- Twitch transformer configuration
- IP range authorization

#### 3. Integration Tests (`tests/03_integration_tests.sh`)
Ensures the full system integrates correctly under various configurations:
- Container starts with no services
- Container starts with individual services
- Container starts with all services enabled
- nginx process runs correctly
- Port 1935 is listening
- No startup errors in logs

#### 4. Functional Tests (`tests/04_functional_tests.sh`)
End-to-end tests of actual RTMP streaming functionality:
- RTMP connections are accepted
- Streams are logged
- Archive recording works
- IP-based authorization
- Multiple simultaneous streams

## Running Individual Test Suites

You can run individual test suites directly:

```bash
# Smoke tests only
bash tests/01_smoke_tests.sh

# Unit tests only
bash tests/02_unit_tests.sh

# Integration tests only
bash tests/03_integration_tests.sh

# Functional tests only
bash tests/04_functional_tests.sh
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

## Test Types Explained

- **Smoke Tests**: Fast sanity checks to verify the build works and basic components are present
- **Unit Tests**: Test individual components in isolation (config scripts, environment variable substitution)
- **Integration Tests**: Test how components work together (container startup with various service combinations)
- **Functional Tests**: End-to-end tests simulating real-world usage (actual RTMP streaming and recording)

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

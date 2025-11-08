---
title: Service Testing
description: Adding automated tests for new streaming services
audience: developers
doc_type: howto
tags: [development, testing, quality, security]
lastReviewed: 2025-10-21
version: 1.x
---

# Service Testing

This guide explains how to add automated tests for your new streaming service.

!!! warning "Testing is Required"
    Adding tests is **mandatory** when implementing a new streaming service. Tests ensure your service works correctly and prevent regressions.

## Why Testing Matters

The docker-rtmp-multistream project has tests covering:
- Input security
- Smoke tests for build verification
- Unit tests for service configuration
- Integration tests for container startup
- Functional tests for end-to-end streaming

Your new streaming service must maintain this standard of quality and security.

## Test Categories

Add tests to the following test suites:

### Unit Tests (`tests/02_unit_tests.sh`)

Unit tests verify that your service configuration scripts work correctly in isolation.

#### 1. Test Service Enablement with Key

Verifies that the service is properly enabled when the required key is provided:

```bash
test_{service}_service_enables_with_key() {
  docker run --rm --entrypoint sh -e SERVICE_KEY=test_key rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_{service}.sh >/dev/null 2>&1
    grep -v '^#' /etc/nginx/http.d/app.conf | grep -q 'apps/{service}.conf'
  "
  return $?
}
```

#### 2. Test Service Skips Without Key

Verifies that the service gracefully skips configuration when the key is missing:

```bash
test_{service}_service_skips_without_key() {
  docker run --rm --entrypoint sh rtmp-multistream:test -c "
    /scripts/pre-init.d/90_configure_{service}.sh 2>&1 | grep -q 'SERVICE_KEY is not set'
  "
  return $?
}
```

#### 3. Test Config Variable Replacement

Verifies that environment variables are correctly substituted in config files:

```bash
test_{service}_config_variables_replaced() {
  docker run --rm --entrypoint sh -e SERVICE_KEY=my_stream_key rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_{service}.sh >/dev/null 2>&1
    grep -q 'my_stream_key' /etc/nginx/http.d/apps/{service}.conf
  "
  return $?
}
```

#### 4. Test Malicious Input Rejection

**CRITICAL FOR SECURITY**: Verifies that malicious inputs are rejected:

```bash
test_malicious_{service}_key_rejected() {
  docker run --rm --entrypoint sh -e SERVICE_KEY='test;rm -rf /' rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_{service}.sh 2>&1 | grep -q 'ERROR'
  "
  return $?
}
```

This test ensures your validation prevents command injection attacks.

#### 5. Test Transformer Configuration (If Applicable)

For services using the transformer pattern, verify FFmpeg configuration:

```bash
test_{service}_transformer_configured() {
  docker run --rm --entrypoint sh -e SERVICE_KEY=test -e SERVICE_HEIGHT=1080 rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_{service}.sh >/dev/null 2>&1
    grep -q 'scale=-1:1080' /etc/nginx/http.d/transformers/{service}.conf
  "
  return $?
}
```

#### Register Your Unit Tests

At the bottom of `tests/02_unit_tests.sh`, add:

```bash
run_test "{Service} service enables with key" test_{service}_service_enables_with_key
run_test "{Service} service skips without key" test_{service}_service_skips_without_key
run_test "{Service} config variables replaced" test_{service}_config_variables_replaced
run_test "Malicious {service} key rejected" test_malicious_{service}_key_rejected
# Add transformer test if applicable:
# run_test "{Service} transformer configured" test_{service}_transformer_configured
```

### Integration Tests (`tests/03_integration_tests.sh`)

Integration tests verify that the container starts and runs correctly with your service enabled.

#### Test Container Startup

```bash
test_container_starts_with_{service}() {
  docker run -d --name test-rtmp-{service} -e SERVICE_KEY=test_key rtmp-multistream:test >/dev/null 2>&1
  sleep 3
  docker ps | grep -q test-rtmp-{service}
  local result=$?
  docker stop test-rtmp-{service} >/dev/null 2>&1
  docker rm test-rtmp-{service} >/dev/null 2>&1
  return $result
}
```

#### Register Your Integration Test

At the bottom of `tests/03_integration_tests.sh`, add:

```bash
run_test "Container starts with {service}" test_container_starts_with_{service}
```

### Validation Tests (`tests/00_validation_tests.sh`)

If you added new validation functions in `validate_input.sh` for service-specific variables, add automated tests.

#### Test Structure

Each validation function should have tests for:

- **Valid inputs**: Various acceptable formats
- **Invalid inputs**: Injection attempts, wrong formats
- **Edge cases**: Empty values, boundaries, special characters

#### Example Test Structure

```bash
echo "Testing validate_{service}_format..."

# Valid inputs
test_validate_{service}_format_valid_standard() {
  validate_{service}_format "standard-value" "TEST" 2>/dev/null
  return $?
}

test_validate_{service}_format_valid_special() {
  validate_{service}_format "value_with-chars" "TEST" 2>/dev/null
  return $?
}

# Invalid inputs
test_validate_{service}_format_invalid_injection() {
  ! validate_{service}_format "value;rm -rf /" "TEST" 2>/dev/null
  return $?
}

test_validate_{service}_format_invalid_length() {
  ! validate_{service}_format "$(printf 'a%.0s' {1..501})" "TEST" 2>/dev/null
  return $?
}

# Register tests
run_test "  valid: standard format" test_validate_{service}_format_valid_standard
run_test "  valid: with special chars" test_validate_{service}_format_valid_special
run_test "  invalid: shell metacharacters" test_validate_{service}_format_invalid_injection
run_test "  invalid: excessive length" test_validate_{service}_format_invalid_length
```

## Running Your Tests

### Run All Tests

```bash
./tests/test.sh
```

This runs all tests across all suites. Your new tests will be included automatically.

### Run Specific Test Suites

```bash
# Unit tests only
bash tests/02_unit_tests.sh

# Integration tests only
bash tests/03_integration_tests.sh

# Validation tests only
bash tests/00_validation_tests.sh
```

### Verify Success

All tests must pass (exit code 0) before your service implementation is complete.

Expected output:
```
=== Unit Tests ===
✓ {Service} service enables with key
✓ {Service} service skips without key
✓ {Service} config variables replaced
✓ Malicious {service} key rejected

=== Integration Tests ===
✓ Container starts with {service}

All tests passed!
```

## Manual Testing

After automated tests pass, perform manual end-to-end testing:

```bash
# Build the image
docker build -t rtmp-multistream .

# Configure environment
echo "SERVICE_KEY=your-test-key" >> env/relay.env

# Start the service
docker compose up

# In another terminal, send a test stream
ffmpeg -re -i test.mp4 -c copy -f flv rtmp://localhost/relay/test
```

### Verify Logs

Check container logs for:
- Service configuration message: "{Service} configured and enabled"
- Connection to service ingest server
- No error messages
- Stream processing logs

```bash
docker compose logs relay | grep -i {service}
```

## Testing Checklist

Before submitting your service implementation, ensure:

- [ ] **Unit tests added** to `tests/02_unit_tests.sh`:
  - [ ] Service enables with key
  - [ ] Service skips without key
  - [ ] Config variables replaced correctly
  - [ ] Malicious input rejected (REQUIRED for security)
  - [ ] Transformer configured (if applicable)
- [ ] **Integration test added** to `tests/03_integration_tests.sh`:
  - [ ] Container starts with service enabled
- [ ] **Validation tests added** to `tests/00_validation_tests.sh` (if new validation functions added):
  - [ ] Valid inputs accepted
  - [ ] Invalid inputs rejected
  - [ ] Edge cases handled
- [ ] **All automated tests pass**: `./tests/test.sh` exits with code 0
- [ ] **Manual testing completed**: Verified end-to-end streaming functionality
- [ ] **Logs verified**: No errors, service enables correctly

## Common Testing Pitfalls

### Pitfall 1: Not Testing Security

**Problem**: Forgetting to test malicious input rejection

**Impact**: Security vulnerabilities (command injection, path traversal)

**Solution**: Always include malicious input tests

### Pitfall 2: Not Cleaning Up Containers

**Problem**: Test containers left running after failure

**Impact**: Port conflicts, resource exhaustion

**Solution**: Always include cleanup in tests (see integration test pattern)

### Pitfall 3: Hardcoding Test Values

**Problem**: Using production keys or endpoints in tests

**Impact**: Tests may fail, security concerns

**Solution**: Use placeholder values like `test_key`

### Pitfall 4: Not Testing Both Paths

**Problem**: Only testing successful configuration, not graceful failure

**Impact**: Services may crash or behave unexpectedly when misconfigured

**Solution**: Test both "enables with key" and "skips without key"

## See Also

- [Adding Services Overview](../adding-services/overview.md) - Complete guide overview
- [Service Configuration](configuration.md) - Configuration implementation steps
- [Testing Guide](../testing.md) - General testing documentation
- [Security](../../security.md) - Security features and validation

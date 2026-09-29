---
title: Test a New Service
description: Add unit, integration and validation tests for a new streaming service
audience: developers
doc_type: howto
tags: [development, testing, services, security]
lastReviewed: 2026-09-29
version: 1.x
---

# Test a New Service

This guide adds tests for a new service, continuing the `example` service from [Add a Streaming Service](overview.md). Replace `example`, `Example` and `EXAMPLE_` with your service's name.

## Before You Begin

- The tests run against the `rtmp-multistream:test` image. `./tests/test.sh` builds it from your working tree. To run one suite on its own, build it first:

    ```bash
    docker build -t rtmp-multistream:test .
    ```

- Use placeholder keys such as `test_key`. Never put a real stream key in a test.

## Add Unit Tests

Add these functions to `tests/02_unit_tests.sh`, before the `run_test` lines.

The enable test filters out commented lines with `grep -Ev '^[[:space:]]*#'`. The include lines in `app.conf` are indented, so `grep -v '^#'` would let a commented include through and the test would pass for a service that is never enabled.

```bash
test_example_service_enables_with_key() {
  docker run --rm --entrypoint sh -e EXAMPLE_KEY=test_key rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_example.sh >/dev/null 2>&1
    grep -Ev '^[[:space:]]*#' /etc/nginx/http.d/app.conf | grep -q 'apps/example.conf'
  "
  return $?
}

test_example_service_skips_without_key() {
  docker run --rm --entrypoint sh rtmp-multistream:test -c "
    /scripts/pre-init.d/90_configure_example.sh 2>&1 | grep -q 'EXAMPLE_KEY is not set'
  "
  return $?
}

test_example_config_variables_replaced() {
  docker run --rm --entrypoint sh -e EXAMPLE_KEY=my_stream_key rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_example.sh >/dev/null 2>&1
    grep -q 'my_stream_key' /etc/nginx/http.d/apps/example.conf
  "
  return $?
}

test_malicious_example_key_rejected() {
  docker run --rm --entrypoint sh -e EXAMPLE_KEY='test;rm -rf /' rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_example.sh 2>&1 | grep -q 'ERROR'
  "
  return $?
}
```

For a Transformer, also check each computed value in the transformer file. With `EXAMPLE_KBITS_PER_VIDEO_FRAME` defaulting to `50`:

```bash
test_example_transformer_bitrate_computed() {
  docker run --rm --entrypoint sh -e EXAMPLE_KEY=test -e EXAMPLE_FPS=60 rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_example.sh >/dev/null 2>&1
    grep -q -- '-b:v 3000k' /etc/nginx/http.d/transformers/example.conf
  "
  return $?
}
```

Register the tests with the other `run_test` lines, above the final `finish_suite` line:

```bash
run_test "Example service enables with key" test_example_service_enables_with_key
run_test "Example service skips without key" test_example_service_skips_without_key
run_test "Example config variables replaced" test_example_config_variables_replaced
run_test "Malicious Example key rejected" test_malicious_example_key_rejected
```

## Add Integration Tests

Add these to `tests/03_integration_tests.sh`. The first starts the container with the service on and checks that nginx accepts the generated config. The second checks that a bad value stops the container.

```bash
test_container_starts_with_example() {
  docker run -d --name test-rtmp-example -e EXAMPLE_KEY=test_key rtmp-multistream:test >/dev/null 2>&1
  sleep 3
  docker ps | grep -q test-rtmp-example
  local result=$?
  docker exec test-rtmp-example nginx -t 2>&1 | grep -q "syntax is ok" || result=1
  docker stop test-rtmp-example >/dev/null 2>&1
  docker rm test-rtmp-example >/dev/null 2>&1
  return $result
}

test_container_stops_on_malicious_example_key() {
  docker run -d --name test-rtmp-example-bad -e EXAMPLE_KEY='a;b' rtmp-multistream:test >/dev/null 2>&1
  sleep 3
  local running
  running=$(docker inspect -f '{{.State.Running}}' test-rtmp-example-bad 2>/dev/null)
  docker rm -f test-rtmp-example-bad >/dev/null 2>&1
  [ "$running" = "false" ]
}
```

Register them above the final `finish_suite` line:

```bash
run_test "Container starts with Example" test_container_starts_with_example
run_test "Container stops on malicious Example key" test_container_stops_on_malicious_example_key
```

## Test a New Validator

If you added a function to `build/scripts/validate_input.sh`, test it in `tests/00_validation_tests.sh` with the `run_validation_test` helper defined at the top of that file. It runs the function inside the container, where `validate_input.sh` exists, and compares the exit code with the expected one: `0` for accept, `1` for reject.

```bash
test_example_host_valid() {
  run_validation_test "validate_example_host" "live.example.com" "host name" 0
}

test_example_host_invalid_semicolon() {
  run_validation_test "validate_example_host" "live.example.com;rm -rf /" "with semicolon" 1
}
```

Do not call the validator directly from the test function. The suite runs on the host, where the function does not exist: the call returns 127, and every test that expects a rejection passes without testing anything.

`run_validation_test` wraps the value in single quotes, so it cannot pass a value that contains `'`. For that case, pass the value through an environment variable, as `test_path_invalid_single_quote` does.

Register the tests in the `validate_*` block near the end of the file:

```bash
echo ""
echo "Testing validate_example_host..."
run_test "  valid: host name" test_example_host_valid
run_test "  invalid: semicolon" test_example_host_invalid_semicolon
```

## Run the Tests

```bash
./tests/test.sh
```

The run ends with `All tests passed!` and exits 0. Each new test is listed with a `✓`. To run one suite on its own, build the image first (see [Before You Begin](#before-you-begin)), then:

```bash
bash tests/02_unit_tests.sh
```

A suite run on its own ends with `Tests run: <N>, passed: <N>, failed: 0`.

To check that a test can fail, break the thing it tests and run it again. For example, change `#include` to `# include` for your service in `app.conf`: the enable test should fail.

## See Also

- [Add a Streaming Service](overview.md) - Step-by-step guide
- [Service Contract Reference](configuration.md) - Rules for includes, placeholders and scripts
- [Run the Tests](../testing.md) - Test suites and CI
- [Input Validation Reference](../validation.md) - Validation functions and what they reject

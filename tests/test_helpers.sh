#!/usr/bin/env bash
# Test helper functions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters (shared with main test.sh via exports)
export TESTS_RUN=${TESTS_RUN:-0}
export TESTS_PASSED=${TESTS_PASSED:-0}
export TESTS_FAILED=${TESTS_FAILED:-0}

# Run a single test. Always returns 0 so test.sh (set -e) keeps going after a
# failure; TESTS_FAILED decides the exit code.
run_test() {
  local test_name="$1"
  local test_function="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if $test_function; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $test_name"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  return 0
}

# Export for use by test.sh
export -f run_test

# Print a summary and exit non-zero on failure. Suites call this only when
# run directly; test.sh sources them and prints its own summary.
finish_suite() {
  echo -e "\nTests run: $TESTS_RUN, passed: $TESTS_PASSED, failed: $TESTS_FAILED"
  [ "$TESTS_FAILED" -eq 0 ]
  exit $?
}

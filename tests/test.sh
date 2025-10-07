#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Cleanup function
cleanup() {
  echo -e "\n${YELLOW}Cleaning up test resources...${NC}"
  docker compose -f docker-compose.test.yml down -v 2>/dev/null || true
  rm -rf tmp 2>/dev/null || true
}

# Register cleanup on exit
trap cleanup EXIT

# Test result function
test_result() {
  local test_name=$1
  local result=$2

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$result" -eq 0 ]; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} $test_name"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# Print section header
section() {
  echo -e "\n${YELLOW}=== $1 ===${NC}"
}

# Main test execution
main() {
  echo -e "${YELLOW}Starting docker-rtmp-multistream test suite...${NC}\n"

  # Change to tests directory if not already there
  cd "$(dirname "$0")"

  # Create temp directory for tests
  mkdir -p tmp

  # Run test suites
  section "Validation Tests"
  source 00_validation_tests.sh

  section "Smoke Tests"
  source 01_smoke_tests.sh

  section "Unit Tests"
  source 02_unit_tests.sh

  section "Integration Tests"
  source 03_integration_tests.sh

  section "Functional Tests"
  source 04_functional_tests.sh

  # Print summary
  echo -e "\n${YELLOW}=== Test Summary ===${NC}"
  echo -e "Total tests run: $TESTS_RUN"
  echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"

  if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    exit 1
  else
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
  fi
}

main "$@"

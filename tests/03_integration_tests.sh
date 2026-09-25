#!/usr/bin/env bash
# Integration Tests - Verify container starts and runs correctly with various configurations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_TMP="$SCRIPT_DIR/tmp"
source "$SCRIPT_DIR/test_helpers.sh"

test_container_starts_without_config() {
  docker run -d --name test-rtmp-no-config rtmp-multistream:test >/dev/null 2>&1
  sleep 3
  docker ps | grep -q test-rtmp-no-config
  local result=$?
  docker stop test-rtmp-no-config >/dev/null 2>&1
  docker rm test-rtmp-no-config >/dev/null 2>&1
  return $result
}

test_container_starts_with_twitch() {
  docker run -d --name test-rtmp-twitch -e TWITCH_KEY=test_key rtmp-multistream:test >/dev/null 2>&1
  sleep 3
  docker ps | grep -q test-rtmp-twitch
  local result=$?
  docker stop test-rtmp-twitch >/dev/null 2>&1
  docker rm test-rtmp-twitch >/dev/null 2>&1
  return $result
}

test_container_starts_with_youtube() {
  docker run -d --name test-rtmp-youtube -e YOUTUBE_KEY=test_key rtmp-multistream:test >/dev/null 2>&1
  sleep 3
  docker ps | grep -q test-rtmp-youtube
  local result=$?
  docker stop test-rtmp-youtube >/dev/null 2>&1
  docker rm test-rtmp-youtube >/dev/null 2>&1
  return $result
}

test_container_starts_with_all_services() {
  mkdir -p "$TEST_TMP/archive"
  chmod 777 "$TEST_TMP/archive"
  docker run -d --name test-rtmp-all \
    -e TWITCH_KEY=test_key \
    -e YOUTUBE_KEY=test_key \
    -e ARCHIVE_PATH=/tmp/archive \
    -v "$TEST_TMP/archive:/tmp/archive" \
    rtmp-multistream:test >/dev/null 2>&1
  sleep 3
  docker ps | grep -q test-rtmp-all
  local result=$?
  docker stop test-rtmp-all >/dev/null 2>&1
  docker rm test-rtmp-all >/dev/null 2>&1
  return $result
}

test_nginx_process_running() {
  docker run -d --name test-rtmp-process rtmp-multistream:test >/dev/null 2>&1
  sleep 3
  docker exec test-rtmp-process ps aux | grep -q "[n]ginx"
  local result=$?
  docker stop test-rtmp-process >/dev/null 2>&1
  docker rm test-rtmp-process >/dev/null 2>&1
  return $result
}

test_port_1935_listening() {
  docker run -d --name test-rtmp-port -p 11935:1935 rtmp-multistream:test >/dev/null 2>&1
  sleep 3
  docker exec test-rtmp-port netstat -tuln | grep -q ":1935"
  local result=$?
  docker stop test-rtmp-port >/dev/null 2>&1
  docker rm test-rtmp-port >/dev/null 2>&1
  return $result
}

test_nginx_config_valid_after_startup() {
  docker run -d --name test-rtmp-config -e TWITCH_KEY=test rtmp-multistream:test >/dev/null 2>&1
  sleep 3
  docker exec test-rtmp-config nginx -t 2>&1 | grep -q "syntax is ok"
  local result=$?
  docker stop test-rtmp-config >/dev/null 2>&1
  docker rm test-rtmp-config >/dev/null 2>&1
  return $result
}

test_container_logs_no_errors() {
  docker run -d --name test-rtmp-logs rtmp-multistream:test >/dev/null 2>&1
  sleep 3
  # Check for common error patterns
  docker logs test-rtmp-logs 2>&1 | grep -i -q -E "(error|failed|fatal)" && local has_errors=1 || local has_errors=0
  docker stop test-rtmp-logs >/dev/null 2>&1
  docker rm test-rtmp-logs >/dev/null 2>&1
  [ $has_errors -eq 0 ]
  return $?
}

test_container_starts_with_twitch_partner_mode() {
  docker run -d --name test-rtmp-twitch-partner -e TWITCH_KEY=test_key -e TWITCH_PARTNER=TRUE rtmp-multistream:test >/dev/null 2>&1
  sleep 3
  docker ps | grep -q test-rtmp-twitch-partner
  local result=$?
  docker stop test-rtmp-twitch-partner >/dev/null 2>&1
  docker rm test-rtmp-twitch-partner >/dev/null 2>&1
  return $result
}

test_container_starts_with_twitch_nonpartner_mode() {
  docker run -d --name test-rtmp-twitch-nonpartner -e TWITCH_KEY=test_key -e TWITCH_PARTNER=FALSE rtmp-multistream:test >/dev/null 2>&1
  sleep 3
  docker ps | grep -q test-rtmp-twitch-nonpartner
  local result=$?
  docker stop test-rtmp-twitch-nonpartner >/dev/null 2>&1
  docker rm test-rtmp-twitch-nonpartner >/dev/null 2>&1
  return $result
}

test_container_stops_on_invalid_value() {
  docker run -d --name test-rtmp-invalid -e YOUTUBE_KEY='bad key!' rtmp-multistream:test >/dev/null 2>&1
  sleep 3
  local running
  running=$(docker inspect -f '{{.State.Running}}' test-rtmp-invalid 2>/dev/null)
  docker rm -f test-rtmp-invalid >/dev/null 2>&1
  [ "$running" = "false" ]
}

test_container_stops_on_unwritable_archive_path() {
  docker run -d --name test-rtmp-unwritable -e ARCHIVE_PATH=/nonexistent rtmp-multistream:test >/dev/null 2>&1
  sleep 3
  local running
  running=$(docker inspect -f '{{.State.Running}}' test-rtmp-unwritable 2>/dev/null)
  docker rm -f test-rtmp-unwritable >/dev/null 2>&1
  [ "$running" = "false" ]
}

# Run tests
run_test "Container starts without configuration" test_container_starts_without_config
run_test "Container starts with Twitch enabled" test_container_starts_with_twitch
run_test "Container starts with YouTube enabled" test_container_starts_with_youtube
run_test "Container starts with all services" test_container_starts_with_all_services
run_test "nginx process is running" test_nginx_process_running
run_test "Port 1935 is listening" test_port_1935_listening
run_test "nginx config valid after startup" test_nginx_config_valid_after_startup
run_test "Container logs show no errors" test_container_logs_no_errors
run_test "Container starts with Twitch partner mode" test_container_starts_with_twitch_partner_mode
run_test "Container starts with Twitch non-partner mode" test_container_starts_with_twitch_nonpartner_mode
run_test "Container stops on invalid value" test_container_stops_on_invalid_value
run_test "Container stops on unwritable archive path" test_container_stops_on_unwritable_archive_path

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then finish_suite; fi

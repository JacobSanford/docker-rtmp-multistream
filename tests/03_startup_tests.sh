#!/usr/bin/env bash
# Startup Tests - Verify container starts and runs correctly

source tests/test_helpers.sh

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
  mkdir -p tests/tmp/archive
  docker run -d --name test-rtmp-all \
    -e TWITCH_KEY=test_key \
    -e YOUTUBE_KEY=test_key \
    -e ARCHIVE_PATH=/tmp/archive \
    -v "$(pwd)/tests/tmp/archive:/tmp/archive" \
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

# Run tests
run_test "Container starts without configuration" test_container_starts_without_config
run_test "Container starts with Twitch enabled" test_container_starts_with_twitch
run_test "Container starts with YouTube enabled" test_container_starts_with_youtube
run_test "Container starts with all services" test_container_starts_with_all_services
run_test "nginx process is running" test_nginx_process_running
run_test "Port 1935 is listening" test_port_1935_listening
run_test "nginx config valid after startup" test_nginx_config_valid_after_startup
run_test "Container logs show no errors" test_container_logs_no_errors

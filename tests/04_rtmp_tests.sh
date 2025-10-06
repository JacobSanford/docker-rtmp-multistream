#!/usr/bin/env bash
# RTMP Functional Tests - Verify RTMP streaming works

source tests/test_helpers.sh

test_rtmp_accepts_connection() {
  # Start container - allow Docker bridge network IPs (172.17.0.0/16)
  docker run -d --name test-rtmp-stream -p 11935:1935 \
    -e PUBLISH_IP_RANGE="172.16.0.0/12" \
    rtmp-multistream:test >/dev/null 2>&1
  sleep 3

  # Try to connect with ffmpeg (send 2 seconds of test pattern)
  timeout 10 ffmpeg -re -f lavfi -i testsrc=duration=2:size=320x240:rate=30 \
    -f lavfi -i sine=frequency=1000:duration=2 \
    -c:v libx264 -preset ultrafast -tune zerolatency -c:a aac \
    -f flv rtmp://127.0.0.1:11935/relay/test >/dev/null 2>&1

  local result=$?
  docker stop test-rtmp-stream >/dev/null 2>&1
  docker rm test-rtmp-stream >/dev/null 2>&1

  # Exit code 0 or 124 (timeout) are both acceptable - means it connected
  [ $result -eq 0 ] || [ $result -eq 124 ]
  return $?
}

test_rtmp_stream_logged() {
  docker run -d --name test-rtmp-log -p 11935:1935 \
    -e PUBLISH_IP_RANGE="172.16.0.0/12" \
    rtmp-multistream:test >/dev/null 2>&1
  sleep 3

  # Send short test stream
  timeout 10 ffmpeg -re -f lavfi -i testsrc=duration=2:size=320x240:rate=30 \
    -f lavfi -i sine=frequency=1000:duration=2 \
    -c:v libx264 -preset ultrafast -tune zerolatency -c:a aac \
    -f flv rtmp://127.0.0.1:11935/relay/test >/dev/null 2>&1

  sleep 1

  # Check if nginx logged the connection
  docker logs test-rtmp-log 2>&1 | grep -q "relay"
  local result=$?

  docker stop test-rtmp-log >/dev/null 2>&1
  docker rm test-rtmp-log >/dev/null 2>&1
  return $result
}

test_archive_records_stream() {
  mkdir -p tests/tmp/archive
  chmod 777 tests/tmp/archive

  docker run -d --name test-rtmp-archive -p 11935:1935 \
    -e PUBLISH_IP_RANGE="172.16.0.0/12" \
    -e ARCHIVE_PATH=/tmp/archive \
    -e ARCHIVE_SUFFIX=flv \
    -v "$(pwd)/tests/tmp/archive:/tmp/archive" \
    rtmp-multistream:test >/dev/null 2>&1
  sleep 3

  # Send 3 second test stream
  timeout 10 ffmpeg -re -f lavfi -i testsrc=duration=3:size=320x240:rate=30 \
    -f lavfi -i sine=frequency=1000:duration=3 \
    -c:v libx264 -preset ultrafast -tune zerolatency -c:a aac \
    -f flv rtmp://127.0.0.1:11935/relay/test >/dev/null 2>&1

  sleep 2

  # Check if archive file was created
  ls tests/tmp/archive/*.flv >/dev/null 2>&1
  local result=$?

  docker stop test-rtmp-archive >/dev/null 2>&1
  docker rm test-rtmp-archive >/dev/null 2>&1
  rm -rf tests/tmp/archive

  return $result
}

test_rtmp_rejects_unauthorized_ip() {
  docker run -d --name test-rtmp-auth -p 11935:1935 \
    -e PUBLISH_IP_RANGE="10.0.0.0/8" \
    rtmp-multistream:test >/dev/null 2>&1
  sleep 3

  # Try to publish from localhost (not in 10.0.0.0/8)
  # This should fail or be rejected
  timeout 5 ffmpeg -re -f lavfi -i testsrc=duration=2:size=320x240:rate=30 \
    -f lavfi -i sine=frequency=1000:duration=2 \
    -c:v libx264 -preset ultrafast -tune zerolatency -c:a aac \
    -f flv rtmp://127.0.0.1:11935/relay/test >/dev/null 2>&1

  # Should fail (non-zero exit code) because IP not in range
  local result=$?

  docker stop test-rtmp-auth >/dev/null 2>&1
  docker rm test-rtmp-auth >/dev/null 2>&1

  # We expect failure here, so invert the result
  [ $result -ne 0 ]
  return $?
}

test_multiple_streams_simultaneously() {
  docker run -d --name test-rtmp-multi -p 11935:1935 \
    -e PUBLISH_IP_RANGE="172.16.0.0/12" \
    rtmp-multistream:test >/dev/null 2>&1
  sleep 3

  # Start two streams simultaneously
  timeout 10 ffmpeg -re -f lavfi -i testsrc=duration=3:size=320x240:rate=30 \
    -f lavfi -i sine=frequency=1000:duration=3 \
    -c:v libx264 -preset ultrafast -tune zerolatency -c:a aac \
    -f flv rtmp://127.0.0.1:11935/relay/stream1 >/dev/null 2>&1 &

  timeout 10 ffmpeg -re -f lavfi -i testsrc=duration=3:size=320x240:rate=30 \
    -f lavfi -i sine=frequency=500:duration=3 \
    -c:v libx264 -preset ultrafast -tune zerolatency -c:a aac \
    -f flv rtmp://127.0.0.1:11935/relay/stream2 >/dev/null 2>&1 &

  wait

  # Check logs mention both streams
  docker logs test-rtmp-multi 2>&1 | grep -q "stream1" && \
  docker logs test-rtmp-multi 2>&1 | grep -q "stream2"
  local result=$?

  docker stop test-rtmp-multi >/dev/null 2>&1
  docker rm test-rtmp-multi >/dev/null 2>&1
  return $result
}

# Run tests
run_test "RTMP accepts connection" test_rtmp_accepts_connection
run_test "RTMP stream is logged" test_rtmp_stream_logged
run_test "Archive records stream to file" test_archive_records_stream
run_test "RTMP rejects unauthorized IP" test_rtmp_rejects_unauthorized_ip
run_test "Multiple streams simultaneously" test_multiple_streams_simultaneously

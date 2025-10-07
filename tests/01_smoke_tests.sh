#!/usr/bin/env bash
# Smoke Tests - Verify Docker image builds and contains required components

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

test_docker_build() {
  docker build -t rtmp-multistream:test "$PROJECT_ROOT" >/dev/null 2>&1
  return $?
}

test_docker_build_with_buildkit() {
  DOCKER_BUILDKIT=1 docker build -t rtmp-multistream:test "$PROJECT_ROOT" >/dev/null 2>&1
  return $?
}

test_image_has_nginx() {
  docker run --rm --entrypoint which rtmp-multistream:test nginx >/dev/null 2>&1
  return $?
}

test_image_has_ffmpeg() {
  docker run --rm --entrypoint which rtmp-multistream:test ffmpeg >/dev/null 2>&1
  return $?
}

test_image_has_rtmp_module() {
  docker run --rm --entrypoint nginx rtmp-multistream:test -V 2>&1 | grep -q "rtmp"
  return $?
}

test_image_has_required_scripts() {
  docker run --rm --entrypoint test rtmp-multistream:test -f /scripts/enableService.sh
  return $?
}

test_image_has_config_files() {
  docker run --rm --entrypoint sh rtmp-multistream:test -c "test -f /etc/nginx/http.d/app.conf && test -f /etc/nginx/http.d/apps/twitch.conf && test -f /etc/nginx/http.d/apps/youtube.conf"
  return $?
}

# Run tests
run_test "Docker image builds successfully" test_docker_build
run_test "Docker image builds with BuildKit" test_docker_build_with_buildkit
run_test "Image contains nginx" test_image_has_nginx
run_test "Image contains ffmpeg" test_image_has_ffmpeg
run_test "Image has RTMP module" test_image_has_rtmp_module
run_test "Image has enableService.sh script" test_image_has_required_scripts
run_test "Image has nginx config files" test_image_has_config_files

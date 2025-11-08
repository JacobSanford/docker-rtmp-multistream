#!/usr/bin/env bash
# Unit Tests - Verify service configuration and environment variable handling

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

test_no_services_enabled_by_default() {
  # Check that services are commented out by default
  docker run --rm --entrypoint sh rtmp-multistream:test -c "grep -q '#include.*apps/twitch.conf' /etc/nginx/http.d/app.conf"
  local twitch_commented=$?

  docker run --rm --entrypoint sh rtmp-multistream:test -c "grep -q '#include.*apps/youtube.conf' /etc/nginx/http.d/app.conf"
  local youtube_commented=$?

  docker run --rm --entrypoint sh rtmp-multistream:test -c "grep -q '#include.*apps/archive.conf' /etc/nginx/http.d/app.conf"
  local archive_commented=$?

  [ $twitch_commented -eq 0 ] && [ $youtube_commented -eq 0 ] && [ $archive_commented -eq 0 ]
  return $?
}

test_twitch_service_enables_with_key() {
  docker run --rm --entrypoint sh -e TWITCH_KEY=test_key rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_twitch.sh >/dev/null 2>&1
    grep -v '^#' /etc/nginx/http.d/app.conf | grep -q 'apps/twitch.conf'
  "
  return $?
}

test_youtube_service_enables_with_key() {
  docker run --rm --entrypoint sh -e YOUTUBE_KEY=test_key rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_youtube.sh >/dev/null 2>&1
    grep -v '^#' /etc/nginx/http.d/app.conf | grep -q 'apps/youtube.conf'
  "
  return $?
}

test_archive_service_skips_without_path() {
  docker run --rm --entrypoint sh rtmp-multistream:test -c "
    /scripts/pre-init.d/90_configure_archive.sh 2>&1 | grep -q 'ARCHIVE_PATH is not set'
  "
  return $?
}

test_twitch_config_variables_replaced() {
  docker run --rm --entrypoint sh -e TWITCH_KEY=my_stream_key -e TWITCH_ENDPOINT=sfo rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_twitch.sh >/dev/null 2>&1
    grep -q 'my_stream_key' /etc/nginx/http.d/apps/twitch.conf && \
    grep -q 'sfo' /etc/nginx/http.d/apps/twitch.conf
  "
  return $?
}

test_youtube_config_variables_replaced() {
  docker run --rm --entrypoint sh -e YOUTUBE_KEY=my_youtube_key rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_youtube.sh >/dev/null 2>&1
    grep -q 'my_youtube_key' /etc/nginx/http.d/apps/youtube.conf
  "
  return $?
}

test_twitch_transformer_configured() {
  docker run --rm --entrypoint sh -e TWITCH_KEY=test -e TWITCH_HEIGHT=1080 -e TWITCH_FPS=30 rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_twitch.sh >/dev/null 2>&1
    grep -q 'scale=-1:1080' /etc/nginx/http.d/transformers/twitch.conf && \
    grep -q '\-r 30' /etc/nginx/http.d/transformers/twitch.conf
  "
  return $?
}

test_publish_ip_range_configured() {
  docker run --rm --entrypoint sh -e PUBLISH_IP_RANGE="10.0.0.0/8" rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    grep -q '10.0.0.0/8' /etc/nginx/http.d/auth.conf
  "
  return $?
}

test_malicious_twitch_key_rejected() {
  # Test that stream key with shell metacharacters is rejected
  docker run --rm --entrypoint sh -e TWITCH_KEY='test;rm -rf /' rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_twitch.sh 2>&1 | grep -q 'ERROR'
  "
  return $?
}

test_malicious_archive_path_rejected() {
  # Test that path with shell metacharacters is rejected
  docker run --rm --entrypoint sh -e ARCHIVE_PATH='/tmp/archive;rm -rf /' rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_archive.sh 2>&1 | grep -q 'ERROR'
  "
  return $?
}

test_invalid_ip_range_rejected() {
  # Test that invalid IP range format is rejected
  docker run --rm --entrypoint sh -e PUBLISH_IP_RANGE='not-an-ip' rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh 2>&1 | grep -q 'ERROR'
  "
  return $?
}

test_invalid_log_level_rejected() {
  # Test that invalid log level is rejected
  docker run --rm --entrypoint sh -e NGINX_ERROR_LOG_LEVEL='invalid' rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh 2>&1 | grep -q 'ERROR'
  "
  return $?
}

test_invalid_numeric_values_rejected() {
  # Test that non-numeric FPS value is rejected
  docker run --rm --entrypoint sh -e TWITCH_KEY='test' -e TWITCH_FPS='not-a-number' rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_twitch.sh 2>&1 | grep -q 'ERROR'
  "
  return $?
}

test_twitch_partner_mode_enables() {
  # Test that partner mode enables twitch-partner service
  docker run --rm --entrypoint sh -e TWITCH_KEY=test_key -e TWITCH_PARTNER=TRUE rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_twitch.sh >/dev/null 2>&1
    grep -Ev '^[[:space:]]*#' /etc/nginx/http.d/app.conf | grep -q 'apps/twitch-partner.conf'
  "
  return $?
}

test_twitch_partner_mode_skips_transformer() {
  # Test that partner mode does NOT enable transformer
  docker run --rm --entrypoint sh -e TWITCH_KEY=test_key -e TWITCH_PARTNER=TRUE rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_twitch.sh >/dev/null 2>&1
    grep -Ev '^[[:space:]]*#' /etc/nginx/http.d/app.conf | grep -q 'transformers/twitch.conf' && exit 1 || exit 0
  "
  return $?
}

test_twitch_nonpartner_mode_includes_transformer() {
  # Test that non-partner mode (default) includes transformer
  docker run --rm --entrypoint sh -e TWITCH_KEY=test_key -e TWITCH_PARTNER=FALSE rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_twitch.sh >/dev/null 2>&1
    grep -Ev '^[[:space:]]*#' /etc/nginx/http.d/app.conf | grep -q 'transformers/twitch.conf'
  "
  return $?
}

test_twitch_partner_mode_variables_replaced() {
  # Test that partner mode replaces KEY and ENDPOINT in twitch-partner.conf
  docker run --rm --entrypoint sh -e TWITCH_KEY=partner_key -e TWITCH_PARTNER=TRUE -e TWITCH_ENDPOINT=lax rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_twitch.sh >/dev/null 2>&1
    grep -q 'partner_key' /etc/nginx/http.d/apps/twitch-partner.conf && \
    grep -q 'lax' /etc/nginx/http.d/apps/twitch-partner.conf
  "
  return $?
}

test_invalid_twitch_partner_value_rejected() {
  # Test that invalid TWITCH_PARTNER value is rejected
  docker run --rm --entrypoint sh -e TWITCH_KEY=test -e TWITCH_PARTNER='yes' rtmp-multistream:test -c "
    /scripts/pre-init.d/89_configure_app.sh >/dev/null 2>&1
    /scripts/pre-init.d/90_configure_twitch.sh 2>&1 | grep -q 'ERROR'
  "
  return $?
}

# Run tests
run_test "No services enabled by default" test_no_services_enabled_by_default
run_test "Twitch service enables with key" test_twitch_service_enables_with_key
run_test "YouTube service enables with key" test_youtube_service_enables_with_key
run_test "Archive service skips without path" test_archive_service_skips_without_path
run_test "Twitch config variables replaced" test_twitch_config_variables_replaced
run_test "YouTube config variables replaced" test_youtube_config_variables_replaced
run_test "Twitch transformer configured" test_twitch_transformer_configured
run_test "Publish IP range configured" test_publish_ip_range_configured
run_test "Malicious Twitch key rejected" test_malicious_twitch_key_rejected
run_test "Malicious archive path rejected" test_malicious_archive_path_rejected
run_test "Invalid IP range rejected" test_invalid_ip_range_rejected
run_test "Invalid log level rejected" test_invalid_log_level_rejected
run_test "Invalid numeric values rejected" test_invalid_numeric_values_rejected
run_test "Twitch partner mode enables" test_twitch_partner_mode_enables
run_test "Twitch partner mode skips transformer" test_twitch_partner_mode_skips_transformer
run_test "Twitch non-partner mode includes transformer" test_twitch_nonpartner_mode_includes_transformer
run_test "Twitch partner mode variables replaced" test_twitch_partner_mode_variables_replaced
run_test "Invalid TWITCH_PARTNER value rejected" test_invalid_twitch_partner_value_rejected

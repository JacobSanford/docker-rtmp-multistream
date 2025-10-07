#!/usr/bin/env bash
# Validation Function Tests - Unit tests for input validation functions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Helper to run validation tests inside container
run_validation_test() {
  local function_name="$1"
  local test_value="$2"
  local test_name="$3"
  local expected_result="$4"  # 0 for pass, 1 for fail

  docker run --rm --entrypoint sh rtmp-multistream:test -c "
    . /scripts/validate_input.sh
    $function_name '$test_value' 'TEST_VAR' >/dev/null 2>&1
  "
  local actual_result=$?

  [ $actual_result -eq $expected_result ]
  return $?
}

# ============================================================================
# validate_stream_key tests
# ============================================================================

test_stream_key_valid_alphanumeric() {
  run_validation_test "validate_stream_key" "abc123XYZ" "alphanumeric" 0
}

test_stream_key_valid_with_dash() {
  run_validation_test "validate_stream_key" "stream-key-123" "with dash" 0
}

test_stream_key_valid_with_underscore() {
  run_validation_test "validate_stream_key" "stream_key_123" "with underscore" 0
}

test_stream_key_valid_with_period() {
  run_validation_test "validate_stream_key" "stream.key.123" "with period" 0
}

test_stream_key_valid_with_colon() {
  run_validation_test "validate_stream_key" "stream:key:123" "with colon" 0
}

test_stream_key_valid_empty() {
  run_validation_test "validate_stream_key" "" "empty string" 0
}

test_stream_key_invalid_semicolon() {
  run_validation_test "validate_stream_key" "key;rm -rf /" "with semicolon" 1
}

test_stream_key_invalid_pipe() {
  run_validation_test "validate_stream_key" "key|whoami" "with pipe" 1
}

test_stream_key_invalid_ampersand() {
  run_validation_test "validate_stream_key" "key&background" "with ampersand" 1
}

test_stream_key_invalid_backtick() {
  run_validation_test "validate_stream_key" 'key`cmd`' "with backtick" 1
}

test_stream_key_invalid_dollar() {
  run_validation_test "validate_stream_key" 'key$var' "with dollar sign" 1
}

test_stream_key_invalid_path_traversal() {
  run_validation_test "validate_stream_key" "key/../../../etc/passwd" "with path traversal" 1
}

test_stream_key_invalid_too_long() {
  local long_key=$(printf 'a%.0s' {1..201})
  run_validation_test "validate_stream_key" "$long_key" "too long (201 chars)" 1
}

# ============================================================================
# validate_path tests
# ============================================================================

test_path_valid_absolute() {
  run_validation_test "validate_path" "/tmp/archive" "absolute path" 0
}

test_path_valid_deep_absolute() {
  run_validation_test "validate_path" "/var/lib/nginx/archive/streams" "deep absolute path" 0
}

test_path_valid_with_dash() {
  run_validation_test "validate_path" "/tmp/my-archive" "with dash" 0
}

test_path_valid_with_underscore() {
  run_validation_test "validate_path" "/tmp/my_archive" "with underscore" 0
}

test_path_valid_empty() {
  run_validation_test "validate_path" "" "empty string" 0
}

test_path_invalid_relative() {
  run_validation_test "validate_path" "tmp/archive" "relative path" 1
}

test_path_invalid_semicolon() {
  run_validation_test "validate_path" "/tmp/archive;rm -rf /" "with semicolon" 1
}

test_path_invalid_pipe() {
  run_validation_test "validate_path" "/tmp/archive|whoami" "with pipe" 1
}

test_path_invalid_ampersand() {
  run_validation_test "validate_path" "/tmp/archive&bg" "with ampersand" 1
}

test_path_invalid_dollar() {
  run_validation_test "validate_path" '/tmp/archive$var' "with dollar sign" 1
}

test_path_invalid_backtick() {
  run_validation_test "validate_path" '/tmp/archive`cmd`' "with backtick" 1
}

test_path_invalid_too_long() {
  local long_path="/$(printf 'a%.0s' {1..501})"
  run_validation_test "validate_path" "$long_path" "too long (501 chars)" 1
}

# ============================================================================
# validate_ip_range tests
# ============================================================================

test_ip_range_valid_class_c() {
  run_validation_test "validate_ip_range" "192.168.1.0/24" "Class C network" 0
}

test_ip_range_valid_class_b() {
  run_validation_test "validate_ip_range" "172.16.0.0/16" "Class B network" 0
}

test_ip_range_valid_class_a() {
  run_validation_test "validate_ip_range" "10.0.0.0/8" "Class A network" 0
}

test_ip_range_valid_single_host() {
  run_validation_test "validate_ip_range" "192.168.1.1/32" "Single host" 0
}

test_ip_range_invalid_no_cidr() {
  run_validation_test "validate_ip_range" "192.168.1.0" "without CIDR" 1
}

test_ip_range_invalid_text() {
  run_validation_test "validate_ip_range" "not-an-ip" "text instead of IP" 1
}

test_ip_range_invalid_empty() {
  run_validation_test "validate_ip_range" "" "empty string" 1
}

test_ip_range_invalid_incomplete() {
  run_validation_test "validate_ip_range" "192.168/16" "incomplete octets" 1
}

# ============================================================================
# validate_number tests
# ============================================================================

test_number_valid_simple() {
  docker run --rm --entrypoint sh rtmp-multistream:test -c "
    . /scripts/validate_input.sh
    validate_number '42' 'TEST' '' '' >/dev/null 2>&1
  "
  return $?
}

test_number_valid_zero() {
  docker run --rm --entrypoint sh rtmp-multistream:test -c "
    . /scripts/validate_input.sh
    validate_number '0' 'TEST' '' '' >/dev/null 2>&1
  "
  return $?
}

test_number_valid_large() {
  docker run --rm --entrypoint sh rtmp-multistream:test -c "
    . /scripts/validate_input.sh
    validate_number '123456' 'TEST' '' '' >/dev/null 2>&1
  "
  return $?
}

test_number_valid_min_bound() {
  docker run --rm --entrypoint sh rtmp-multistream:test -c "
    . /scripts/validate_input.sh
    validate_number '10' 'TEST' '10' '' >/dev/null 2>&1
  "
  return $?
}

test_number_valid_max_bound() {
  docker run --rm --entrypoint sh rtmp-multistream:test -c "
    . /scripts/validate_input.sh
    validate_number '100' 'TEST' '' '100' >/dev/null 2>&1
  "
  return $?
}

test_number_valid_within_range() {
  docker run --rm --entrypoint sh rtmp-multistream:test -c "
    . /scripts/validate_input.sh
    validate_number '50' 'TEST' '1' '100' >/dev/null 2>&1
  "
  return $?
}

test_number_invalid_text() {
  docker run --rm --entrypoint sh rtmp-multistream:test -c "
    . /scripts/validate_input.sh
    validate_number 'abc' 'TEST' '' '' >/dev/null 2>&1
  "
  local result=$?
  [ $result -eq 1 ]
}

test_number_invalid_negative() {
  docker run --rm --entrypoint sh rtmp-multistream:test -c "
    . /scripts/validate_input.sh
    validate_number '-10' 'TEST' '' '' >/dev/null 2>&1
  "
  local result=$?
  [ $result -eq 1 ]
}

test_number_invalid_decimal() {
  docker run --rm --entrypoint sh rtmp-multistream:test -c "
    . /scripts/validate_input.sh
    validate_number '3.14' 'TEST' '' '' >/dev/null 2>&1
  "
  local result=$?
  [ $result -eq 1 ]
}

test_number_invalid_below_min() {
  docker run --rm --entrypoint sh rtmp-multistream:test -c "
    . /scripts/validate_input.sh
    validate_number '5' 'TEST' '10' '' >/dev/null 2>&1
  "
  local result=$?
  [ $result -eq 1 ]
}

test_number_invalid_above_max() {
  docker run --rm --entrypoint sh rtmp-multistream:test -c "
    . /scripts/validate_input.sh
    validate_number '150' 'TEST' '' '100' >/dev/null 2>&1
  "
  local result=$?
  [ $result -eq 1 ]
}

test_number_invalid_empty() {
  docker run --rm --entrypoint sh rtmp-multistream:test -c "
    . /scripts/validate_input.sh
    validate_number '' 'TEST' '' '' >/dev/null 2>&1
  "
  local result=$?
  [ $result -eq 1 ]
}

# ============================================================================
# validate_identifier tests
# ============================================================================

test_identifier_valid_alphanumeric() {
  run_validation_test "validate_identifier" "libx264" "alphanumeric" 0
}

test_identifier_valid_with_dash() {
  run_validation_test "validate_identifier" "ultra-fast" "with dash" 0
}

test_identifier_valid_with_underscore() {
  run_validation_test "validate_identifier" "very_fast" "with underscore" 0
}

test_identifier_valid_mixed() {
  run_validation_test "validate_identifier" "preset_fast-1" "mixed characters" 0
}

test_identifier_invalid_space() {
  run_validation_test "validate_identifier" "ultra fast" "with space" 1
}

test_identifier_invalid_period() {
  run_validation_test "validate_identifier" "preset.fast" "with period" 1
}

test_identifier_invalid_special_chars() {
  run_validation_test "validate_identifier" "preset@fast" "with special char" 1
}

test_identifier_invalid_empty() {
  run_validation_test "validate_identifier" "" "empty string" 1
}

test_identifier_invalid_too_long() {
  local long_id=$(printf 'a%.0s' {1..101})
  run_validation_test "validate_identifier" "$long_id" "too long (101 chars)" 1
}

# ============================================================================
# validate_bitrate tests
# ============================================================================

test_bitrate_valid_numeric() {
  run_validation_test "validate_bitrate" "160000" "numeric only" 0
}

test_bitrate_valid_with_k() {
  run_validation_test "validate_bitrate" "160k" "with lowercase k" 0
}

test_bitrate_valid_with_K() {
  run_validation_test "validate_bitrate" "160K" "with uppercase K" 0
}

test_bitrate_valid_zero() {
  run_validation_test "validate_bitrate" "0" "zero" 0
}

test_bitrate_invalid_text() {
  run_validation_test "validate_bitrate" "fast" "text only" 1
}

test_bitrate_invalid_decimal() {
  run_validation_test "validate_bitrate" "160.5k" "with decimal" 1
}

test_bitrate_invalid_space() {
  run_validation_test "validate_bitrate" "160 k" "with space" 1
}

test_bitrate_invalid_wrong_suffix() {
  run_validation_test "validate_bitrate" "160m" "with wrong suffix" 1
}

test_bitrate_invalid_empty() {
  run_validation_test "validate_bitrate" "" "empty string" 1
}

# ============================================================================
# validate_log_level tests
# ============================================================================

test_log_level_valid_debug() {
  run_validation_test "validate_log_level" "debug" "debug level" 0
}

test_log_level_valid_info() {
  run_validation_test "validate_log_level" "info" "info level" 0
}

test_log_level_valid_notice() {
  run_validation_test "validate_log_level" "notice" "notice level" 0
}

test_log_level_valid_warn() {
  run_validation_test "validate_log_level" "warn" "warn level" 0
}

test_log_level_valid_error() {
  run_validation_test "validate_log_level" "error" "error level" 0
}

test_log_level_valid_crit() {
  run_validation_test "validate_log_level" "crit" "crit level" 0
}

test_log_level_valid_alert() {
  run_validation_test "validate_log_level" "alert" "alert level" 0
}

test_log_level_valid_emerg() {
  run_validation_test "validate_log_level" "emerg" "emerg level" 0
}

test_log_level_invalid_unknown() {
  run_validation_test "validate_log_level" "invalid" "invalid level" 1
}

test_log_level_invalid_uppercase() {
  run_validation_test "validate_log_level" "ERROR" "uppercase" 1
}

test_log_level_invalid_empty() {
  run_validation_test "validate_log_level" "" "empty string" 1
}

# ============================================================================
# validate_suffix tests
# ============================================================================

test_suffix_valid_mp4() {
  run_validation_test "validate_suffix" "mp4" "mp4 format" 0
}

test_suffix_valid_flv() {
  run_validation_test "validate_suffix" "flv" "flv format" 0
}

test_suffix_valid_mkv() {
  run_validation_test "validate_suffix" "mkv" "mkv format" 0
}

test_suffix_valid_uppercase() {
  run_validation_test "validate_suffix" "MP4" "uppercase" 0
}

test_suffix_invalid_with_dot() {
  run_validation_test "validate_suffix" ".mp4" "with leading dot" 1
}

test_suffix_invalid_with_slash() {
  run_validation_test "validate_suffix" "mp4/flv" "with slash" 1
}

test_suffix_invalid_special_chars() {
  run_validation_test "validate_suffix" "mp4-flv" "with dash" 1
}

test_suffix_invalid_empty() {
  run_validation_test "validate_suffix" "" "empty string" 1
}

test_suffix_invalid_too_long() {
  run_validation_test "validate_suffix" "verylongext" "too long (11 chars)" 1
}

# ============================================================================
# escape_for_sed tests
# ============================================================================

test_escape_for_sed_simple() {
  local result=$(docker run --rm --entrypoint sh rtmp-multistream:test -c "
    . /scripts/validate_input.sh
    escape_for_sed 'simple_text'
  ")
  [ "$result" = "simple_text" ]
}

test_escape_for_sed_with_pipe() {
  local result=$(docker run --rm --entrypoint sh rtmp-multistream:test -c "
    . /scripts/validate_input.sh
    escape_for_sed 'text|with|pipes'
  ")
  [ "$result" = 'text\|with\|pipes' ]
}

test_escape_for_sed_with_ampersand() {
  local result=$(docker run --rm --entrypoint sh rtmp-multistream:test -c "
    . /scripts/validate_input.sh
    escape_for_sed 'text&with&ampersand'
  ")
  [ "$result" = 'text\&with\&ampersand' ]
}

test_escape_for_sed_with_backslash() {
  local result=$(docker run --rm --entrypoint sh rtmp-multistream:test -c "
    . /scripts/validate_input.sh
    escape_for_sed 'text\\with\\backslash'
  ")
  echo "$result" | grep -q '\\\\'
}

test_escape_for_sed_mixed() {
  local result=$(docker run --rm --entrypoint sh rtmp-multistream:test -c "
    . /scripts/validate_input.sh
    escape_for_sed 'text|with&mixed\\chars'
  ")
  echo "$result" | grep -q '\\|' && echo "$result" | grep -q '\\&' && echo "$result" | grep -q '\\\\'
}

# ============================================================================
# Run all tests
# ============================================================================

echo "Testing validate_stream_key..."
run_test "  valid: alphanumeric" test_stream_key_valid_alphanumeric
run_test "  valid: with dash" test_stream_key_valid_with_dash
run_test "  valid: with underscore" test_stream_key_valid_with_underscore
run_test "  valid: with period" test_stream_key_valid_with_period
run_test "  valid: with colon" test_stream_key_valid_with_colon
run_test "  valid: empty string" test_stream_key_valid_empty
run_test "  invalid: semicolon" test_stream_key_invalid_semicolon
run_test "  invalid: pipe" test_stream_key_invalid_pipe
run_test "  invalid: ampersand" test_stream_key_invalid_ampersand
run_test "  invalid: backtick" test_stream_key_invalid_backtick
run_test "  invalid: dollar sign" test_stream_key_invalid_dollar
run_test "  invalid: path traversal" test_stream_key_invalid_path_traversal
run_test "  invalid: too long" test_stream_key_invalid_too_long

echo ""
echo "Testing validate_path..."
run_test "  valid: absolute path" test_path_valid_absolute
run_test "  valid: deep absolute path" test_path_valid_deep_absolute
run_test "  valid: with dash" test_path_valid_with_dash
run_test "  valid: with underscore" test_path_valid_with_underscore
run_test "  valid: empty string" test_path_valid_empty
run_test "  invalid: relative path" test_path_invalid_relative
run_test "  invalid: semicolon" test_path_invalid_semicolon
run_test "  invalid: pipe" test_path_invalid_pipe
run_test "  invalid: ampersand" test_path_invalid_ampersand
run_test "  invalid: dollar sign" test_path_invalid_dollar
run_test "  invalid: backtick" test_path_invalid_backtick
run_test "  invalid: too long" test_path_invalid_too_long

echo ""
echo "Testing validate_ip_range..."
run_test "  valid: Class C network" test_ip_range_valid_class_c
run_test "  valid: Class B network" test_ip_range_valid_class_b
run_test "  valid: Class A network" test_ip_range_valid_class_a
run_test "  valid: single host" test_ip_range_valid_single_host
run_test "  invalid: no CIDR" test_ip_range_invalid_no_cidr
run_test "  invalid: text" test_ip_range_invalid_text
run_test "  invalid: empty" test_ip_range_invalid_empty
run_test "  invalid: incomplete" test_ip_range_invalid_incomplete

echo ""
echo "Testing validate_number..."
run_test "  valid: simple number" test_number_valid_simple
run_test "  valid: zero" test_number_valid_zero
run_test "  valid: large number" test_number_valid_large
run_test "  valid: min bound" test_number_valid_min_bound
run_test "  valid: max bound" test_number_valid_max_bound
run_test "  valid: within range" test_number_valid_within_range
run_test "  invalid: text" test_number_invalid_text
run_test "  invalid: negative" test_number_invalid_negative
run_test "  invalid: decimal" test_number_invalid_decimal
run_test "  invalid: below min" test_number_invalid_below_min
run_test "  invalid: above max" test_number_invalid_above_max
run_test "  invalid: empty" test_number_invalid_empty

echo ""
echo "Testing validate_identifier..."
run_test "  valid: alphanumeric" test_identifier_valid_alphanumeric
run_test "  valid: with dash" test_identifier_valid_with_dash
run_test "  valid: with underscore" test_identifier_valid_with_underscore
run_test "  valid: mixed" test_identifier_valid_mixed
run_test "  invalid: space" test_identifier_invalid_space
run_test "  invalid: period" test_identifier_invalid_period
run_test "  invalid: special chars" test_identifier_invalid_special_chars
run_test "  invalid: empty" test_identifier_invalid_empty
run_test "  invalid: too long" test_identifier_invalid_too_long

echo ""
echo "Testing validate_bitrate..."
run_test "  valid: numeric only" test_bitrate_valid_numeric
run_test "  valid: with lowercase k" test_bitrate_valid_with_k
run_test "  valid: with uppercase K" test_bitrate_valid_with_K
run_test "  valid: zero" test_bitrate_valid_zero
run_test "  invalid: text" test_bitrate_invalid_text
run_test "  invalid: decimal" test_bitrate_invalid_decimal
run_test "  invalid: space" test_bitrate_invalid_space
run_test "  invalid: wrong suffix" test_bitrate_invalid_wrong_suffix
run_test "  invalid: empty" test_bitrate_invalid_empty

echo ""
echo "Testing validate_log_level..."
run_test "  valid: debug" test_log_level_valid_debug
run_test "  valid: info" test_log_level_valid_info
run_test "  valid: notice" test_log_level_valid_notice
run_test "  valid: warn" test_log_level_valid_warn
run_test "  valid: error" test_log_level_valid_error
run_test "  valid: crit" test_log_level_valid_crit
run_test "  valid: alert" test_log_level_valid_alert
run_test "  valid: emerg" test_log_level_valid_emerg
run_test "  invalid: unknown" test_log_level_invalid_unknown
run_test "  invalid: uppercase" test_log_level_invalid_uppercase
run_test "  invalid: empty" test_log_level_invalid_empty

echo ""
echo "Testing validate_suffix..."
run_test "  valid: mp4" test_suffix_valid_mp4
run_test "  valid: flv" test_suffix_valid_flv
run_test "  valid: mkv" test_suffix_valid_mkv
run_test "  valid: uppercase" test_suffix_valid_uppercase
run_test "  invalid: with dot" test_suffix_invalid_with_dot
run_test "  invalid: with slash" test_suffix_invalid_with_slash
run_test "  invalid: special chars" test_suffix_invalid_special_chars
run_test "  invalid: empty" test_suffix_invalid_empty
run_test "  invalid: too long" test_suffix_invalid_too_long

echo ""
echo "Testing escape_for_sed..."
run_test "  simple text" test_escape_for_sed_simple
run_test "  with pipes" test_escape_for_sed_with_pipe
run_test "  with ampersand" test_escape_for_sed_with_ampersand
run_test "  with backslash" test_escape_for_sed_with_backslash
run_test "  mixed special chars" test_escape_for_sed_mixed

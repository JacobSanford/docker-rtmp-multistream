#!/usr/bin/env sh
# Input validation helper for pre-init scripts
# Prevents configuration injection attacks via environment variables

# Validate stream key format (alphanumeric, dashes, underscores, periods)
# Stream keys should not contain special characters that could break configs
validate_stream_key() {
  local key="$1"
  local name="$2"

  if [ -z "$key" ]; then
    return 0  # Empty is OK - service will be skipped
  fi

  # Check for dangerous characters that could be used for injection
  # Allow: alphanumeric, dash, underscore, period, colon (for some keys)
  if echo "$key" | grep -qE '[^a-zA-Z0-9._:-]'; then
    echo "ERROR: $name contains invalid characters. Only alphanumeric, dash, underscore, period, and colon are allowed."
    return 1
  fi

  # Check for path traversal attempts
  if echo "$key" | grep -qE '\.\./'; then
    echo "ERROR: $name contains path traversal sequence."
    return 1
  fi

  # Check for newlines or null bytes (config injection)
  # Count lines - if more than 1, contains newline
  local line_count=$(printf '%s' "$key" | wc -l)
  if [ "$line_count" -gt 0 ]; then
    echo "ERROR: $name contains newline or null byte."
    return 1
  fi

  # Reasonable length check (stream keys typically < 100 chars)
  if [ ${#key} -gt 200 ]; then
    echo "ERROR: $name is too long (max 200 characters)."
    return 1
  fi

  return 0
}

# Validate file path (no injection, must be absolute)
validate_path() {
  local path="$1"
  local name="$2"

  if [ -z "$path" ]; then
    return 0  # Empty is OK - feature will be skipped
  fi

  # Must be absolute path
  if ! echo "$path" | grep -qE '^/'; then
    echo "ERROR: $name must be an absolute path starting with /."
    return 1
  fi

  # Check for dangerous characters (check each separately for reliability)
  if echo "$path" | grep -qF ';'; then
    echo "ERROR: $name contains invalid shell metacharacters."
    return 1
  fi
  if echo "$path" | grep -qF '|'; then
    echo "ERROR: $name contains invalid shell metacharacters."
    return 1
  fi
  if echo "$path" | grep -qF '&'; then
    echo "ERROR: $name contains invalid shell metacharacters."
    return 1
  fi
  if echo "$path" | grep -qF '$'; then
    echo "ERROR: $name contains invalid shell metacharacters."
    return 1
  fi
  if echo "$path" | grep -qF '`'; then
    echo "ERROR: $name contains invalid shell metacharacters."
    return 1
  fi
  if echo "$path" | grep -qE '[()\{\}<>]'; then
    echo "ERROR: $name contains invalid shell metacharacters."
    return 1
  fi

  # Check for newlines or null bytes
  local line_count=$(printf '%s' "$path" | wc -l)
  if [ "$line_count" -gt 0 ]; then
    echo "ERROR: $name contains newline or null byte."
    return 1
  fi

  # Reasonable length check
  if [ ${#path} -gt 500 ]; then
    echo "ERROR: $name is too long (max 500 characters)."
    return 1
  fi

  return 0
}

# Validate IP range (CIDR notation)
validate_ip_range() {
  local range="$1"
  local name="$2"

  if [ -z "$range" ]; then
    echo "ERROR: $name cannot be empty."
    return 1
  fi

  # Check for basic CIDR format (simple validation)
  # Format: x.x.x.x/y where x is 0-255 and y is 0-32
  if ! echo "$range" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$'; then
    echo "ERROR: $name is not a valid CIDR notation (e.g., 192.168.0.0/16)."
    return 1
  fi

  return 0
}

# Validate numeric value with range
validate_number() {
  local value="$1"
  local name="$2"
  local min="$3"
  local max="$4"

  if [ -z "$value" ]; then
    echo "ERROR: $name cannot be empty."
    return 1
  fi

  # Check if numeric
  if ! echo "$value" | grep -qE '^[0-9]+$'; then
    echo "ERROR: $name must be a number."
    return 1
  fi

  # Check range if provided
  if [ -n "$min" ] && [ "$value" -lt "$min" ]; then
    echo "ERROR: $name must be >= $min."
    return 1
  fi

  if [ -n "$max" ] && [ "$value" -gt "$max" ]; then
    echo "ERROR: $name must be <= $max."
    return 1
  fi

  return 0
}

# Validate alphanumeric identifier (presets, codecs, etc)
validate_identifier() {
  local value="$1"
  local name="$2"

  if [ -z "$value" ]; then
    echo "ERROR: $name cannot be empty."
    return 1
  fi

  # Allow: alphanumeric, dash, underscore only
  if ! echo "$value" | grep -qE '^[a-zA-Z0-9_-]+$'; then
    echo "ERROR: $name contains invalid characters. Only alphanumeric, dash, and underscore allowed."
    return 1
  fi

  if [ ${#value} -gt 100 ]; then
    echo "ERROR: $name is too long (max 100 characters)."
    return 1
  fi

  return 0
}

# Validate bitrate (e.g., "160k", "128000")
validate_bitrate() {
  local value="$1"
  local name="$2"

  if [ -z "$value" ]; then
    echo "ERROR: $name cannot be empty."
    return 1
  fi

  # Allow: digits optionally followed by 'k' or 'K'
  if ! echo "$value" | grep -qE '^[0-9]+[kK]?$'; then
    echo "ERROR: $name must be numeric or numeric with 'k' suffix (e.g., 160k)."
    return 1
  fi

  return 0
}

# Validate log level
validate_log_level() {
  local level="$1"
  local name="$2"

  if [ -z "$level" ]; then
    echo "ERROR: $name cannot be empty."
    return 1
  fi

  # Valid nginx log levels
  case "$level" in
    debug|info|notice|warn|error|crit|alert|emerg)
      return 0
      ;;
    *)
      echo "ERROR: $name must be one of: debug, info, notice, warn, error, crit, alert, emerg."
      return 1
      ;;
  esac
}

# Validate file suffix (extension)
validate_suffix() {
  local suffix="$1"
  local name="$2"

  if [ -z "$suffix" ]; then
    echo "ERROR: $name cannot be empty."
    return 1
  fi

  # Allow: alphanumeric only (no dots, no paths)
  if ! echo "$suffix" | grep -qE '^[a-zA-Z0-9]+$'; then
    echo "ERROR: $name must be alphanumeric only (e.g., mp4, flv, mkv)."
    return 1
  fi

  if [ ${#suffix} -gt 10 ]; then
    echo "ERROR: $name is too long (max 10 characters)."
    return 1
  fi

  return 0
}

# Escape value for safe sed substitution
# Escapes: / | & \ (sed delimiters and special chars)
escape_for_sed() {
  local value="$1"
  # Use | as sed delimiter instead of / to avoid issues with paths
  # Just need to escape | & and \
  echo "$value" | sed -e 's/\\/\\\\/g' -e 's/|/\\|/g' -e 's/&/\\&/g'
}

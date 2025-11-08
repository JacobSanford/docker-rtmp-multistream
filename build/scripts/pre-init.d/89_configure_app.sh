#!/usr/bin/env sh
set -e

# Source validation functions
. /scripts/validate_input.sh

# Validate inputs
validate_ip_ranges "$PUBLISH_IP_RANGE" "PUBLISH_IP_RANGE" || exit 1
validate_log_level "$NGINX_ERROR_LOG_LEVEL" "NGINX_ERROR_LOG_LEVEL" || exit 1

sed -i "s|NGINX_CONFD_DIR|$NGINX_CONFD_DIR|g" "${NGINX_APP_CONF_FILE}"
sed -i "s|NGINX_ERROR_LOG_LEVEL|$NGINX_ERROR_LOG_LEVEL|g" "${NGINX_APP_CONF_FILE}"

# Generate multiple allow publish lines from comma-separated ranges
allow_lines=""
old_IFS="$IFS"
IFS=','
for range in $PUBLISH_IP_RANGE; do
  # Trim whitespace
  range=$(echo "$range" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  # Add allow line
  allow_lines="${allow_lines}allow publish ${range};\n"
done
IFS="$old_IFS"

# Remove trailing newline
allow_lines=$(printf '%s' "$allow_lines")

# Replace placeholder with multiple lines using awk
awk -v lines="$allow_lines" '
  /allow publish PUBLISH_IP_RANGE;/ {
    printf "%s\n", lines
    next
  }
  { print }
' "${NGINX_CONFD_DIR}/auth.conf" > "${NGINX_CONFD_DIR}/auth.conf.tmp"
mv "${NGINX_CONFD_DIR}/auth.conf.tmp" "${NGINX_CONFD_DIR}/auth.conf"

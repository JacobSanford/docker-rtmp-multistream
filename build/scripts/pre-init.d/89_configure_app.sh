#!/usr/bin/env sh
set -e

# Source validation functions
. /scripts/validate_input.sh

# Validate inputs
validate_ip_range "$PUBLISH_IP_RANGE" "PUBLISH_IP_RANGE" || exit 1
validate_log_level "$NGINX_ERROR_LOG_LEVEL" "NGINX_ERROR_LOG_LEVEL" || exit 1

sed -i "s|NGINX_CONFD_DIR|$NGINX_CONFD_DIR|g" "${NGINX_APP_CONF_FILE}"
sed -i "s|NGINX_ERROR_LOG_LEVEL|$NGINX_ERROR_LOG_LEVEL|g" "${NGINX_APP_CONF_FILE}"
sed -i "s|PUBLISH_IP_RANGE|$PUBLISH_IP_RANGE|g" "${NGINX_CONFD_DIR}/auth.conf"

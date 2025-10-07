#!/usr/bin/env sh
set -e

# Source validation functions
. /scripts/validate_input.sh

if [ -z "$ARCHIVE_PATH" ]; then
  echo "ARCHIVE_PATH is not set. Skipping Archive configuration."
  exit 0
fi

# Validate inputs
validate_path "$ARCHIVE_PATH" "ARCHIVE_PATH" || exit 1
validate_suffix "$ARCHIVE_SUFFIX" "ARCHIVE_SUFFIX" || exit 1

if ! sudo -u $NGINX_RUN_USER test -w "$ARCHIVE_PATH"; then
  echo "The archive path is not writable by the nginx user. Skipping Archive configuration."
  exit 0
fi

# Escape values for safe sed substitution
ARCHIVE_PATH_ESC=$(escape_for_sed "$ARCHIVE_PATH")

sed -i "/record off/d" ${NGINX_APP_CONF_FILE}
sed -i "s|ARCHIVE_PATH|$ARCHIVE_PATH_ESC|g" "${NGINX_CONFD_DIR}/apps/archive.conf"
sed -i "s|ARCHIVE_SUFFIX|$ARCHIVE_SUFFIX|g" "${NGINX_CONFD_DIR}/apps/archive.conf"

/scripts/enableService.sh archive

echo "Archive configuration complete, and service enabled."

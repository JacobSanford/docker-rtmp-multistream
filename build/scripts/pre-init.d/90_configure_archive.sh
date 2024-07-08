#!/usr/bin/env sh
if [ -z "$ARCHIVE_PATH" ]; then
  echo "ARCHIVE_PATH is not set. Skipping Archive configuration."
  exit 0
fi

if ! sudo -u $NGINX_RUN_USER test -w "$ARCHIVE_PATH"; then
  echo "The archive path is not writable by the nginx user. Skipping Archive configuration."
  exit 0
fi

sed -i "/record off/d" ${NGINX_APP_CONF_FILE}
sed -i "s|ARCHIVE_PATH|$ARCHIVE_PATH|g" "${NGINX_CONFD_DIR}/apps/archive.conf"
sed -i "s|ARCHIVE_SUFFIX|$ARCHIVE_SUFFIX|g" "${NGINX_CONFD_DIR}/apps/archive.conf"

/scripts/enableService.sh archive

echo "Archive configuration complete, and service enabled."

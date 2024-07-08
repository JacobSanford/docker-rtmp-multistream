#!/usr/bin/env sh
if [ -z "$YOUTUBE_KEY" ]; then
  echo "YOUTUBE_KEY is not set. Skipping YouTube configuration."
  exit 0
fi

sed -i "s|YOUTUBE_KEY|$YOUTUBE_KEY|g" "${NGINX_CONFD_DIR}/apps/youtube.conf"

/scripts/enableService.sh youtube

echo "Youtube configuration complete, and service enabled."

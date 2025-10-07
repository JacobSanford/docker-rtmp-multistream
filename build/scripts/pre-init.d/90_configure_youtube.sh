#!/usr/bin/env sh
set -e

# Source validation functions
. /scripts/validate_input.sh

if [ -z "$YOUTUBE_KEY" ]; then
  echo "YOUTUBE_KEY is not set. Skipping YouTube configuration."
  exit 0
fi

# Validate inputs
validate_stream_key "$YOUTUBE_KEY" "YOUTUBE_KEY" || exit 1

# Escape values for safe sed substitution
YOUTUBE_KEY_ESC=$(escape_for_sed "$YOUTUBE_KEY")

sed -i "s|YOUTUBE_KEY|$YOUTUBE_KEY_ESC|g" "${NGINX_CONFD_DIR}/apps/youtube.conf"

/scripts/enableService.sh youtube

echo "Youtube configuration complete, and service enabled."

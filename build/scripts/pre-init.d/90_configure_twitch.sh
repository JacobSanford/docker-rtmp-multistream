#!/usr/bin/env sh
if [ -z "$TWITCH_KEY" ]; then
  echo "TWITCH_KEY is not set. Skipping Twitch configuration."
  exit 0
fi

TWITCH_DOUBLE_FPS=$(( TWITCH_FPS * 2 ))
TWITCH_VIDEO_BITRATE=$(( TWITCH_KBITS_PER_VIDEO_FRAME * TWITCH_FPS ))

# Encoder Settings
sed -i "s|TWITCH_AUDIO_BITRATE|$TWITCH_AUDIO_BITRATE|g" "${NGINX_CONFD_DIR}/transformers/twitch.conf"
sed -i "s|TWITCH_CODEC|$TWITCH_CODEC|g" "${NGINX_CONFD_DIR}/transformers/twitch.conf"
sed -i "s|TWITCH_DOUBLE_FPS|$TWITCH_DOUBLE_FPS|g" "${NGINX_CONFD_DIR}/transformers/twitch.conf"
sed -i "s|TWITCH_FFMPEG_THREADS|$TWITCH_FFMPEG_THREADS|g" "${NGINX_CONFD_DIR}/transformers/twitch.conf"
sed -i "s|TWITCH_FPS|$TWITCH_FPS|g" "${NGINX_CONFD_DIR}/transformers/twitch.conf"
sed -i "s|TWITCH_HEIGHT|$TWITCH_HEIGHT|g" "${NGINX_CONFD_DIR}/transformers/twitch.conf"
sed -i "s|TWITCH_VIDEO_BITRATE|$TWITCH_VIDEO_BITRATE|g" "${NGINX_CONFD_DIR}/transformers/twitch.conf"
sed -i "s|TWITCH_X264_PRESET|$TWITCH_X264_PRESET|g" "${NGINX_CONFD_DIR}/transformers/twitch.conf"

# App
sed -i "s|TWITCH_KEY|$TWITCH_KEY|g" "${NGINX_CONFD_DIR}/apps/twitch.conf"
sed -i "s|TWITCH_ENDPOINT|$TWITCH_ENDPOINT|g" "${NGINX_CONFD_DIR}/apps/twitch.conf"

/scripts/enableService.sh twitch
echo "Twitch configuration complete, and service enabled."

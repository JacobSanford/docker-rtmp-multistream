#!/usr/bin/env sh
set -e

# Source validation functions
. /scripts/validate_input.sh

if [ -z "$TWITCH_KEY" ]; then
  echo "TWITCH_KEY is not set. Skipping Twitch configuration."
  exit 0
fi

# Validate stream key (required for both modes)
validate_stream_key "$TWITCH_KEY" "TWITCH_KEY" || exit 1

# Validate TWITCH_PARTNER boolean
validate_boolean "$TWITCH_PARTNER" "TWITCH_PARTNER" || exit 1

# Normalize TWITCH_PARTNER to uppercase for consistent comparison
TWITCH_PARTNER_UPPER=$(echo "$TWITCH_PARTNER" | tr '[:lower:]' '[:upper:]')

# Validate endpoint (required for both modes)
validate_identifier "$TWITCH_ENDPOINT" "TWITCH_ENDPOINT" || exit 1

# Escape values for safe sed substitution
TWITCH_KEY_ESC=$(escape_for_sed "$TWITCH_KEY")
TWITCH_ENDPOINT_ESC=$(escape_for_sed "$TWITCH_ENDPOINT")

if [ "$TWITCH_PARTNER_UPPER" = "TRUE" ]; then
  # Partner Mode: Simple Relay Pattern
  echo "Configuring Twitch in Partner mode (Simple Relay)..."

  # Configure partner app (direct push, no transcoding)
  sed -i "s|TWITCH_KEY|$TWITCH_KEY_ESC|g" "${NGINX_CONFD_DIR}/apps/twitch-partner.conf"
  sed -i "s|TWITCH_ENDPOINT|$TWITCH_ENDPOINT_ESC|g" "${NGINX_CONFD_DIR}/apps/twitch-partner.conf"

  # Enable partner service
  /scripts/enableService.sh twitch-partner
  echo "Twitch Partner configuration complete, and service enabled."

else
  # Non-Partner Mode: Transformer Pattern (default)
  echo "Configuring Twitch in Non-Partner mode (Transformer)..."

  # Validate transformer-specific inputs
  validate_number "$TWITCH_FPS" "TWITCH_FPS" 1 120 || exit 1
  validate_number "$TWITCH_HEIGHT" "TWITCH_HEIGHT" 144 4320 || exit 1
  validate_number "$TWITCH_KBITS_PER_VIDEO_FRAME" "TWITCH_KBITS_PER_VIDEO_FRAME" 1 1000 || exit 1
  validate_number "$TWITCH_FFMPEG_THREADS" "TWITCH_FFMPEG_THREADS" 0 64 || exit 1
  validate_bitrate "$TWITCH_AUDIO_BITRATE" "TWITCH_AUDIO_BITRATE" || exit 1
  validate_identifier "$TWITCH_CODEC" "TWITCH_CODEC" || exit 1
  validate_identifier "$TWITCH_X264_PRESET" "TWITCH_X264_PRESET" || exit 1

  # Calculate derived values
  TWITCH_DOUBLE_FPS=$(( TWITCH_FPS * 2 ))
  TWITCH_VIDEO_BITRATE=$(( TWITCH_KBITS_PER_VIDEO_FRAME * TWITCH_FPS ))

  # Configure transformer (FFmpeg encoder settings)
  sed -i "s|TWITCH_AUDIO_BITRATE|$TWITCH_AUDIO_BITRATE|g" "${NGINX_CONFD_DIR}/transformers/twitch.conf"
  sed -i "s|TWITCH_CODEC|$TWITCH_CODEC|g" "${NGINX_CONFD_DIR}/transformers/twitch.conf"
  sed -i "s|TWITCH_DOUBLE_FPS|$TWITCH_DOUBLE_FPS|g" "${NGINX_CONFD_DIR}/transformers/twitch.conf"
  sed -i "s|TWITCH_FFMPEG_THREADS|$TWITCH_FFMPEG_THREADS|g" "${NGINX_CONFD_DIR}/transformers/twitch.conf"
  sed -i "s|TWITCH_FPS|$TWITCH_FPS|g" "${NGINX_CONFD_DIR}/transformers/twitch.conf"
  sed -i "s|TWITCH_HEIGHT|$TWITCH_HEIGHT|g" "${NGINX_CONFD_DIR}/transformers/twitch.conf"
  sed -i "s|TWITCH_VIDEO_BITRATE|$TWITCH_VIDEO_BITRATE|g" "${NGINX_CONFD_DIR}/transformers/twitch.conf"
  sed -i "s|TWITCH_X264_PRESET|$TWITCH_X264_PRESET|g" "${NGINX_CONFD_DIR}/transformers/twitch.conf"

  # Configure app (destination for transcoded stream)
  sed -i "s|TWITCH_KEY|$TWITCH_KEY_ESC|g" "${NGINX_CONFD_DIR}/apps/twitch.conf"
  sed -i "s|TWITCH_ENDPOINT|$TWITCH_ENDPOINT_ESC|g" "${NGINX_CONFD_DIR}/apps/twitch.conf"

  # Enable non-partner service (transformer + app)
  /scripts/enableService.sh twitch
  echo "Twitch Non-Partner configuration complete, and service enabled."

fi

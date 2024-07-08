#!/usr/bin/env sh
SERVICE=$1
SERVICE_TRANSFORMER_FILE="$NGINX_CONFD_DIR/transformers/$SERVICE.conf"
SERVICE_APP_FILE="$NGINX_CONFD_DIR/apps/$SERVICE.conf"

if [ -z "$SERVICE" ]; then
  echo "No service specified. Skipping service enabling."
  exit 0
fi

if [ ! -f "$SERVICE_APP_FILE" ]; then
  echo "Service app definition file (SERVICE_APP_FILE) not found. Skipping service enabling."
  exit 0
fi

sed -i "s|\#include $SERVICE_APP_FILE|include $SERVICE_APP_FILE|g" "$NGINX_APP_CONF_FILE"

if [ -f "$SERVICE_TRANSFORMER_FILE" ]; then
  sed -i "s|\#include $SERVICE_TRANSFORMER_FILE|include $SERVICE_TRANSFORMER_FILE|g" "$NGINX_APP_CONF_FILE"
fi

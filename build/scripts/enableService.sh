#!/usr/bin/env sh
# Uncomment a service's include lines in app.conf. Exits 1 when the service
# cannot be enabled, so the calling pre-init script stops the container
# instead of reporting a service that never runs.
SERVICE=$1
SERVICE_TRANSFORMER_FILE="$NGINX_CONFD_DIR/transformers/$SERVICE.conf"
SERVICE_APP_FILE="$NGINX_CONFD_DIR/apps/$SERVICE.conf"

if [ -z "$SERVICE" ]; then
  echo "ERROR: enableService.sh needs a service name."
  exit 1
fi

if [ ! -f "$SERVICE_APP_FILE" ]; then
  echo "ERROR: $SERVICE_APP_FILE not found. Cannot enable $SERVICE."
  exit 1
fi

# Enable one include line, and fail if app.conf has no active line for it
# afterwards (for example '# include' with a space, which the sed never matches)
enable_include() {
  sed -i "s|\#include $1;|include $1;|g" "$NGINX_APP_CONF_FILE"
  if ! grep -qE "^[[:space:]]*include $1;" "$NGINX_APP_CONF_FILE"; then
    echo "ERROR: No '#include $1;' line in $NGINX_APP_CONF_FILE. Cannot enable $SERVICE."
    exit 1
  fi
}

enable_include "$SERVICE_APP_FILE"

if [ -f "$SERVICE_TRANSFORMER_FILE" ]; then
  enable_include "$SERVICE_TRANSFORMER_FILE"
fi

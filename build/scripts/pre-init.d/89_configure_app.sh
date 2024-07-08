#!/usr/bin/env sh
sed -i "s|NGINX_CONFD_DIR|$NGINX_CONFD_DIR|g" "${NGINX_APP_CONF_FILE}"
sed -i "s|PUBLISH_IP_RANGE|$PUBLISH_IP_RANGE|g" "${NGINX_CONFD_DIR}/auth.conf"

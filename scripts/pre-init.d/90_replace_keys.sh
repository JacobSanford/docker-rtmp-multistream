#!/usr/bin/env sh
sed -i "s|YOUTUBE_KEY|$YOUTUBE_KEY|g" ${NGINX_CONF}
sed -i "s|TWITCH_KEY|$TWITCH_KEY|g" ${NGINX_CONF}

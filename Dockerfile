FROM ghcr.io/unb-libraries/nginx:1.x
MAINTAINER UNB Libraries <libsupport@unb.ca>

ENV NGINX_CONF /etc/nginx/conf.d/app.conf
ENV YOUTUBE_KEY keyhere
ENV TWITCH_KEY keyhere

COPY ./conf /conf
COPY ./scripts /scripts

RUN apk --no-cache add nginx-mod-rtmp && \
  cp /conf/nginx/app.conf ${NGINX_CONF} && \
  cp /conf/nginx/nginx.conf /etc/nginx/nginx.conf && \
  chmod -R 755 /scripts

EXPOSE 1935

FROM ghcr.io/unb-libraries/nginx:3.18.x

ENV TWITCH_AUDIO_BITRATE=160k
ENV TWITCH_CODEC=libx264
ENV TWITCH_FPS=60
ENV TWITCH_HEIGHT=720
ENV TWITCH_KBITS_PER_VIDEO_FRAME=67
ENV TWITCH_KEY=keyhere
ENV TWITCH_X264_PRESET=medium
ENV YOUTUBE_KEY=keyhere

COPY build /build

RUN apk --no-cache add nginx-mod-rtmp ffmpeg && \
  $RSYNC_COPY /build/scripts/ /scripts/ && \
  $RSYNC_COPY /build/conf/nginx/nginx.conf "$NGINX_CONF_FILE" && \
  $RSYNC_COPY /build/conf/nginx/app.conf "$NGINX_APP_CONF_FILE"

EXPOSE 1935

LABEL ca.unb.lib.generator="nginx" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.description="A lightweight docker-based nginx based RTMP relay/encoder for streaming simultaneously to Youtube, Twitch, and other services." \
  org.label-schema.name="rtmp-multistream" \
  org.label-schema.url="https://github.com/jacobsanford/docker-rtmp-multistream" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/jacobsanford/docker-rtmp-multistream" \
  org.label-schema.version=$VERSION \
  org.opencontainers.image.authors="jsanford@unb.ca" \
  org.opencontainers.image.source="https://github.com/jacobsanford/docker-rtmp-multistream"

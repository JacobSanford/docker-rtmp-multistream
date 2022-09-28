FROM ghcr.io/unb-libraries/nginx:3.x
MAINTAINER Jacob Sanford <jsanford@unb.ca>

ENV TWITCH_AUDIO_BITRATE 160k
ENV TWITCH_CODEC libx264
ENV TWITCH_FPS 60
ENV TWITCH_HEIGHT 720
ENV TWITCH_KBITS_PER_VIDEO_FRAME 67
ENV TWITCH_KEY keyhere
ENV TWITCH_X264_PRESET medium
ENV YOUTUBE_KEY keyhere

COPY build /build

RUN apk --no-cache add nginx-mod-rtmp ffmpeg && \
  $RSYNC_COPY /build/conf/nginx/nginx.conf "$NGINX_CONF_FILE" && \
  $RSYNC_COPY /build/conf/nginx/app.conf "$NGINX_APP_CONF_FILE"

EXPOSE 1935

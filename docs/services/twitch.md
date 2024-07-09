# Service: Twitch
## Description
The relay can stream to Twitch. To enable this feature, set the `TWITCH_KEY` environment variable in the `env/relay.env` file to the stream key provided by Twitch.

## Configuration
The Twitch service can be configured by setting the following environment variables:
| Variable | Description | Default |
|----------|-------------|---------|
| `TWITCH_KEY` | The stream key provided by Twitch. | `` |
| `TWITCH_AUDIO_BITRATE` | The audio bitrate for the stream. 160k is the Maximum audio bit rate supported by Twitch. | `160k` |
| `TWITCH_CODEC` | The codec to use for the stream. This is unlikely to change. | `libx264` |
| `TWITCH_ENDPOINT` | The Twitch ingest server slug to use. See the [Recommended Ingest Endpoints](https://help.twitch.tv/s/twitch-ingest-recommendation?language=en_US) document to determine which is best for you. | `jfk` |
| `TWITCH_FFMPEG_THREADS` | The number of CPU threads to use for encoding. Consider changing this if you are relaying to multiple endpoints to ensure equal access to the processor. The default setting of `0` instructs ffmpeg to optimize use. | `0` |
| `TWITCH_FPS` | The frames per second for the stream. | `60` |
| `TWITCH_HEIGHT` | The height of the video stream in pixels. | `720` |
| `TWITCH_KBITS_PER_VIDEO_FRAME` | The number of kilobits per video frame. Change this to control the bitrate of the video stream. See `TWITCH_KBITS_PER_VIDEO_FRAME` below. | `75` |
| `TWITCH_X264_PRESET` | The x264 preset to use for encoding. A list of options is available [in the x264 documentation](https://trac.ffmpeg.org/wiki/Encode/H.264). 'Slower' presets increase computational costs but typically provide higher quality output at the same bitrate. Slower than `medium` generally offers rapidly diminishing returns. | `medium` |

## Stream Quality
As with all services, the quality of the Twitch stream is determined by the bitrate of the video and audio streams. Please see the [Performance and Quality](../quality.md) document for a detailed discussion.

The Twitch relay re-encodes the stream from the original RTMP stream using `ffmpeg`. This is based on this software's original use case: a high stream quality from the streaming software which is then re-encoded multiple times to fit guidelines for multiple services.

As a result: if your streaming software is configured to encode at a lower bitrate than the Twitch relay, the relay will re-encode the stream at a higher bitrate, which can negatively affect quality.

### Twitch's x264 Guidelines
Twitch provides a [guide](https://help.twitch.tv/s/article/broadcasting-guidelines?language=en_US) on encoding settings for streaming to its platform. In the guide, they recommend a maximum video bitrate of `6000 kbps`, even when streaming 1080p/60fps.

Another important fact to consider is that [Twitch does not reliably transcode streams for non-partners](https://help.twitch.tv/s/article/transcoding-options-faq?language=en_US). **This means that for non-partners, viewers may only be able to watch your stream at the quality you transmit**. If you transmit a high-bandwidth stream, viewers with slower internet connections may not be able to watch.

## General Recommendations
See the [Performance and Quality](../quality.md) document for a detailed discussion on how to determine the quality of your stream.

### TWITCH_KBITS_PER_VIDEO_FRAME
For 1080p streams, you should begin with a value of `100` for `TWITCH_KBITS_PER_VIDEO_FRAME`, and 720p streams should default to using `75`.

This is a reasonable starting point for most streams. If your stream is pixelated or blurry, you may need to increase this value. If you are dropping frames, you may need to decrease this value.

Based on these values, the following table provides a starting point for determining the bandwidth required for different resolutions and frame rates:

| Resoluion      | FPS     | Video Bitrate        |  TWITCH_KBITS_PER_VIDEO_FRAME |
|----------------|---------|----------------------|-------------------------------|
| 1920x1080      | 60      | 6000 Kbps            | `100`                           |
| 1920x1080      | 50      | 5000 Kbps            | `100`                           |
| 1920x1080      | 30      | 3000 Kbps            | `100`                           |
| 1920x1080      | 25      | 2500 Kbps            | `100`                           |
| 1280x720       | 60      | 4500 Kbps            | `75`                            |
| 1280x720       | 50      | 3750 Kbps            | `75`                            |
| 1280x720       | 30      | 2250 Kbps            | `75`                            |
| 1280x720       | 25      | 1875 Kbps            | `75`                            |

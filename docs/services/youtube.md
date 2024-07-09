# Service: YouTube
## Description
The relay can stream to YouTube. To enable this feature, set the `YOUTUBE_KEY` environment variable in the `env/relay.env` file to the stream key provided by YouTube.

## Configuration
The YouTube service can be configured by setting the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `YOUTUBE_KEY` | The stream key provided by YouTube. | `` |

## Stream Quality
As with all services, the quality of the YouTube stream is determined by the bitrate of the video and audio streams. Please see the [Performance and Quality](../quality.md) document for a detailed discussion.

YouTube reprocesses every video it receives, including live streams. Consequently, streams that appear fine at lower bitrates on other platforms (such as Twitch) will appear distorted on YouTube after the stream is re-encoded. Therefore, the relay directly relays the stream from the original RTMP source to YouTube. 

## General Recommendations
See the [Performance and Quality](../quality.md) document for a detailed discussion on how to determine the quality of your stream.


# YouTube

## Overview

The relay can stream to YouTube using direct pass-through. To enable this feature, set the `YOUTUBE_KEY` environment variable in the `env/relay.env` file to the stream key provided by YouTube.

The YouTube relay uses a **simple relay pattern** - it forwards your stream directly to YouTube without any re-encoding or modification. This preserves your original stream quality for YouTube's reprocessing.

## Configuration

The YouTube service can be configured by setting the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `YOUTUBE_KEY` | The stream key provided by YouTube. | `` |

## Why Direct Pass-Through?

YouTube reprocesses every video it receives, including live streams. This means YouTube applies its own encoding to your stream after receiving it.

Streams that appear acceptable at lower bitrates on platforms like Twitch will often appear distorted on YouTube after YouTube's re-encoding process. To maintain quality, the relay passes your original high-quality stream directly to YouTube without intermediate transcoding.

!!! tip "Optimize Your Source"
    Since the relay passes your stream through unchanged, ensure your streaming software (OBS, etc.) is configured with high-quality settings suitable for YouTube. See the [Quality & Performance Guide](../quality.md) for recommendations.

## Quality Settings

Since YouTube doesn't modify the stream, quality is determined entirely by your streaming software configuration and available bandwidth.

Refer to the [Quality & Performance Guide](../quality.md) for:
- Bitrate recommendations
- Resolution and framerate considerations
- Bandwidth requirements

## See Also

- [Quality & Performance Guide](../quality.md) - Stream quality and bandwidth guidance
- [Architecture](../architecture.md) - Learn about relay patterns
- [Quick Start Guide](../quickstart.md) - Initial setup instructions

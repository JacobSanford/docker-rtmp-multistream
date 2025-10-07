# Environment Variables Reference

Complete reference for all environment variables used in docker-rtmp-multistream.

## System Variables

### PUBLISH_IP_RANGE

**Description**: IP address range allowed to publish streams to the relay. Uses CIDR notation.

**Type**: String (CIDR notation)

**Default**: `192.168.0.0/16`

**Used by**: Authentication system (`auth.conf`)

**Examples**:
```bash
PUBLISH_IP_RANGE=192.168.0.0/16   # Entire local network
PUBLISH_IP_RANGE=192.168.1.0/24   # Specific subnet
PUBLISH_IP_RANGE=192.168.1.50/32  # Single IP address
```

**See also**: [Configuration Overview](../configuration.md#ip-based-access-control)

---

## Twitch Variables

### TWITCH_KEY

**Description**: Stream key provided by Twitch. Setting this variable enables the Twitch service.

**Type**: String

**Default**: `""` (empty, service disabled)

**Required**: Yes (to enable Twitch)

**Used by**: Twitch application config

**Example**:
```bash
TWITCH_KEY=live_123456789_abcdefghijklmnopqrstuvwxyz
```

**See also**: [Twitch Configuration](../services/twitch.md)

### TWITCH_AUDIO_BITRATE

**Description**: Audio bitrate for the Twitch stream. 160k is the maximum supported by Twitch.

**Type**: String (with 'k' suffix)

**Default**: `160k`

**Required**: No

**Used by**: Twitch transformer

**Examples**:
```bash
TWITCH_AUDIO_BITRATE=160k  # Maximum quality
TWITCH_AUDIO_BITRATE=128k  # Good quality
```

### TWITCH_CODEC

**Description**: Video codec for Twitch encoding. Typically shouldn't be changed.

**Type**: String

**Default**: `libx264`

**Required**: No

**Used by**: Twitch transformer

**Possible values**: `libx264`, `libx264rgb`, other FFmpeg-supported codecs

### TWITCH_ENDPOINT

**Description**: Twitch ingest server identifier. Choose the server closest to your location.

**Type**: String (server code)

**Default**: `jfk` (New York)

**Required**: No

**Used by**: Twitch application config

**Common values**:
- `jfk` - New York, NY
- `lax` - Los Angeles, CA
- `dfw` - Dallas, TX
- `ord` - Chicago, IL
- `sea` - Seattle, WA
- `iad` - Ashburn, VA
- `fra` - Frankfurt, Germany
- `lhr` - London, UK
- `syd` - Sydney, Australia
- `sin` - Singapore
- `gru` - São Paulo, Brazil

**See also**: [Twitch Ingest Endpoints](https://help.twitch.tv/s/twitch-ingest-recommendation?language=en_US)

### TWITCH_FFMPEG_THREADS

**Description**: Number of CPU threads for FFmpeg encoding. `0` means auto-optimize.

**Type**: Integer

**Default**: `0`

**Required**: No

**Used by**: Twitch transformer

**Examples**:
```bash
TWITCH_FFMPEG_THREADS=0   # Auto-optimize (recommended)
TWITCH_FFMPEG_THREADS=4   # Limit to 4 threads
TWITCH_FFMPEG_THREADS=8   # Use 8 threads
```

**When to override**: When streaming to multiple services to ensure fair CPU distribution.

### TWITCH_FPS

**Description**: Frames per second for the Twitch stream.

**Type**: Integer

**Default**: `60`

**Required**: No

**Used by**: Twitch transformer (for bitrate calculation)

**Common values**: `60`, `50`, `30`, `25`, `24`

**See also**: [Twitch Quality Settings](../services/twitch.md#quality-settings)

### TWITCH_HEIGHT

**Description**: Video height in pixels. Width is calculated automatically to maintain aspect ratio.

**Type**: Integer

**Default**: `720`

**Required**: No

**Used by**: Twitch transformer

**Common values**: `1080`, `900`, `720`, `540`, `480`

**Note**: Twitch recommends 720p for most non-partner streams due to lack of guaranteed transcoding.

### TWITCH_KBITS_PER_VIDEO_FRAME

**Description**: Bitrate multiplier for video encoding. Actual bitrate = `TWITCH_KBITS_PER_VIDEO_FRAME * TWITCH_FPS`.

**Type**: Integer

**Default**: `75`

**Required**: No

**Used by**: Twitch transformer

**Recommended values**:
- `100` for 1080p (results in 6000 kbps @ 60fps)
- `75` for 720p (results in 4500 kbps @ 60fps)

**Formula**: `bitrate = TWITCH_KBITS_PER_VIDEO_FRAME * TWITCH_FPS`

**Examples**:
```bash
TWITCH_KBITS_PER_VIDEO_FRAME=100  # 1080p: 6000 kbps @ 60fps
TWITCH_KBITS_PER_VIDEO_FRAME=75   # 720p: 4500 kbps @ 60fps
TWITCH_KBITS_PER_VIDEO_FRAME=50   # 540p: 3000 kbps @ 60fps
```

**See also**: [Twitch Bitrate Reference](../services/twitch.md#bitrate-reference-table)

### TWITCH_X264_PRESET

**Description**: x264 encoding preset. Controls speed vs quality trade-off.

**Type**: String

**Default**: `medium`

**Required**: No

**Used by**: Twitch transformer

**Possible values** (fastest to slowest):
- `ultrafast` - Extremely fast, lowest quality
- `superfast` - Very fast, low quality
- `veryfast` - Fast, moderate quality
- `faster` - Faster, good quality
- `fast` - Fast, good quality
- `medium` - **Default**, balanced
- `slow` - Slower, better quality
- `slower` - Much slower, high quality
- `veryslow` - Extremely slow, highest quality

**Recommendation**: Presets slower than `medium` offer diminishing returns. Use `fast` or `veryfast` if CPU is constrained.

**See also**: [x264 Encoding Guide](https://trac.ffmpeg.org/wiki/Encode/H.264)

---

## YouTube Variables

### YOUTUBE_KEY

**Description**: Stream key provided by YouTube. Setting this variable enables the YouTube service.

**Type**: String

**Default**: `""` (empty, service disabled)

**Required**: Yes (to enable YouTube)

**Used by**: YouTube application config

**Example**:
```bash
YOUTUBE_KEY=abcd-efgh-ijkl-mnop-qrst
```

**See also**: [YouTube Configuration](../services/youtube.md)

---

## Archive Variables

### ARCHIVE_PATH

**Description**: Directory path inside the container where streams are archived. Setting this variable enables archiving.

**Type**: String (filesystem path)

**Default**: `""` (empty, archiving disabled)

**Required**: Yes (to enable archiving)

**Used by**: Archive service configuration

**Example**:
```bash
ARCHIVE_PATH=/archive
```

**Important**:
- Path must exist inside container
- Must be writable by nginx user (UID:GID 100:101)
- Map to host directory via Docker volume for persistence

**See also**: [Archive Configuration](../services/archive.md)

### ARCHIVE_SUFFIX

**Description**: File extension for archived stream files.

**Type**: String

**Default**: `flv`

**Required**: No

**Used by**: Archive service configuration

**Common values**: `flv`, `mp4`, `mkv`

**Example**:
```bash
ARCHIVE_SUFFIX=mp4
```

**Note**: File format depends on stream encoding. `flv` is the most compatible with RTMP streams.

---

## Variable Quick Reference

| Variable | Default | Required | Service |
|----------|---------|----------|---------|
| `PUBLISH_IP_RANGE` | `192.168.0.0/16` | No | System |
| `TWITCH_KEY` | `""` | For Twitch | Twitch |
| `TWITCH_AUDIO_BITRATE` | `160k` | No | Twitch |
| `TWITCH_CODEC` | `libx264` | No | Twitch |
| `TWITCH_ENDPOINT` | `jfk` | No | Twitch |
| `TWITCH_FFMPEG_THREADS` | `0` | No | Twitch |
| `TWITCH_FPS` | `60` | No | Twitch |
| `TWITCH_HEIGHT` | `720` | No | Twitch |
| `TWITCH_KBITS_PER_VIDEO_FRAME` | `75` | No | Twitch |
| `TWITCH_X264_PRESET` | `medium` | No | Twitch |
| `YOUTUBE_KEY` | `""` | For YouTube | YouTube |
| `ARCHIVE_PATH` | `""` | For Archive | Archive |
| `ARCHIVE_SUFFIX` | `flv` | No | Archive |

---

## Configuration Examples

### Minimal Twitch Setup
```bash
TWITCH_KEY=live_123456789_abc
# All other Twitch variables use defaults
```

### Optimized 720p60 Twitch
```bash
TWITCH_KEY=live_123456789_abc
TWITCH_HEIGHT=720
TWITCH_FPS=60
TWITCH_KBITS_PER_VIDEO_FRAME=75
TWITCH_X264_PRESET=medium
TWITCH_ENDPOINT=jfk
```

### High-Quality 1080p60 Twitch
```bash
TWITCH_KEY=live_123456789_abc
TWITCH_HEIGHT=1080
TWITCH_FPS=60
TWITCH_KBITS_PER_VIDEO_FRAME=100
TWITCH_X264_PRESET=medium
```

### CPU-Constrained Twitch
```bash
TWITCH_KEY=live_123456789_abc
TWITCH_HEIGHT=720
TWITCH_FPS=30
TWITCH_KBITS_PER_VIDEO_FRAME=75
TWITCH_X264_PRESET=veryfast
TWITCH_FFMPEG_THREADS=4
```

### Multi-Service with Archive
```bash
# System
PUBLISH_IP_RANGE=192.168.1.0/24

# Twitch
TWITCH_KEY=live_123456789_abc
TWITCH_HEIGHT=720
TWITCH_FPS=60

# YouTube
YOUTUBE_KEY=abcd-efgh-ijkl-mnop

# Archive
ARCHIVE_PATH=/archive
ARCHIVE_SUFFIX=flv
```

---

## See Also

- [Configuration Overview](../configuration.md) - How configuration works
- [Twitch Service](../services/twitch.md) - Twitch-specific configuration
- [YouTube Service](../services/youtube.md) - YouTube configuration
- [Archive Service](../services/archive.md) - Archive configuration
- [Adding Services](adding-services.md) - Define custom environment variables

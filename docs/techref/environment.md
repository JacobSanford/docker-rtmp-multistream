---
title: Environment Variables Reference
description: Complete reference for all configuration environment variables
audience: developers
doc_type: reference
tags: [reference, configuration, environment-variables, settings]
lastReviewed: 2026-09-29
version: 1.x
---

# Environment Variables Reference

Complete reference for all environment variables used in docker-rtmp-multistream.

Every value is validated when the container starts. An invalid value logs an `ERROR:` line naming the variable and stops the container. `TWITCH_CODEC` and `TWITCH_X264_PRESET` are the exceptions: they are checked for allowed characters only, so a wrong value lets the container start and fails when a stream arrives.

!!! tip "Quick Configuration"
    For a practical guide on using these variables, see [Change Relay Settings](../configuration.md).

## System Variables

### NGINX_ERROR_LOG_LEVEL

**Description**: Minimum severity of messages nginx writes to the container log (`docker compose logs relay`).

**Type**: String

**Default**: `error`

**Required**: No

**Used by**: App configuration script (`89_configure_app.sh`)

**Valid values** (most to least verbose): `debug`, `info`, `notice`, `warn`, `error`, `crit`, `alert`, `emerg`. Any other value, or an empty value, stops the container at start.

**Example**:
```bash
NGINX_ERROR_LOG_LEVEL=info
```

This logs each connection and push while troubleshooting.

!!! warning
    The log can contain full stream URLs, including stream keys. At `info` and more verbose levels this happens every time you stream. Set the level back to `error` when you have finished troubleshooting.

**See also**: [Increase Log Verbosity](../troubleshooting/connection-issues.md#increase-log-verbosity)

### PUBLISH_IP_RANGE

**Description**: IPv4 address ranges allowed to publish streams to the relay, in Classless Inter-Domain Routing (CIDR) notation. Connections from any other address are refused with `access forbidden by rule` in the log. Connections from inside the container (`127.0.0.1`) are always allowed; the Twitch transformer uses this to republish its encoded stream.

**Type**: String (comma-separated list of IPv4 CIDR ranges)

**Default**: `172.16.0.0/12,192.168.0.0/16`: all Docker networks from Docker's default address pool, including the one `docker compose` creates, plus typical home networks.

**Required**: No

**Used by**: Authentication system (`auth.conf`)

**Valid values**: One or more `a.b.c.d/n` ranges separated by commas, with each octet 0–255 and `n` 0–32. An empty or invalid value stops the container at start.

**Examples**:
```bash
PUBLISH_IP_RANGE=172.16.0.0/12,192.168.1.0/24
```

This allows the Docker networks and one subnet. For the Docker networks and one address, use `172.16.0.0/12,192.168.1.50/32`.

**Note**: Setting this variable replaces the default. When OBS runs on the same machine as the relay, its connection arrives from the Docker network's gateway (for example `172.25.0.1`), so keep `172.16.0.0/12` in the list.

**See also**: [Security](../security.md)

---

## Twitch Variables

### TWITCH_KEY

**Description**: Stream key provided by Twitch. Setting this variable enables the Twitch service.

**Type**: String

**Default**: `""` (empty, service disabled)

**Required**: Yes (to enable Twitch)

**Used by**: Twitch application config

**Valid values**: Letters, digits, `.`, `_`, `:` and `-`, up to 200 characters. Any other value stops the container at start.

**Example**:
```bash
TWITCH_KEY=live_123456789_abcdefghijklmnopqrstuvwxyz
```

**See also**: [Twitch Configuration](../services/twitch.md)

### TWITCH_PARTNER

**Description**: Boolean flag indicating whether the user is a Twitch Partner with transcoding services. When `TRUE`, uses simple relay pattern (passthrough) like YouTube. When `FALSE`, uses transformer pattern (FFmpeg re-encoding).

**Type**: Boolean (`TRUE` / `FALSE`, case insensitive). Any other value, such as `yes` or `1`, stops the container at start.

**Default**: `FALSE`

**Required**: No

**Used by**: Twitch service configuration script (`90_configure_twitch.sh`)

**Valid values**:

- `TRUE` (or `true`): **Partner mode** - Simple relay with no transcoding. Stream is forwarded directly to Twitch, preserving full source quality for Twitch's multi-bitrate transcoding services. All transformer-related variables (`TWITCH_HEIGHT`, `TWITCH_FPS`, etc.) are ignored in this mode.

- `FALSE` (or `false`): **Non-partner mode** (default) - Transformer pattern with FFmpeg re-encoding. Allows full control over output quality, resolution, bitrate, and codec. Useful for bandwidth optimization or streaming to Twitch without partner transcoding.

**Example**:
```bash
# Partner mode (simple relay, no encoding)
TWITCH_PARTNER=TRUE

# Non-partner mode (default, with encoding)
TWITCH_PARTNER=FALSE
```

**See also**: [Twitch Configuration - Partner vs Non-Partner](../services/twitch.md#partner-vs-non-partner-streaming)

!!! note "Service Pattern Selection"
    The `TWITCH_PARTNER` setting determines which nginx configuration files are enabled:

    - **Partner mode**: Enables `apps/twitch-partner.conf` (simple relay)
    - **Non-partner mode**: Enables `transformers/twitch.conf` + `apps/twitch.conf` (transformer pattern)

### TWITCH_AUDIO_BITRATE

**Description**: Audio bitrate for the Twitch stream. See Twitch's [Broadcasting Guidelines](https://help.twitch.tv/s/article/broadcasting-guidelines?language=en_US){target="_blank"} for the current maximum.

**Type**: String

**Default**: `160k`

**Required**: No

**Used by**: Twitch transformer

**Valid values**: Digits, optionally followed by `k` or `K` (`160k`, `160000`). The value is not checked against Twitch's maximum. Any other value stops the container at start.

**Examples**:
```bash
TWITCH_AUDIO_BITRATE=160k
```

`160k` is the default. `128k` uses less upload.

### TWITCH_AUDIO_CHANNELS

**Description**: Number of audio channels in the Twitch stream. `2` sends stereo; `1` downmixes to mono.

**Type**: Integer

**Default**: `2`

**Required**: No

**Used by**: Twitch transformer

**Valid values**: `1` or `2`. Any other value stops the container at start.

**Example**:
```bash
TWITCH_AUDIO_CHANNELS=2
```

This sends stereo.

### TWITCH_CODEC

**Description**: Video codec for Twitch encoding. Typically shouldn't be changed.

**Type**: String

**Default**: `libx264`

**Required**: No

**Used by**: Twitch transformer

**Valid values**: `libx264`. The transformer sets H.264-specific options (`-x264opts`, `-profile:v main`) and sends FLV over RTMP, which in this image's FFmpeg carries H.264 only. Other encoders, including `libx264rgb` and `libx265`, fail.

**Example**:
```bash
TWITCH_CODEC=libx264
```

**Note**: This value is not checked against a list at startup. An unsupported codec lets the container start and report Twitch as enabled, then fails when a stream arrives: Twitch receives nothing.

### TWITCH_ENDPOINT

**Description**: Twitch ingest server identifier. Choose the server closest to your location.

**Type**: String (server code)

**Default**: `use10` (US East, N. Virginia)

**Required**: No

**Used by**: Twitch application config

**Valid values**: Letters, digits, `_` and `-`, 1 to 100 characters. The relay connects to `rtmp://<TWITCH_ENDPOINT>.contribute.live-video.net/app/`, so the value must be a Twitch ingest slug.

**Common values** (from `https://ingest.twitch.tv/ingests`, checked 2026-09-25):

| Slug | Location |
|---|---|
| `use10` | US East (N. Virginia) |
| `use20` | US East (Ohio) |
| `usw20` | US West (Oregon) |
| `euw10` | Europe (Ireland) |
| `euw30` | Europe (Paris) |
| `euc10` | Europe (Frankfurt) |
| `eun10` | Europe (Stockholm) |
| `sae10` | South America (São Paulo) |
| `apn10` | Asia Pacific (Tokyo) |
| `apn20` | Asia Pacific (Seoul) |
| `aps10` | Asia Pacific (Singapore) |
| `aps20` | Asia Pacific (Sydney) |
| `aps30` | Asia Pacific (Mumbai) |

Twitch changes this list. For the current one, open `https://ingest.twitch.tv/ingests` and use the label before `.contribute.live-video.net` in each `url_template`.

**Example**:
```bash
TWITCH_ENDPOINT=euc10
```

This uses Europe (Frankfurt). Set one value, with no comment on the same line.

**Note**: Legacy slugs such as `jfk`, `syd` and `lhr` still resolve, but several route to US servers regardless of their name. Use a slug from the list above.

**See also**: [Twitch Ingest Endpoints](https://help.twitch.tv/s/twitch-ingest-recommendation?language=en_US){target="_blank"}

### TWITCH_FFMPEG_THREADS

**Description**: Number of threads the libx264 encoder uses. `0` lets x264 choose based on the CPU count.

**Type**: Integer

**Default**: `0`

**Required**: No

**Used by**: Twitch transformer

**Valid values**: Integer, 0 to 64. Any other value stops the container at start.

**Examples**:
```bash
TWITCH_FFMPEG_THREADS=0
```

`0` lets x264 choose. To limit the encoder to 4 threads, use `4`.

**When to override**: To cap the relay's CPU use on a shared host.

### TWITCH_FPS

**Description**: Frames per second for the Twitch stream.

**Type**: Integer

**Default**: `60`

**Required**: No

**Used by**: Twitch transformer (for bitrate calculation)

**Valid values**: Integer, 1 to 120. Any other value stops the container at start.

**Common values**: `60`, `50`, `30`, `25`, `24`

**Example**:
```bash
TWITCH_FPS=30
```

**See also**: [Twitch Quality Settings](../services/twitch.md#optimizing-twitch-quality)

### TWITCH_HEIGHT

**Description**: Video height in pixels. Width follows the source aspect ratio, rounded to an even number. A source shorter than `TWITCH_HEIGHT` is upscaled, which uses bitrate without adding detail; set `TWITCH_HEIGHT` to your source height or lower.

**Type**: Integer

**Default**: `720`

**Required**: No

**Used by**: Twitch transformer

**Valid values**: Integer, 144 to 4320. Any other value stops the container at start.

**Common values**: `1080`, `900`, `720`, `540`, `480`

**Example**:
```bash
TWITCH_HEIGHT=1080
```

### TWITCH_KBITS_PER_VIDEO_FRAME

**Description**: Bitrate multiplier for video encoding. Actual bitrate = `TWITCH_KBITS_PER_VIDEO_FRAME * TWITCH_FPS`.

**Type**: Integer

**Default**: `75`

**Required**: No

**Used by**: Twitch transformer

**Valid values**: Integer, 1 to 1000. Any other value stops the container at start.

**Examples**:
```bash
TWITCH_KBITS_PER_VIDEO_FRAME=100
```

At `TWITCH_FPS=60`, `100` gives 6000 kbps, `75` (the default) gives 4500 kbps, and `50` gives 3000 kbps. `TWITCH_HEIGHT` does not change the bitrate.

**See also**: [Twitch Bitrate Reference](../services/twitch.md#bitrate-reference-table)

### TWITCH_X264_PRESET

**Description**: x264 encoding preset. Controls speed vs quality trade-off.

**Type**: String

**Default**: `medium`

**Required**: No

**Used by**: Twitch transformer

**Valid values**: Letters, digits, `_` and `-`, up to 100 characters. The value is not checked against the preset list below: a misspelled preset lets the container start and report Twitch as enabled, then fails when a stream arrives, and Twitch receives nothing.

**Common values** (fastest to slowest):
- `ultrafast` - Extremely fast, lowest quality
- `superfast` - Very fast, low quality
- `veryfast` - Fast, moderate quality
- `faster` - Faster, good quality
- `fast` - Fast, good quality
- `medium` - **Default**, balanced
- `slow` - Slower, better quality
- `slower` - Much slower, high quality
- `veryslow` - Extremely slow, highest quality
- `placebo` - Slowest; negligible gain over `veryslow`

**Example**:
```bash
TWITCH_X264_PRESET=veryfast
```

**When to override**: Presets slower than `medium` offer diminishing returns. Use `fast` or `veryfast` if CPU is constrained.

**See also**: [x264 Encoding Guide](https://trac.ffmpeg.org/wiki/Encode/H.264){target="_blank"}

---

## YouTube Variables

### YOUTUBE_KEY

**Description**: Stream key provided by YouTube. Setting this variable enables the YouTube service.

**Type**: String

**Default**: `""` (empty, service disabled)

**Required**: Yes (to enable YouTube)

**Used by**: YouTube application config

**Valid values**: Letters, digits, `.`, `_`, `:` and `-`, up to 200 characters. Any other value stops the container at start.

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

**Valid values**: An absolute path, up to 500 characters, with no spaces, no `..` segments, no newlines and none of `` ; | & $ ` ( ) { } < > # ' " ``. The directory must exist inside the container and be writable by the nginx user (user ID 100, group ID 101: `docker compose exec relay id nginx` prints `uid=100(nginx) gid=101(nginx)`). Any other value stops the container at start.

**Example**:
```bash
ARCHIVE_PATH=/archive
```

**Note**: Map the path to a host directory with a Docker volume, or archives are lost when the container is removed. See [Enable Archive](../services/archive.md#enable-archive).

**See also**: [Archive Configuration](../services/archive.md)

---

## See Also

- [Change Relay Settings](../configuration.md) - How configuration works
- [Add a Streaming Service](../developer/adding-services/overview.md) - Define custom environment variables

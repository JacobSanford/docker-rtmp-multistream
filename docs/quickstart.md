---
title: Quick Start
description: Relay one OBS stream to Twitch and YouTube through the relay
audience: users
doc_type: howto
tags: [quickstart, setup, getting-started, obs]
lastReviewed: 2026-09-25
version: 1.x
---

# Quick Start: Relay OBS to Twitch and YouTube

This guide runs the relay on one Linux machine (the *relay host*) and points OBS Studio on your streaming PC at it. The relay receives your stream over the Real-Time Messaging Protocol (RTMP) and forwards it to Twitch and YouTube.

Before you start, check the [Requirements](requirements.md).

| Placeholder | Meaning |
|---|---|
| `<RELAY_IP>` | The relay host's LAN address, for example `192.168.1.50`. On the relay host, `hostname -I` prints it. |

## Set Up the Relay Host

1. Clone the repository and change into it:

    ```bash
    git clone https://github.com/JacobSanford/docker-rtmp-multistream.git
    cd docker-rtmp-multistream
    ```

2. Copy your stream keys:
    - **Twitch**: Creator Dashboard → **Settings** → **Stream** → **Primary Stream key**.
    - **YouTube**: YouTube Studio → **Create** → **Go live** → **Stream** → **Stream key**.

    TODO(verify: current Twitch and YouTube menu paths to the stream key)

3. In `env/relay.env`, set each key, then save the file:

    ```bash
    TWITCH_KEY=live_123456789_abcdefghij
    YOUTUBE_KEY=abcd-efgh-ijkl-mnop-qrst
    ```

    Paste each key with no spaces or quotes. Leave a key empty to turn that service off.

    !!! warning "Keep your keys out of git"
        `env/relay.env` is tracked by git. After adding keys, run `git update-index --skip-worktree env/relay.env` so a later `git commit -a` cannot publish them.

4. If your streaming PC's address does not start with `192.168.`, add its subnet to `PUBLISH_IP_RANGE` in `env/relay.env`, keeping the default ranges. For a streaming PC at `10.0.0.25`:

    ```bash
    PUBLISH_IP_RANGE=172.16.0.0/12,192.168.0.0/16,10.0.0.0/24
    ```

    The relay refuses streams from any address outside this list.

5. Start the relay:

    ```bash
    ./start.sh
    ```

    `start.sh` removes any existing relay container, rebuilds the image against the latest base image, and runs the relay in the foreground. Press Ctrl+C to stop it.

6. In a second terminal on the relay host, confirm each service is enabled:

    ```bash
    docker compose logs relay | grep -E "service enabled|Skipping|ERROR"
    ```

    Expected output:

    ```text
    Twitch Non-Partner configuration complete, and service enabled.
    YouTube configuration complete, and service enabled.
    ```

    If you see an `ERROR:` line, the relay has stopped. See [Invalid Environment Value](troubleshooting/connection-issues.md#invalid-environment-value).

!!! warning "Security"
    The relay has no password or key authentication. It accepts a stream from any address in `PUBLISH_IP_RANGE`. Keep that list as narrow as your network allows, and never expose port 1935 to the internet.

## Point OBS at the Relay

1. In OBS, open **Settings** → **Stream** and set:
    - **Service**: Custom
    - **Server**: `rtmp://<RELAY_IP>:1935/relay`
    - **Stream Key**: any name, for example `mystream`. This is **not** your Twitch or YouTube key; it names the stream on the relay, in its log and in archive file names.
    - **Use authentication**: unchecked

2. Open **Settings** → **Output**, set **Output Mode** to **Advanced**, and on the **Streaming** tab set:
    - **Encoder**: a hardware encoder such as NVIDIA NVENC H.264 if you have one, otherwise x264.
    - **Rate Control**: CBR (constant bitrate).
    - **Keyframe Interval**: 2 s.
    - **Bitrate**: the highest your upload sustains. YouTube receives this stream unchanged. For Twitch, the relay re-encodes to 4500 kbps by default; in Twitch partner mode (`TWITCH_PARTNER=TRUE`) Twitch also receives it unchanged, so keep it within Twitch's [Broadcasting Guidelines](https://help.twitch.tv/s/article/broadcasting-guidelines?language=en_US){target="_blank"}. See [Bandwidth Requirements](performance/bandwidth.md) for the relay host's total upload.

    YouTube, and Twitch in partner mode, get exactly what OBS sends, so these settings are what those viewers see.

3. Click **Start Streaming**, then confirm the stream is live in Twitch Stream Manager and in YouTube Studio → **Go live**.

    If it is not, start at the [Troubleshooting Guide](troubleshooting/index.md).

## See Also

- [Change Relay Settings](configuration.md) - Edit, apply and confirm a setting
- [Environment Variables Reference](techref/environment.md) - Every variable, its default and valid values
- [Troubleshooting](troubleshooting/index.md) - Common issues and solutions

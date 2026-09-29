---
title: Restrict Who Can Publish and Watch
description: Limit which machines can send a stream to the relay and which can watch it
audience: users
doc_type: howto
tags: [security, network, publish, play, access-control]
lastReviewed: 2026-09-29
version: 1.x
---

# Restrict Who Can Publish and Watch

The relay controls who can **publish** (send a stream to it) with `PUBLISH_IP_RANGE`. It does not control who can **watch**: any machine that can reach port 1935 can play the stream. This page limits both.

## Before You Begin

- The relay is set up as in [Quick Start](quickstart.md), and runs with `docker compose`.
- You know the IP address of the machine that runs your streaming software, and the relay host's address on the network your streaming software uses.
- For the confirm steps: `ffprobe` (part of FFmpeg) on a second machine.

## Limit Who Can Publish

1. In `env/relay.env`, set `PUBLISH_IP_RANGE` to the networks or addresses allowed to publish, separated by commas. Every entry needs a prefix: use `/32` for a single machine. Keep `172.16.0.0/12` if your streaming software runs on the relay host itself, because its connection arrives from the Docker network. For a streaming PC at `192.168.1.50` and nothing else:

    ```bash
    PUBLISH_IP_RANGE=172.16.0.0/12,192.168.1.50/32
    ```

    Drop `172.16.0.0/12` if nothing streams from the relay host.

2. Recreate the container:

    ```bash
    docker compose up -d --force-recreate
    ```

3. Confirm the container started:

    ```bash
    docker compose ps
    ```

    If the relay is not running, check `docker compose logs relay` for an `ERROR: PUBLISH_IP_RANGE` line and fix the value.

`127.0.0.1` can always publish, whatever this variable says. For more examples and the "access forbidden by rule" error, see [IP Authentication](troubleshooting/ip_authentication.md).

## Limit Who Can Watch

`docker-compose.yml` publishes port 1935 on every interface of the relay host. Bind it to one address instead, so only machines that can reach that address can connect, to publish or to watch.

1. In `docker-compose.yml`, replace `"1935:1935"` with the relay host's address on your streaming network. For a relay host at `192.168.1.20`:

    ```yaml
        ports:
          - "192.168.1.20:1935:1935"
    ```

    To allow only software on the relay host itself, use `"127.0.0.1:1935:1935"`.

2. Recreate the container:

    ```bash
    docker compose up -d --force-recreate
    ```

3. In your streaming software, set the server to the address you bound, for example `rtmp://192.168.1.20:1935/relay`. A server of `localhost` or `127.0.0.1` stops working unless you bound `127.0.0.1`.

`docker-compose.yml` is tracked by git, unlike `env/relay.env`. If a later `git pull` stops with `Your local changes to the following files would be overwritten by merge: docker-compose.yml`, save your copy, run `git checkout docker-compose.yml`, pull again, then put your `ports:` line back.

!!! warning "A host firewall may not block Docker ports"
    Docker writes its own iptables rules for published ports, so host firewall tools such as `ufw` may not block them. Bind the port as above, or block it at a firewall in front of the host.

## Confirm

Start streaming, then run these from a machine that should **not** have access. Replace `<RELAY_HOST>` with any address of the relay host that this machine can reach, and `<STREAM_NAME>` with the stream name in your streaming software.

1. Try to watch:

    ```bash
    ffprobe -v error -show_entries stream=codec_name -of csv rtmp://<RELAY_HOST>:1935/relay/<STREAM_NAME>
    ```

    With the port bound, this fails with `Connection refused`. If it prints `stream,h264`, the machine can watch: check that the `ports:` line took effect with `docker compose ps`, which shows the bound address.

2. Try to publish:

    ```bash
    ffmpeg -re -f lavfi -i testsrc -t 5 -c:v libx264 -f flv rtmp://<RELAY_HOST>:1935/relay/test
    ```

    This fails with `Connection refused` if the port is bound, or `Broken pipe` if the machine can connect but is outside `PUBLISH_IP_RANGE`. The relay log shows `access forbidden by rule` for the second case.

## See Also

- [Security](security.md) - What the relay protects against, and what it does not
- [IP Authentication](troubleshooting/ip_authentication.md) - Publish refused with "access forbidden by rule"
- [`PUBLISH_IP_RANGE`](techref/environment.md#system-variables) - Default and syntax

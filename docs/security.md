---
title: Security
description: Who the relay protects against, what it protects, and what it leaves open
audience: users
doc_type: explanation
tags: [security, authentication, access-control, stream-keys]
lastReviewed: 2026-09-29
version: 1.x
---

# Security

This page explains what the relay protects, against whom, and what it leaves to you. To lock down a running relay, see [Restrict Who Can Publish and Watch](restrict-access.md).

## Reporting Security Issues

Email [jacob.josh.sanford@gmail.com](mailto:jacob.josh.sanford@gmail.com) rather than opening a public issue. The same policy is in `SECURITY.md` at the repository root.

## Threat Model

The relay is built to run on a home or studio network, next to the machine that runs your streaming software. It assumes:

- **You are trusted.** Whoever edits `env/relay.env` and `docker-compose.yml`, or can run `docker` on the host, controls the relay and can read its stream keys.
- **Other machines on the network are not.** They should not be able to send a stream through the relay to your Twitch or YouTube channel.
- **Settings can be mistyped.** A bad value should stop the relay at startup rather than produce a broken or unsafe nginx configuration.

It does not try to hide your stream from viewers on the network, or to protect stream keys from anyone with access to the host.

## What Is Protected

- **Publishing.** Only addresses in `PUBLISH_IP_RANGE`, plus `127.0.0.1`, can send a stream to the relay. Others are refused with `access forbidden by rule` in the log. The default, `172.16.0.0/12,192.168.0.0/16`, admits the Docker networks and typical home networks.
- **Configuration.** Every variable you set is checked against a whitelist or pattern before it is written into the nginx configuration, so a value cannot inject a shell command or an nginx directive. If a value fails, the container stops before nginx starts and the log names the variable. For each check, see the [Input Validation Reference](developer/validation.md).

## What Is Not Protected

- **Playback is open.** The relay has publish rules only, and no play rules. Anyone who can reach port 1935 can play `rtmp://<RELAY_HOST>/relay/<STREAM_NAME>`, and the transcoded Twitch stream at `/twitch/<STREAM_NAME>`. This was checked against a running container: with `PUBLISH_IP_RANGE=10.99.0.0/24`, a host outside that range was refused as a publisher but could play `relay/<STREAM_NAME>`.
- **The port is published on every host interface.** `docker-compose.yml` maps `1935:1935`. Docker writes its own iptables rules for published ports, so host firewall tools such as `ufw` may not block them. To close both gaps, see [Limit Who Can Watch](restrict-access.md#limit-who-can-watch).
- **`127.0.0.1` can always publish**, whatever `PUBLISH_IP_RANGE` is set to.
- **The `twitch` application accepts publishes directly.** Any address in `PUBLISH_IP_RANGE` can publish to `/twitch/<STREAM_NAME>` and send a stream to Twitch without going through the transcoder.

## Where Stream Keys Live

- **`env/relay.env`**, in plain text. `.gitignore` excludes it, so git does not commit it; the tracked template is `env/relay.env.example`, which holds no keys. See [Change Relay Settings](configuration.md).
- **The container environment.** Anyone who can run `docker inspect` on the container can read them. The relay has no support for Docker secrets or `*_FILE` variables.
- **The generated nginx config** inside the container, in plain text.
- **The container log**, when `NGINX_ERROR_LOG_LEVEL` is `info` or more verbose: nginx logs the full push URL, including the key, when it starts relaying. Return to `error` (the default) after troubleshooting, and remove keys before sharing logs.

If a key may have leaked, reset it in the service's dashboard.

## Running the Container

- **Archive path.** The path must be writable by the nginx user. If it is not, the container stops at startup with `ERROR: ARCHIVE_PATH is not writable by the nginx user.` Archive writes every stream published to `relay` at its source bitrate, so a 6000 kbps stream uses about 2.7 GB per hour: watch disk space.
- **Read-only filesystem.** A read-only root filesystem breaks startup: the startup scripts rewrite files under `NGINX_CONFD_DIR` (`/etc/nginx/http.d`) in place with `sed -i` and `mv`.
- **Resource limits.** Twitch non-partner mode re-encodes for as long as you stream. Setting a CPU limit on the container keeps it from starving the host. See [CPU Considerations](performance/hardware.md).
- **Updates.** To pick up relay and base image fixes, run `git pull`, then rebuild with `docker compose build --pull` and restart with `docker compose up -d`.

## See Also

- [Restrict Who Can Publish and Watch](restrict-access.md) - Lock down publishing and playback
- [Input Validation Reference](developer/validation.md) - Every validation function and the variables it checks
- [IP Authentication](troubleshooting/ip_authentication.md) - Publish refused with "access forbidden by rule"
- [Architecture](techref/architecture.md) - How configuration is processed

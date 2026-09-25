---
title: Requirements
description: What the relay host needs before you start, and how to check each item
audience: users
doc_type: reference
tags: [requirements, prerequisites, docker, setup]
lastReviewed: 2026-09-25
version: 1.x
---

# Requirements

Check each item on the relay host before following the [Quick Start](quickstart.md).

## Operating System

Linux is the only supported operating system. The relay may run on macOS or Windows, but that is not tested.

## Software

| Requirement | Check | Expected |
|---|---|---|
| Docker Engine ([install](https://docs.docker.com/engine/install/){target="_blank"}) | `docker --version` | Prints a version |
| Docker Compose v2 plugin ([install](https://docs.docker.com/compose/install/){target="_blank"}) | `docker compose version` | Prints a version. `start.sh` uses `docker compose`; the older standalone `docker-compose` command does not work with it. |
| Docker without `sudo` ([steps](https://docs.docker.com/engine/install/linux-postinstall/){target="_blank"}) | `docker ps` | Prints a table, not `permission denied` |
| git | `git --version` | Prints a version |

## Network

| Requirement | Why | Check |
|---|---|---|
| Inbound TCP port 1935 on the relay host, from the streaming PC | OBS sends its stream to the relay on this port | After the relay starts, from the streaming PC: `nc -zv <RELAY_IP> 1935` (Linux, macOS) or `Test-NetConnection <RELAY_IP> -Port 1935` (Windows PowerShell) succeeds |
| Outbound TCP port 1935 from the relay host | The relay forwards the stream to Twitch and YouTube over the Real-Time Messaging Protocol (RTMP) | `nc -zv use10.contribute.live-video.net 1935` and `nc -zv a.rtmp.youtube.com 1935` each print a line containing `succeeded` or `open` |
| Outbound HTTPS from the relay host | Building the image downloads the base image and packages | `docker compose build --pull` completes |
| Streaming PC address inside `PUBLISH_IP_RANGE` | The relay refuses streams from any other address. The default allows `172.16.0.0/12` and `192.168.0.0/16`. | See [OBS Is Refused](troubleshooting/ip_authentication.md) |

`<RELAY_IP>` is the relay host's LAN address. If a proxy server sits between the relay host and the internet, it must allow both outbound HTTPS and outbound RTMP.

## Bandwidth and Hardware

The relay host's upload must carry every service at once. See [Bandwidth Requirements](performance/bandwidth.md) and [Hardware Requirements](performance/hardware.md).

## See Also

- [Quick Start](quickstart.md) - First-time setup
- [Bandwidth Requirements](performance/bandwidth.md) - Upload needed per service
- [Hardware Requirements](performance/hardware.md) - CPU and system resources

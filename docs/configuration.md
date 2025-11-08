---
title: Configuration
description: How to configure docker-rtmp-multistream services and environment variables
audience: users
doc_type: howto
tags: [configuration, setup, environment-variables, services]
lastReviewed: 2025-10-21
version: 1.x
---

# Configuration

This page explains how docker-rtmp-multistream is configured and how services are enabled.

## Environment Variables

Configuration is performed by passing environment variables to the docker container. This can be done by editing **`env/relay.env`**. This file defines environment variables that are passed to the container at runtime.

!!! warning "Security"
    Never commit `env/relay.env` to git/version control if it contains stream keys or secrets. The included `.gitignore` prevents this by default.

### General

| Environment Variable | Description | Required |
|---------------------|-------------|----------|
| `PUBLISH_IP_RANGE` | Allowed IP range for publishing (CIDR notation) | N |

For complete system-wide configuration options, see [Environment Variables Reference](techref/environment.md).

### Twitch

!!! note "Service Activation"
    Setting `TWITCH_KEY` enables the Twitch streaming service. If `TWITCH_KEY` is empty or unset, Twitch streaming is disabled.

For detailed Twitch configuration options including quality settings, encoding parameters, and ingest endpoints, see [Twitch Configuration](services/twitch.md).

### YouTube

!!! note "Service Activation"
    Setting `YOUTUBE_KEY` enables the YouTube streaming service. If `YOUTUBE_KEY` is empty or unset, YouTube streaming is disabled.

For YouTube configuration details, see [YouTube Configuration](services/youtube.md).

### Archive

!!! note "Service Activation"
    Setting `ARCHIVE_PATH` to a writable directory enables the archive service. If `ARCHIVE_PATH` is empty, unset, or not writable, archiving is disabled.

For archive configuration including volume setup and format options, see [Archive Configuration](services/archive.md).

## See Also

- [Environment Variables Reference](techref/environment.md) - Complete variable listing
- [Architecture](techref/architecture.md) - How configuration is processed internally
- [Quick Start Guide](quickstart.md) - Step-by-step setup

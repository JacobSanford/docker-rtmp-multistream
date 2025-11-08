---
title: Archive Service
description: Configure local stream archiving to disk
audience: users
doc_type: howto
tags: [archive, recording, vod, backup]
lastReviewed: 2025-10-21
version: 1.x
---

# Archive

## Overview

The relay can archive streams to local disk in real-time. To enable this feature, set the `ARCHIVE_PATH` environment variable in the `env/relay.env` file to specify a directory path inside the Docker container (e.g., `/stream_archive`).

!!! warning "Further Setup Required"
    See [Persistent Storage Setup](#persistent-storage-setup) for details on how to configure host directory mapping.

## Configuration

The Archive service can be configured by setting the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `ARCHIVE_PATH` | Specifies the path within the container where the archive videos will be stored. Enabling this feature activates stream archiving. | `` |
| `ARCHIVE_SUFFIX` | Defines the file extension or format of the videos saved in the archive. | `flv` |

## Persistent Storage Setup

By default, archived videos are stored inside the Docker container. Since Docker containers are ephemeral, these files will be deleted when the container is removed.

To persist archives on your host machine, map a host directory as a Docker volume. You can do this in your `docker-compose.yml`:

```yaml
services:
  relay:
    build:
      context: .
    ports:
      - "1935:1935"
    env_file:
      - ./env/relay.env
    volumes:
      - ./stream_archive:/archive  # Format: Host directory : Container path (ARCHIVE_PATH)
```

Also, ensure you set permissions on the host directory so that the container can write to it:

```bash
mkdir -p stream_archive
chown 100:101 stream_archive
chmod o+w stream_archive
```

## File Naming

Archived files are automatically named using a timestamp-based pattern. The file extension is determined by the `ARCHIVE_SUFFIX` setting (default: `flv`).

## See Also

- [Configuration Overview](../configuration.md) - Docker volumes and environment setup
- [Requirements](../requirements.md) - System prerequisites
- [Troubleshooting](../troubleshooting/index.md) - Common archive issues

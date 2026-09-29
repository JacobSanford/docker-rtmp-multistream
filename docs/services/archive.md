---
title: Archive Streams to Disk
description: Record every incoming stream to a host directory
audience: users
doc_type: howto
tags: [archive, recording, vod, backup]
lastReviewed: 2026-09-25
version: 1.x
---

# Archive Streams to Disk

## Overview

The relay can archive streams to disk in real time. Archives are written inside the container to `ARCHIVE_PATH`; mount a host directory there so the files survive container removal.

## Enable Archive

1. Create a host directory and give it to the container's nginx user (UID 100, GID 101):

    ```bash
    mkdir -p stream_archive
    sudo chown 100:101 stream_archive
    ```

2. In `docker-compose.yml`, add a `volumes:` entry to the existing `relay` service:

    ```yaml
    services:
      relay:
        volumes:
          - ./stream_archive:/archive
    ```

3. In `env/relay.env`, set `ARCHIVE_PATH` to the container side of that mount:

    ```bash
    ARCHIVE_PATH=/archive
    ```

4. Recreate the container:

    ```bash
    docker compose up -d --force-recreate
    ```

5. Confirm the service is enabled:

    ```bash
    docker compose logs relay | grep -iE "archive|error"
    ```

    Expected output: `Archive configuration complete, and service enabled.`

    If you see `ERROR: ARCHIVE_PATH is not writable by the nginx user.`, the container has stopped: the relay does not run at all, not only archiving. Check that `ARCHIVE_PATH` matches the container side of the mount in step 2, and that step 1's `chown` succeeded.

## Settings

`ARCHIVE_PATH` turns archiving on. `ARCHIVE_SUFFIX` sets the filename extension only; files are always FLV. For both variables' defaults and valid values, see [Archive Variables](../techref/environment.md#archive-variables).

## File Naming

Each stream is written to a new file named:

```text
<stream-name>-<unix-time>_<DDMMYYYY>_<HHMMSS>.<ARCHIVE_SUFFIX>
```

For example, a stream published as `rtmp://<relay>/relay/live` on 25 September 2026 at 14:53:40 UTC produces:

```text
live-1790348020_25092026_145340.flv
```

The date and time are in UTC, not your local time zone. Because the date is day-first, sorting by filename does not sort by date across months; sort by the Unix time after the stream name instead, or by modification time (`ls -t`).

## See Also

- [Change Relay Settings](../configuration.md) - Edit, apply and confirm a setting
- [Requirements](../requirements.md) - System prerequisites
- [Troubleshooting](../troubleshooting/index.md) - Common archive issues

# Archive

## Overview

The relay can archive streams to local disk in real-time. To enable this feature, set the `ARCHIVE_PATH` environment variable in the `env/relay.env` file to specify a directory path inside the Docker container (e.g., `/stream_archive`).

!!! warning "Permissions Required"
    The archive path must exist and be writable by the nginx user (UID:GID 100:101).

## Configuration

The Archive service can be configured by setting the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `ARCHIVE_PATH` | Specifies the path within the container where the archive videos will be stored. Enabling this feature activates stream archiving. | `` |
| `ARCHIVE_SUFFIX` | Defines the file extension or format of the videos saved in the archive. | `flv` |

## Persistent Storage Setup

By default, archived videos are stored inside the Docker container. Since Docker containers are ephemeral, these files will be deleted when the container is removed.

To persist archives on your host machine, map a host directory as a Docker volume.

### Step-by-Step Configuration

#### 1. Update docker-compose.yml

Add a volume mapping to your `docker-compose.yml` file to link a host directory with the container path:

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
      - ./stream_archive:/archive
```

This maps the host directory `./stream_archive` to `/archive` inside the container.

#### 2. Set Directory Permissions

The nginx process runs as user ID 100, group ID 101. Set appropriate permissions on the host directory:

```bash
chown 100:101 ./stream_archive
chmod o+w ./stream_archive
```

#### 3. Configure Environment Variable

Set the `ARCHIVE_PATH` environment variable in `env/relay.env` to match the container path:

```bash
ARCHIVE_PATH=/archive
```

#### 4. Restart the Service

```bash
docker compose down
docker compose up
```

Your streams will now be archived to `./stream_archive` on your host machine.

## File Naming

Archived files are automatically named using a timestamp-based pattern. The file extension is determined by the `ARCHIVE_SUFFIX` setting (default: `flv`).

## See Also

- [Configuration Overview](../configuration.md) - Docker volumes and environment setup
- [Requirements](../requirements.md) - System prerequisites
- [Troubleshooting](../troubleshooting.md) - Common archive issues

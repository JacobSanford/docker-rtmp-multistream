---
title: Archive Troubleshooting
description: Troubleshooting Archive-specific recording issues
audience: users
doc_type: howto
tags: [troubleshooting, archive, recording, storage]
lastReviewed: 2026-09-25
version: 1.x
---

# Archive Troubleshooting

Troubleshooting issues specific to local stream archiving.

## Common Issues

| Issue | Description |
|-------|-------------|
| **[Archive Not Recording](#archive-not-recording)** | No files appearing in archive directory, recording not working |
| **[File Format Issues](#file-format-issues)** | Archive files won't play or are corrupted |
| **[Files Not Named as Expected](#files-not-named-as-expected)** | Archive filenames are unclear or unexpected |
| **[Archive Grows Too Large](#archive-grows-too-large)** | Disk filling up with old archives, storage management |
| **[Debug Logs](#debug-logs)** | How to check Archive-specific logs and error messages |

---

## Archive Not Recording

### Symptoms
- Stream works on Twitch/YouTube
- No files appearing in archive directory

### Possible Causes

#### 1. Archive Not Enabled

**Check**: Look for archive configuration in logs:

```bash
docker compose logs relay | grep -i archive
```

**Solution**: Set `ARCHIVE_PATH` in `env/relay.env`:
```bash
ARCHIVE_PATH=/archive
```

Recreate the container so it reads the new value:

```bash
docker compose up -d --force-recreate
```

Confirm the service is enabled:

```bash
docker compose logs relay | grep -E "service enabled|Skipping|ERROR"
```

#### 2. Archive Folder Not Mounted or Not Writable

**Check**:

```bash
docker compose logs relay | grep "not writable"
```

```text
ERROR: ARCHIVE_PATH is not writable by the nginx user.
```

This error appears both when no host folder is mounted and when the mounted folder is not writable by the container's nginx user (UID 100, GID 101).

**Solution**:

1. In `docker-compose.yml`, mount a host folder at the path set in `ARCHIVE_PATH`. The `volumes:` block goes under the `relay` service:

    ```yaml
    services:
      relay:
        image: ghcr.io/jacobsanford/rtmp-multistream:1.x
        build: .
        ports:
          - "1935:1935"
        env_file:
          - ./env/relay.env
        volumes:
          - ./stream_archive:/archive
    ```

2. Create the folder and give it to the container's nginx user:

    ```bash
    mkdir -p stream_archive
    sudo chown 100:101 stream_archive
    ```

    Recordings in this folder are then owned by UID 100, so deleting them from the host requires `sudo`.

3. Recreate the container:

    ```bash
    docker compose up -d --force-recreate
    ```

4. Confirm the service is enabled:

    ```bash
    docker compose logs relay | grep -E "service enabled|Skipping|ERROR"
    ```

    The output includes `Archive configuration complete, and service enabled.`

#### 3. Disk Space

**Check**: Verify available space:

```bash
df -h ./stream_archive
```

**Solution**: Free up disk space or use a different directory with more space.

**Estimate space needed**:
- 1080p60 @ 20 Mbps: ~9 GB per hour
- 720p60 @ 6 Mbps: ~2.7 GB per hour
- 720p30 @ 3 Mbps: ~1.35 GB per hour

## File Format Issues

**Issue**: Archive files won't play or are corrupted

Archives are always recorded as FLV (Flash Video), whatever `ARCHIVE_SUFFIX` says. `ARCHIVE_SUFFIX` only sets the file extension. A file named `.mp4` is still FLV inside, and some players refuse it.

**Solution**: Set the extension to match the content in `env/relay.env`:

```bash
ARCHIVE_SUFFIX=flv
```

To convert an existing archive to a real MP4 file without re-encoding:

```bash
ffmpeg -i <ARCHIVE_FILE> -c copy <OUTPUT_FILE>.mp4
```

## Files Not Named as Expected

Archive files are named:

```text
<STREAM_NAME>-<UNIX_TIME>_<DDMMYYYY>_<HHMMSS>.<ARCHIVE_SUFFIX>
```

| Part | Meaning |
|---|---|
| `<STREAM_NAME>` | The stream key set in OBS, the part after `rtmp://<RELAY_IP>/relay/` |
| `<UNIX_TIME>` | When recording started, in seconds since 1970 |
| `<DDMMYYYY>_<HHMMSS>` | When recording started, day first, in **UTC** |
| `<ARCHIVE_SUFFIX>` | The `ARCHIVE_SUFFIX` value |

Example, a stream named `mystream` recorded at 13:16:49 UTC on 25 September 2026:

```text
mystream-1790342209_25092026_131649.mp4
```

Because the Unix time comes first, sorting files by name sorts each stream's recordings in the order they were recorded.

## Archive Grows Too Large

**Issue**: Disk filling up with old archives

List the recordings older than 30 days first:

```bash
find ./stream_archive -name "*.flv" -mtime +30 -print
```

If the list is what you expect to lose, delete them. This cannot be undone:

```bash
sudo find ./stream_archive -name "*.flv" -mtime +30 -delete
```

## Debug Logs

### View Archive Log Lines

For more detail, see [Increase Log Verbosity](../connection-issues.md#increase-log-verbosity).

```bash
# Archive-specific logs
docker compose logs relay | grep -i archive
```

### Common Log Messages

**Success messages**:
```text
Archive configuration complete, and service enabled.
```

**Service skipped** — the relay keeps running without this service:
```text
ARCHIVE_PATH is not set. Skipping Archive configuration.
```

**Invalid value** — the container stops. The last lines of `docker compose logs relay` name the variable to correct:
```text
ERROR: ARCHIVE_PATH must be an absolute path starting with /.
ERROR: ARCHIVE_PATH is not writable by the nginx user.
[!] pre-init.d - 90_configure_archive.sh failed. Stopping container.
```

## See Also

- **[Troubleshooting Overview](../index.md)** - Main troubleshooting guide
- **[Connection Issues](../connection-issues.md)** - Network and connectivity problems
- **[Archive Service](../../services/archive.md)** - Archive configuration details

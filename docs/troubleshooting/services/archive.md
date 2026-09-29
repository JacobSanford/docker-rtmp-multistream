---
title: Archive Not Recording, Won't Play, or Filling the Disk
description: Troubleshooting Archive-specific recording issues
audience: users
doc_type: howto
tags: [troubleshooting, archive, recording, storage]
lastReviewed: 2026-09-25
version: 1.x
---

# Archive Not Recording, Won't Play, or Filling the Disk

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
- No files appear in the archive directory, or
- The whole relay stops at startup with `ERROR: ARCHIVE_PATH is not writable by the nginx user.`: Twitch and YouTube stop too. See [Archive Folder Not Mounted or Not Writable](#archive-folder-not-mounted-or-not-writable)

### Possible Causes

#### Archive Not Enabled

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

#### Archive Folder Not Mounted or Not Writable

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

#### Disk Space

**Check**: Verify available space:

```bash
df -h ./stream_archive
```

**Solution**: Free up disk space or use a different directory with more space.

**Estimate space needed**:
- 1080p60 @ 20 Mbps: ~9 GB per hour
- 720p60 @ 6 Mbps: ~2.7 GB per hour
- 720p30 @ 3 Mbps: ~1.35 GB per hour

### Confirm the Fix

Stream for a minute, then list the archive folder. A new file is there and grows while you stream:

```bash
ls -l stream_archive
```

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

Replace `<ARCHIVE_FILE>` with the archive's file name and `<OUTPUT_FILE>` with a name for the copy. Confirm the copy by opening `<OUTPUT_FILE>.mp4` in your player.

## Files Not Named as Expected

The name is `<stream-name>-<unix-time>_<DDMMYYYY>_<HHMMSS>.<ARCHIVE_SUFFIX>`, with the date and time in UTC. See [File Naming](../../services/archive.md#file-naming) for an example and how to sort the files.

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

For the startup lines every service prints, and which ones mean the container stopped, see [Check Service Status](../index.md#check-service-status). For more detail while streaming, see [Increase Log Verbosity](../connection-issues.md#increase-log-verbosity).

## See Also

- **[Troubleshooting Overview](../index.md)** - Main troubleshooting guide
- **[Connection Issues](../connection-issues.md)** - Network and connectivity problems
- **[Archive Service](../../services/archive.md)** - Archive configuration details

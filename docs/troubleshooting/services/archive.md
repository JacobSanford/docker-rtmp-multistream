---
title: Archive Troubleshooting
description: Troubleshooting Archive-specific recording issues
audience: users
doc_type: howto
tags: [troubleshooting, archive, recording, storage]
lastReviewed: 2025-11-07
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

#### 2. Permission Denied

**Check**: Look for permission errors:

```bash
docker compose logs relay | grep -i "permission\|denied"
```

**Solution**: Fix directory permissions on host:
```bash
chown 100:101 ./stream_archive
chmod o+w ./stream_archive
```

**Why these IDs?** The nginx process runs as UID:GID 100:101 inside the container.

#### 3. Volume Not Mounted

**Check**: Verify volume is mapped:

```bash
docker compose exec relay ls -la /archive
```

**Solution**: Add volume to `docker-compose.yml`:
```yaml
volumes:
  - ./stream_archive:/archive
```

Then restart:
```bash
docker compose down
docker compose up
```

#### 4. Disk Space

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

**Check**: Verify archive format:

```bash
grep ARCHIVE_SUFFIX env/relay.env
```

**Solution**: Use compatible format:
```bash
ARCHIVE_SUFFIX=flv   # Most compatible with RTMP
# or
ARCHIVE_SUFFIX=mp4   # Better compatibility with players
```

**Note**: `flv` is most reliable for RTMP streams. `mp4` requires stream to complete cleanly.

## Files Not Named as Expected

**Issue**: Archive filenames are unclear

**Current behavior**: Files use timestamp-based naming.

**Solution**: Files are named automatically based on:
- Stream name from OBS
- Timestamp
- Suffix from `ARCHIVE_SUFFIX`

Example: `mystream_2025-10-21_143022.flv`

## Archive Grows Too Large

**Issue**: Disk filling up with old archives

**Solution**: Implement cleanup strategy:

```bash
# Manual cleanup of files older than 30 days
find ./stream_archive -name "*.flv" -mtime +30 -delete

# Or use logrotate/cron for automatic cleanup
```

## Debug Logs

### Enable Detailed Logging

For Archive-specific issues, check logs:

```bash
# Archive-specific logs
docker compose logs relay | grep -i archive
```

### Common Log Messages

**Success messages**:
```
Archive configured and enabled.
```

**Error messages**:
```
ERROR: ARCHIVE_PATH is not set
WARNING: /archive is not writable
```

## See Also

- **[Troubleshooting Overview](../index.md)** - Main troubleshooting guide
- **[Connection Issues](../connection-issues.md)** - Network and connectivity problems
- **[Archive Service](../../services/archive.md)** - Archive configuration details

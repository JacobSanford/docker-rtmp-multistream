---
title: Troubleshooting Guide
description: Diagnostic guide for common docker-rtmp-multistream issues
audience: users
doc_type: howto
tags: [troubleshooting, debugging, problems, diagnostics]
lastReviewed: 2025-10-21
version: 1.x
---

# Troubleshooting Guide

Quick diagnostic guide to identify and resolve common issues with docker-rtmp-multistream.

## Quick Diagnostics

Follow this flowchart to identify your issue:

```
Is the container running?
├─ NO → See [Connection Issues](connection-issues.md#container-wont-start)
└─ YES
   │
   Can you connect from OBS?
   ├─ NO → See [Connection Issues](connection-issues.md#cannot-connect-from-obs)
   └─ YES
      │
      Is the stream appearing on platforms?
      ├─ NO → See Service Issues: [Twitch](services/twitch.md#stream-not-appearing) | [YouTube](services/youtube.md#stream-not-appearing)
      └─ YES → Working correctly!
```

## Common Issues by Category

### Connection Problems
Can't connect to the relay or container won't start.

**Symptoms:**
- Container exits immediately
- OBS shows "Failed to connect to server"
- Port not accessible

**→ [Connection Issues Guide](connection-issues.md)**

### Service-Specific Problems
Stream works but doesn't appear on specific platforms, or archive not recording.

**Symptoms:**
- OBS shows streaming but nothing on Twitch/YouTube
- Archive directory empty
- Service configuration errors

**→ Service Troubleshooting:** [Twitch](services/twitch.md) | [YouTube](services/youtube.md) | [Archive](services/archive.md)

## General Debugging

### View Container Logs

```bash
# All logs
docker compose logs relay

# Follow logs in real-time
docker compose logs -f relay

# Last 100 lines
docker compose logs --tail=100 relay

# Filter for errors
docker compose logs relay | grep -i error
```

### Check Service Status

Verify which services are enabled:

```bash
docker compose logs relay | grep "configured and enabled"
```

Expected output:
```
Twitch configured and enabled.
YouTube configured and enabled.
```

### Test Configuration Syntax

```bash
docker compose exec relay nginx -t
```

Should show: `nginx: configuration file /etc/nginx/nginx.conf test is successful`

### Check Active Configuration

```bash
docker compose exec relay cat /etc/nginx/http.d/app.conf
```

Look for uncommented `include` directives for enabled services.

## Getting Help

If you're still experiencing issues:

1. **Check existing issues**: [GitHub Issues](https://github.com/JacobSanford/docker-rtmp-multistream/issues){target="_blank"}
2. **Gather information**:
   - Container logs: `docker compose logs relay > logs.txt`
   - Environment: `docker compose config > config.txt`
   - System info: `uname -a; docker --version`
3. **Open a new issue** with:
   - Clear description of the problem
   - Steps to reproduce
   - Logs and configuration (redact stream keys!)
   - System information

## See Also

- **[Architecture](../techref/architecture.md)** - Understand how the system works
- **[Quality Optimization](../performance/quality.md)** - Optimization guidance
- **[Configuration](../configuration.md)** - Setup details
- **[Security](../security.md)** - Access control and validation

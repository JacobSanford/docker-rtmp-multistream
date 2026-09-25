---
title: OBS Is Refused: access forbidden by rule
description: Fixing "access forbidden by rule" when OBS cannot publish
audience: users
doc_type: howto
tags: [troubleshooting, authentication, network, publish]
lastReviewed: 2026-09-25
version: 1.x
---

# OBS Is Refused: access forbidden by rule

## Overview
The default configuration relays Real-Time Messaging Protocol (RTMP) streams from all typical local and docker IPs (172.16.0.0/12,192.168.0.0/16). This restriction can be modified by setting the [PUBLISH_IP_RANGE](../techref/environment.md#system-variables) environment variable.

If this mask does not include the IP address of the machine you are streaming from, you will see access forbidden errors in the logs and publishing the stream from OBS to your relay will not be accepted.

## Symptoms
"access forbidden by rule" errors in the relay logs, e.g.:

```text
relay-1  | 2025/11/05 10:34:08 [error] 95#95: *42 access forbidden by rule, client: 172.22.0.1, server: 0.0.0.0:1935
```

## Solution

1. Find the address the relay refused. It's the `client:` value in the log line:

    ```bash
    docker compose logs relay | grep "access forbidden"
    ```

2. In `env/relay.env`, uncomment `PUBLISH_IP_RANGE` and add a range that includes that address. Keep the ranges you still need, because this value replaces the default. For a refused address of `10.0.0.25`:

    ```bash
    PUBLISH_IP_RANGE=10.0.0.0/24,172.16.0.0/12,192.168.0.0/16
    ```

3. Recreate the container so it reads the new value:

    ```bash
    docker compose up -d --force-recreate
    ```

4. Start streaming from OBS, then confirm that nothing was refused:

    ```bash
    docker compose logs relay | grep "access forbidden"
    ```

    No output means the connection was allowed.

## Choosing an Appropriate PUBLISH_IP_RANGE

### Connections From: WAN, Other Machines on LAN
The container typically detects the actual IP (e.g., 192.168.1.100). Choose a mask based on your actual network range.

### Connections From: The Same Machine

If OBS runs on the same machine as the relay, its connection reaches the relay from the Docker network's gateway address (for example `172.25.0.1`), not from `127.0.0.1`. The default range `172.16.0.0/12` allows it. If you set your own `PUBLISH_IP_RANGE`, keep `172.16.0.0/12` in the list.

## Example Ranges

Each value keeps `172.16.0.0/12` so OBS on the relay's own machine can still publish. Drop it only if nothing streams from that machine.

| Description                                  | PUBLISH_IP_RANGE Value             |
|----------------------------------------------|------------------------------------|
| Relay machine plus one other machine         | `172.16.0.0/12,192.168.1.100/32`   |
| Relay machine plus one subnet (192.168.1.x)  | `172.16.0.0/12,192.168.1.0/24`     |
| Relay machine plus a typical home network    | `172.16.0.0/12,192.168.0.0/16` (the default) |

!!! warning "Security Recommendation"
    Use the most restrictive mask that meets your needs. If you stream from one other machine, use `/32` for that machine's address.

## See Also

- [Security](../security.md) - Security features and best practices
- [Connection Issues](connection-issues.md) - Other connection problems
- [Change Relay Settings](../configuration.md) - Environment variable setup


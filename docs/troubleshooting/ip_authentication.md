# Troubleshooting: IP Authentication

## Overview
The default configuration relays RTMP from all typical local and docker IPs (172.17.0.0/16,192.168.0.0/16). This restriction can be modified by setting the [PUBLISH_IP_RANGE](../techref/environment.md#system-variables) environment variable.

If this mask does not include the IP address of the machine you are streaming from, you will see access forbidden errors in the logs and publishing the stream from OBS to your relay will not be accepted.

## Symptoms
"access forbidden by rule" errors in the relay logs, e.g.:

```
relay-1  | 2025/11/05 10:34:08 [error] 95#95: *42 access forbidden by rule, client: 172.22.0.1, server: 0.0.0.0:1935
```

## Solution
This error will provide you with the correct client IP address that was denied access. In the example above, the client's apparent IP is `172.22.0.1`. Setting the `PUBLISH_IP_RANGE` to a mask that include this IP address (e.g., `172.22.0.0/16`) will resolve the issue.

## Choosing an Appropriate PUBLISH_IP_RANGE
The streaming software's IP address detected by the _docker-rtmp-multistream_ container may differ from what you expect based on how you are connecting to it.

### Connections From: WAN, Other Machines on LAN
The container typically detects the actual IP (e.g., 192.168.1.100). Choose a mask based on your actual network range.

### Connections From: The Same Machine (Docker host, localhost)
When Docker creates containers, it generally uses a bridge network (usually named `docker0` or a custom bridge). This creates a virtual network interface that acts as a gateway between your host and containers.

In this case, the container typically detects the Gateway IP of the Docker bridge network. Choose a mask that includes the entire Docker bridge subnet (e.g., `172.22.0.0/16`).

## Example Ranges

| Description                         | PUBLISH_IP_RANGE Value               |
|-------------------------------------|--------------------------------------|
| Single specific machine only        | `192.168.1.100/32`                   |
| Specific subnet (e.g., 192.168.1.x) | `192.168.1.0/24`                     |
| Entire typical home network         | `192.168.0.0/16`                     |
| Allow Docker host + local network   | `172.17.0.0/16,192.168.0.0/16`       |

!!! warning "Security Recommendation"
    Use the most restrictive mask that meets your needs. If you only stream from one machine, use /32 for that single IP.

## See Also

- [Security](../security.md) - Security features and best practices
- [Connection Issues](connection-issues.md) - Other connection problems
- [Configuration Guide](../configuration.md) - Environment variable setup


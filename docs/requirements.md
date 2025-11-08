---
title: Requirements
description: System requirements and prerequisites for docker-rtmp-multistream
audience: users
doc_type: reference
tags: [requirements, prerequisites, docker, setup]
lastReviewed: 2025-10-21
version: 1.x
---

# Requirements

## Operating Systems

**Supported OS**: Linux is the only supported operating system. While it may be possible to deploy on OSX or Windows, it is not officially supported.


## Software Prerequisites

Ensure the following packages are installed and configured for the current user:

- **Docker**: Follow the [installation guide](https://docs.docker.com/install/){target="_blank"}.
- **Docker Compose**: Follow the [installation guide](https://docs.docker.com/compose/install/){target="_blank"}.


## Networking

### Network Access
The following network requirements must be met:

- **HTTP/HTTPS Requests**: Building the docker image requires outbound HTTP and HTTPS requests.
- **RTMP Requests**: Video is relayed through RTMP requests.

Your OS, network, or ISP must not block either type of request. If you use a proxy server to connect to the web, ensure it accommodates the above requirements.

### Bandwidth
Sufficient upload bandwidth is required to stream to multiple services simultaneously. See the [Bandwidth Requirements](performance/bandwidth.md) for details on bandwidth usage per service.

## See Also

- [Bandwidth Requirements](performance/bandwidth.md) - Network bandwidth considerations
- [Hardware Requirements](performance/hardware.md) - CPU and system resources
- [Quick Start Guide](quickstart.md) - Get up and running in 5 minutes

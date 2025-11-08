---
title: docker-rtmp-multistream Documentation
description: Lightweight nginx-based RTMP relay/encoder for simultaneous streaming to Twitch, YouTube, and local archive
audience: users
doc_type: landing
tags: [rtmp, streaming, nginx, docker, obs, twitch, youtube]
lastReviewed: 2025-10-21
version: 1.x
---

# docker-rtmp-multistream

[![CI](https://github.com/JacobSanford/docker-rtmp-multistream/actions/workflows/ci.yml/badge.svg)](https://github.com/JacobSanford/docker-rtmp-multistream/actions/workflows/ci.yml)

```docker-rtmp-multistream``` is a lightweight nginx-based RTMP relay/encoder. It is intended to complement traditional streaming software (OBS, etc.) by providing a single broadcast target that relays the stream simultaneously to multiple services, optionally archiving it to a local disk.

!!! info "Performance Note"
    This project works best if deployed on a dedicated PC that is separate from the one running your streaming software.

## Supported Streaming Services

* **Twitch**: [Advanced Twitch Configuration](services/twitch.md)
* **YouTube**: [Advanced YouTube Configuration](services/youtube.md)
* **Archive** (local disk): [Advanced Local Archive Configuration](services/archive.md)

Additional streaming services can be added. Please see the [Adding New Streaming Services](developer/adding-services/overview.md) documentation.

## Getting Started

New to docker-rtmp-multistream? Start here:

1. [Requirements](requirements.md) - Check prerequisites and system requirements
2. [Quick Start Guide](quickstart.md) - Get up and running quickly

## Issues

Please report any issues or bugs you encounter via the [GitHub Issues tab](https://github.com/JacobSanford/docker-rtmp-multistream/issues).

## Contributions

Contributions / Pull requests are welcome!

## License

This project is dual-licensed under the GNU Affero General Public License v3 (AGPLv3) and a commercial license. You may use, modify, and distribute the software under the terms of the AGPLv3, which requires sharing source code for network-accessible applications. If you prefer to use this software under different terms—for example, in proprietary or commercial products—a commercial license is available.

## See Also

- [Requirements](requirements.md) - Check prerequisites and system requirements
- [Quick Start Guide](quickstart.md) - Get up and running quickly
- [Services Overview](services/overview.md) - Supported streaming services

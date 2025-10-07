# docker-rtmp-multistream

[![CI](https://github.com/JacobSanford/docker-rtmp-multistream/actions/workflows/ci.yml/badge.svg)](https://github.com/JacobSanford/docker-rtmp-multistream/actions/workflows/ci.yml)

This is a lightweight nginx-based RTMP relay/encoder.

It is intended to complement traditional streaming software (OBS, etc.) by providing a single endpoint that relays the stream simultaneously to multiple services, and archives it to a local disk.

This project works best if deployed on a dedicated PC, separate from the one running your streaming software.

## Supported Streaming Services

* **Twitch**: [Advanced Twitch Configuration](services/twitch.md)
* **YouTube**: [Advanced YouTube Configuration](services/youtube.md)
* **Archive** (local disk): [Advanced Local Archive Configuration](services/archive.md)

New/Additional services can easily be added. Please see the [Adding New Services](developer/adding-services.md) documentation.

## Getting Started

New to docker-rtmp-multistream? Start here:

1. [Requirements](requirements.md) - Check prerequisites and system requirements
2. [Quick Start Guide](quickstart.md) - Get up and running in minutes

## Issues

Please report any issues or bugs you encounter by opening a new issue via the [Issues tab](https://github.com/JacobSanford/docker-rtmp-multistream/issues).

## Contributions

Contributions / Pull requests are welcome!

## License

MIT

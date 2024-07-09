<center><img src="thumbnail.png" alt="docker-rtmp-multistream" width="400"/></center>

# JacobSanford/docker-rtmp-multistream
This is a lightweight nginx-based RTMP relay/encoder.

It is intended to complement traditional streaming software (OBS, etc.) by providing a single endpoint that relays the stream simultaneously to multiple services, and archives it to a local disk.

This project is intended to be deployed on a dedicated PC, separate from the one running your streaming software.

[Prerequisites](docs/prerequisites.md) | [Quick Start Guide](docs/quickstart.md) | [Documentation](docs/README.md)

## Supported Streaming Services
* Twitch: [Advanced Twitch Configuration](docs/services/twitch.md)
* YouTube: [Advanced YouTube Configuration](docs/services/youtube.md)
* Archive (local disk): [Advanced Local Archive Configuration](docs/services/archive.md)

New/Additional services can easily be added. Please see the [Adding New Services](docs/services/new.md) documentation.

## Issues
Please report any issues or bugs you encounter by opening a new issue via the [Issues tab](https://github.com/JacobSanford/docker-rtmp-multistream/issues).

## Contributions
Contributions / Pull requests are welcome!

## License
MIT

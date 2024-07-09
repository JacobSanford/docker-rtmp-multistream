<center><img src="thumbnail.png" alt="docker-rtmp-multistream" width="400"/></center>

# JacobSanford/docker-rtmp-multistream
A lightweight nginx-based based RTMP relay/encoder for streaming simultaneously to multiple services, while also archiving the stream locally to disk. YouTube and Twitch are configured by default.

This project is intended to be deployed on a dedicated PC, separate from the one hosting your streaming software.

## Currently Supported Streaming Services
* Twitch: [Configure Twitch](docs/services/twitch.md)
* YouTube: [Configure YouTube](docs/services/youtube.md)
* Archive (local disk): [Configure Archive](docs/services/archive.md)

New/Additional services can easily be added. Please see the [Adding New Services](docs/services/new.md) documentation.

## Documentation / Quick Start Guide
For detailed instructions on setting up and deploying a basic relay, see the [Quick Start Guide](docs/quickstart.md). Complete documentation is available in the [docs](docs/README.md) directory.

## Issues
Please report any issues or bugs you encounter by opening a new issue via the [Issues tab](https://github.com/JacobSanford/docker-rtmp-multistream/issues).

## Contributions
Contributions / Pull requests are welcome!

## License
MIT

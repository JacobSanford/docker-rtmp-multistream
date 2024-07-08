<center><img src="thumbnail.png" alt="docker-rtmp-multistream" width="400"/></center>

# JacobSanford/docker-rtmp-multistream
A lightweight docker-based nginx based RTMP relay/encoder for streaming simultaneously to multiple services. YouTube and Twitch are configured by default.

## Requirements
### Operating System
- **Supported OS**: Linux is the officially supported operating system. While it may be possible to deploy on OSX or Windows, it is not officially supported.

### Networking

- **HTTP/HTTPS Requests**: Building the docker image requires outbound HTTP and HTTPS requests.
- **RTMP Requests**: Video is relayed through RTMP requests.

Both types of requests must not be blocked by your OS, network, or ISP. If you use a proxy server to connect to the web, ensure it accommodates the above requirements.

### Prerequisites
Ensure the following packages are installed and configured for the current user:

- **Docker**: Follow the [installation guide](https://docs.docker.com/install/).
- **Docker Compose**: Follow the [installation guide](https://docs.docker.com/compose/install/).

## Setup and Use
### Configuration

1. Navigate to the `env/relay.env` file.
2. Add your Twitch and YouTube keys.
3. Configure stream quality settings as needed.

### Starting the Service
Execute the following command in your terminal:

```
./start.sh
```

To shut down the service, use `CTRL-C`.

## OBS Setup
### Settings
#### Streaming
* ```Service```: Custom
* ```Server```: rtmp://192.168.2.22:1935/relay
  * Where 192.168.2.22 corresponds to the relay PC's actual IP address.
* ```Stream Key```: Enter an identifer for your stream. This key is used to identify your stream uniquely on the relay server. For example, `myStream`. It does (should?) not need to match your Twitch or YouTube stream keys.
* ```Use Authentication```: Unchecked.

#### Output
* ```Output Mode```: Advanced
* ```Encoder```: If you have a modern NVidia card, use NVIDIA NVENC H.264. Otherwise, use CPU encoding with x264.
* ```Rate Control```: CBR
* ```Bitrate```: 20000. Set the bitrate to as large as a value as possible allowed by your network/bandwidth. See below!
* ```Keyframe Interval```: 2

## Archiving
The relay can archive streams to disk. To enable this feature, set the `ARCHIVE_PATH` environment variable in the `env/relay.env` file. This is a path inside the docker container. For example: `/stream_archive`.

### Writing to Local Disk
As the archive path is inside the docker container, it will be deleted when the docker container is removed. To persist the files, a local path can be mounted as a volume in the docker container. In the `docker-compose.yml` file, add a volume to the relay service:

```
services:
  relay:
    build:
      context: .
    ports:
      - "1935:1935"
    env_file:
      - ./env/relay.env
    volumes:
      - ./stream_archive:/archive
```

### Permissions
The archive path must exist and be writable by the nginx user (id 100:101).

```
chown 100:101 ./stream_archive
```

## Further Considerations

- **Output Bitrate**: YouTube reprocesses every video it receives, including live streams. Result: streams that look fine at lower bitrates on platforms such as Twitch will appear distorted on YouTube after the stream is re-encoded. To ensure the best quality on YouTube, set the bitrate to the highest value your network's upload bandwidth can reasonably support.
- **CPU Requirements**: Encoding, especially for gaming streams, is CPU-intensive. Consider using a dedicated encoder PC.
- **Optimal Settings Guide**: For detailed settings recommendations, refer to NVidia's [Broadcasting Guide](https://www.nvidia.com/en-us/geforce/guides/broadcasting-guide/).

## License
MIT

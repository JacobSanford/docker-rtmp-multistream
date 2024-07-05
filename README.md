<center><img src="thumbnail.png" alt="docker-rtmp-multistream" width="400"/></center>

# JacobSanford/docker-rtmp-multistream
A lightweight docker-based nginx based RTMP relay/encoder for streaming simultaneously to multiple services. YouTube and Twitch are configured by default.

## Requirements
### Operating System
- **Supported OS**: Linux is the officially supported operating system. While it may be possible to deploy and develop on OSX, it is not officially supported.

### Networking

- **HTTP/HTTPS Requests**: The docker image build process requires outbound HTTP and HTTPS requests.
- **RTMP Requests**: Video is relayed through RTMP requests.

Both types of requests must not be blocked by your OS, network, or ISP. If you use a proxy server to connect to the web, ensure it accommodates the above requirements.

### Prerequisites
Ensure the following packages are installed and configured for the current user:

- **Docker**: Follow the [installation guide](https://docs.docker.com/install/).
- **Docker Compose**: Follow the [installation guide](https://docs.docker.com/compose/install/).

## Setup and Use
### Configuration

1. Navigate to the `env/nginx.env` file.
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
* ```Server```: rtmp://192.168.2.22:1935/live
  * Where 192.168.2.22 corresponds to the relay PC's actual IP address.

#### Output
* ```Output Mode```: Advanced
* ```Encoder```: If you have a modern NVidia card, use NVIDIA NVENC H.264. Otherwise, use CPU encoding with x264.
* ```Rate Control```: CBR
* ```Bitrate```: 20000. Set the bitrate to as large as a value as possible allowed by your network/bandwidth. See below!
* ```Keyframe Interval```: 2

## Further Considerations

- **Output Bitrate**: YouTube reprocesses every video it receives, including live streams. This means that streams which look fine at lower bitrates on platforms like Twitch might not look as good on YouTube after it re-encodes them. To ensure the best quality on YouTube, set the bitrate to the highest value your network bandwidth can support.
- **CPU Requirements**: Encoding, especially for gaming streams, is CPU-intensive. Consider using a dedicated encoder PC.
- **Optimal Settings Guide**: For detailed settings recommendations, refer to NVidia's [Broadcasting Guide](https://www.nvidia.com/en-us/geforce/guides/broadcasting-guide/).


## Author / Contributors
This application was created by the following humans:

<a href="https://github.com/JacobSanford"><img src="https://avatars.githubusercontent.com/u/244894?v=3" title="Jacob Sanford" width="128" height="128"></a>

## License
MIT

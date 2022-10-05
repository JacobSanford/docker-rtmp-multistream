# JacobSanford/docker-rtmp-multistream
A lightweight docker-based nginx based RTMP relay/encoder for streaming simultaneously to multiple services. YouTube and Twitch are configured by default.

## Requirements
### Operating System
Although this package can be likely deployed and developed on OSX, the only officially supported operating system is Linux.

### Networking
* The process of building the docker image makes outbound HTTP, HTTPS requests.
* Video is relayed via RTMP requests.

Both types of requests must not be blocked by your OS, network, or ISP. If you use a proxy server to connect to the web, ensure it accommodates the above requirements.

### Prerequisites
You must have the following packages installed and working for the current user:

* [docker](https://www.docker.com): Installation steps [are located here](https://docs.docker.com/install/).
* [docker-compose](https://docs.docker.com/compose/): Installation steps [are located here](https://docs.docker.com/compose/install/).

## Use
### Configuration
Add your Twitch and YouTube keys in the ```env/nginx.env``` file. A few stream quality values are also configurable there.

### Startup
```
./start.sh
```
That is it! Shut down the service with CTRL-C.

## OBS Setup Example (Gaming PC)
### Settings
#### Streaming
* ```Service```: Custom
* ```Server```: rtmp://192.168.2.22:1935/live
  * Where 192.168.2.22 corresponds to the relay PC's actual IP address.

#### Output
* ```Output Mode```: Advanced
* ```Encoder```: If you have a modern NVidia card, use NVIDIA NVENC H.264. Otherwise, use CPU encoding with x264.
* ```Rate Control```: CBR
* ```Bitrate```: 20000. Set the bitrate to as large as a value as possible allowed by your network/bandwidth. YouTube re-encodes all video that it receives, even for live streams. Video that may look acceptable at lower bitrates will not look good when re-encoded by YouTube.
* ```Keyframe Interval```: 2

## Further Considerations

* As with any encoder, CPU requirements are very high. If this package is intended to re-stream gaming from a PC, it should be deployed on a separate 'encoder' PC.
* If you get lost setting bitrates, resolutions, and framerates: NVidia produced an excellent [Broadcasting Guide](https://www.nvidia.com/en-us/geforce/guides/broadcasting-guide/) that prescribes optimal settings.

## Author / Contributors
This application was created by the following humans:

<a href="https://github.com/JacobSanford"><img src="https://avatars.githubusercontent.com/u/244894?v=3" title="Jacob Sanford" width="128" height="128"></a>

## License
MIT

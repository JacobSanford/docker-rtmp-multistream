# Quick Start Guide
This guide serves as a quick start for setting up the relay and streaming to Twitch and YouTube. For more detailed information, visit the [full documentation](README.md) page.

## 1. Configure Streams
### Twitch
Open your [Twitch dashboard](https://dashboard.twitch.tv) and click on 'Stream Manager' to configure your stream details.

### YouTube
Open your [YouTube dashboard](https://studio.youtube.com) and click on 'Go Live' to configure your stream details.

## 2. Relay PC Setup
1. ```git clone git@github.com:JacobSanford/docker-rtmp-multistream.git```
2. ```cd docker-rtmp-multistream```
3. Edit the `env/relay.env` file:
   1. Add your Twitch and YouTube keys.
   2. Configure stream quality settings as needed. For more information, see the specific documentation for [Twitch](services/twitch.md) and [Youtube](services/youtube.md), as well as [Quality Considerations](quality.md).
4. Execute ```./start.sh```

The relay is now ready to receive video from your streaming software. To shut down the service, use `CTRL-C`.

## 3. Gaming PC Setup
### a. When Using OBS Studio
#### Stream Settings
* ```Service```: Custom
* ```Server```: rtmp://192.168.2.22:1935/relay
  * Where 192.168.2.22 corresponds to the relay PC's actual IP address.
* ```Stream Key```: Enter an identifer for your stream. This key is only used to identify your stream on the relay server. For example, `myStream`. It is unrelated to and should not match your Twitch or YouTube stream keys.
* ```Use Authentication```: Unchecked.

#### Output Settings
* ```Output Mode```: Advanced
* ```Encoder```: If you have a modern NVidia card, use NVIDIA NVENC H.264. Otherwise, use CPU encoding with x264.
* ```Rate Control```: CBR
* ```Bitrate```: 20000. Set the bitrate to as large as a value as possible allowed by your network/bandwidth. See below!
* ```Keyframe Interval```: 2

#### Start Streaming!
Open OBS Studio and click `Start Streaming`. The relay will automatically forward your stream to Twitch and YouTube.

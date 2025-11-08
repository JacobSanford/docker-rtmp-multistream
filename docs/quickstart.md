---
title: Quick Start Guide
description: Get docker-rtmp-multistream up and running in 5 minutes
audience: users
doc_type: tutorial
tags: [quickstart, setup, getting-started, obs]
lastReviewed: 2025-10-21
version: 1.x
---

# QuickStart Guide

## Streaming Services Setup
First, log-in to your streaming service dashboards to start a new stream and obtain your stream keys.

### Twitch
Open your [Twitch dashboard](https://dashboard.twitch.tv){target="_blank"} and click on 'Stream Manager' to configure your stream details.

### YouTube
Open your [YouTube dashboard](https://studio.youtube.com){target="_blank"} and click on 'Go Live' to configure your stream details.

## Relay PC Setup
### Clone the Repository
Clone the application's GitHub repository and navigate to the project directory:

```bash
git clone https://github.com/JacobSanford/docker-rtmp-multistream.git
cd docker-rtmp-multistream
```

### Configure the Relay
3. Edit the `env/relay.env` file:
    1. Add your Twitch and YouTube keys.
    2. Configure stream quality settings as needed. For details:
        * [Twitch Configuration](services/twitch.md)
        * [YouTube Configuration](services/youtube.md)
        * [Configuration Guide](configuration.md)

!!! warning "Security Alert"
    This is a simple relay with no authentication!
    
    The default configuration relays RTMP from all typical local and docker IPs (172.17.0.0/16,192.168.0.0/16). This restriction can be modified by setting the [PUBLISH_IP_RANGE](techref/environment.md#system-variables) environment variable. Consider tightening the mask to only include trusted IPs on your network. Be extremely cautious if changing this setting to allow wider access.
    
    Never expose the relay directly to the public internet.

### Start the Relay
1. Execute ```./start.sh```

The relay is now ready to receive video from your streaming software. To shut down the service, use `CTRL-C`.

## Streaming PC Setup
This guide assumes you are using OBS Studio as your streaming software. Other software should have similar settings.

### Configure OBS Studio
Configure OBS Studio to stream directly to your relay instead of upstream. 

#### OBS / Settings / Stream Settings
* ```Service```: Custom
* ```Server```: `rtmp://<relay-ip>:1935/relay`
    * Replace `<relay-ip>` with your relay PC's actual IP address (e.g., `192.168.2.22`)
* ```Stream Key```: Any identifier for your stream (e.g., `myStream`)
    * This is **NOT** your Twitch/YouTube key - it only identifies your stream on the relay, and in logs.
* ```Use Authentication```: Unchecked.

#### OBS / Settings / Output Settings
* ```Output Mode```: Advanced
* ```Encoder```: If you have a modern NVidia card, use NVIDIA NVENC H.264. Otherwise, use CPU encoding with x264.
* ```Rate Control```: CBR
* ```Bitrate```: 20000. Set the bitrate to as large as a value as possible allowed by your network/bandwidth. See below!
* ```Keyframe Interval```: 2

### Start Streaming!
Within OBS Studio, click `Start Streaming`. OBS will send the stream to the relay, which will automatically forward your stream to Twitch and YouTube.

## See Also

- [Configuration Guide](configuration.md) - Detailed configuration options
- [Requirements](requirements.md) - System prerequisites and hardware needs
- [Troubleshooting](troubleshooting/index.md) - Common issues and solutions

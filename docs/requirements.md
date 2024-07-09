# Requirements
### Operating System
- **Supported OS**: Linux is the officially supported operating system. While it may be possible to deploy on OSX or Windows, it is not officially supported.

### Networking

- **HTTP/HTTPS Requests**: Building the docker image requires outbound HTTP and HTTPS requests.
- **RTMP Requests**: Video is relayed through RTMP requests.

Your OS, network, or ISP must not block either type of request. If you use a proxy server to connect to the web, ensure it accommodates the above requirements.

### Prerequisites
Ensure the following packages are installed and configured for the current user:

- **Docker**: Follow the [installation guide](https://docs.docker.com/install/).
- **Docker Compose**: Follow the [installation guide](https://docs.docker.com/compose/install/).

# Service : Archive
## Description
The relay can archive streams to disk. To enable this feature, set the `ARCHIVE_PATH` environment variable in the `env/relay.env` file. It should specify a path inside the docker container. For example: `/stream_archive`.

The archive path must exist and be writable by the nginx user (id 100:101).


## Configuration
The Archive service can be configured by setting the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `ARCHIVE_PATH` | Specifies the path within the container where the archive videos will be stored. Enabling this feature activates stream archiving. | `` |
| `ARCHIVE_SUFFIX` | Defines the file extension or format of the videos saved in the archive. | `flv` |

## Writing Persistently to Local Disk
As the videos will be archived from within the docker container, any streams archived will be deleted when the docker container is removed.

To avoid this, map a host directory to a container volume by adding a volume configuration for the relay service in `docker-compose.yml`.

For instance, to link the host machine's `./stream_archive` directory with the container's `/archive` directory, add a volume definition in your `docker-compose.yml` file:

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

Next, execute the command below on the host machine to set the appropriate permissions on the `./stream_archive` directory:

```
chown 100:101 ./stream_archive
chmod o+w ./stream_archive
```

# Adding New Services

This guide explains how to add support for new streaming services to docker-rtmp-multistream.

## Service Patterns

There are two architectural patterns for implementing services:

### Simple Relay Pattern

**Use case**: Services that accept streams in the format your streaming software provides (e.g., YouTube).

**How it works**: The incoming stream is forwarded directly to the destination without modification.

**Requirements**: Only requires an `apps/{service}.conf` file.

**Example**: YouTube service

### Transformer Pattern

**Use case**: Services requiring specific encoding settings, resolution changes, or bitrate adjustments (e.g., Twitch).

**How it works**: A two-stage pipeline where:
1. The stream is first transcoded/downscaled via FFmpeg (transformer)
2. The transformed stream is pushed to an internal RTMP application (app)
3. The app forwards to the destination service

**Requirements**: Both `transformers/{service}.conf` (FFmpeg pipeline) and `apps/{service}.conf` (destination application).

**Example**: Twitch service (Transformer Pattern)

## Implementation Steps

### 1. Create Configuration Files

Create the necessary nginx configuration files in the appropriate directories.

#### For Simple Relay

Create `build/conf/nginx/http.d/apps/{service}.conf`:

```nginx
application {service} {
    live on;
    push rtmp://{service-ingest-url}/{path}?streamkey={SERVICE_KEY};
}
```

**Example**: [YouTube App Configuration](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/conf/nginx/http.d/apps/youtube.conf)

#### For Transformer Pattern

Create both files:

**`build/conf/nginx/http.d/transformers/{service}.conf`**:
```nginx
exec ffmpeg -i rtmp://localhost/relay/$name
  -c:v {SERVICE_CODEC} -preset {SERVICE_PRESET}
  -b:v {calculated_bitrate} -c:a aac -b:a {SERVICE_AUDIO_BITRATE}
  -f flv rtmp://localhost/{service}/$name;
```

**`build/conf/nginx/http.d/apps/{service}.conf`**:
```nginx
application {service} {
    live on;
    push rtmp://{service-ingest-url}/{path}?streamkey={SERVICE_KEY};
}
```

**Examples**:
- [Twitch Transformer Configuration](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/conf/nginx/http.d/transformers/twitch.conf)
- [Twitch App Configuration](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/conf/nginx/http.d/apps/twitch.conf)

### 2. Define Environment Variables

Add environment variables to two locations:

#### Dockerfile

Add default values (initialize secrets as empty strings):

```dockerfile
ENV SERVICE_KEY=""
ENV SERVICE_ENDPOINT="default-endpoint"
ENV SERVICE_BITRATE="3000k"
```

**Example**: [Dockerfile environment variables](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/Dockerfile#L6-L14)

#### env/relay.env

Add user-configurable template:

```bash
# Service Name
SERVICE_KEY=
SERVICE_ENDPOINT=default-endpoint
SERVICE_BITRATE=3000k
```

**Example**: [relay.env template](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/env/relay.env#L4-L12)

### 3. Register in Main Configuration

Add include directives to `build/conf/nginx/http.d/app.conf` (commented out):

```nginx
# Service: {Service Name}
# include /etc/nginx/http.d/transformers/{service}.conf;
# include /etc/nginx/http.d/apps/{service}.conf;
```

**Example**: [app.conf includes](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/conf/nginx/http.d/app.conf#L19-L26)

### 4. Create Pre-init Script

Create `build/scripts/pre-init.d/90_configure_{service}.sh`:

```bash
#!/usr/bin/env bash

# Check if service should be enabled (required env vars present)
if [ -z "$SERVICE_KEY" ]; then
  echo "SERVICE_KEY not set. Disabling {service}."
  exit 0
fi

# Additional validation
if [ ! -f "/path/to/config.conf" ]; then
  echo "Error: Configuration file not found"
  exit 1
fi

# Replace placeholders in config files using sed
sed -i "s#{SERVICE_KEY}#$SERVICE_KEY#g" /path/to/config.conf
sed -i "s#{SERVICE_ENDPOINT}#$SERVICE_ENDPOINT#g" /path/to/config.conf

# Enable the service by uncommenting includes in app.conf
/scripts/enableService.sh {service}

echo "{Service} configured and enabled."
```

**Example**: [90_configure_twitch.sh](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/scripts/pre-init.d/90_configure_twitch.sh)

#### Make Script Executable

```bash
chmod +x build/scripts/pre-init.d/90_configure_{service}.sh
```

### 5. Test Your Implementation

Build and test the container:

```bash
# Build the image
docker build -t rtmp-multistream .

# Configure environment
echo "SERVICE_KEY=your-test-key" >> env/relay.env

# Start the service
docker compose up

# Send a test stream
ffmpeg -re -i test.mp4 -c copy -f flv rtmp://localhost/relay/test
```

Check logs for:
- Service configuration messages
- Connection to service ingest server
- Any error messages

## Script Execution Order

Pre-init scripts run in alphanumeric order:
1. `89_configure_app.sh` - Configures main app placeholders
2. `90_configure_{service}.sh` - Service-specific configuration

Later scripts can reference files configured by earlier scripts.

## The enableService.sh Utility

The `/scripts/enableService.sh` script uncomments service includes in `app.conf`:

```bash
/scripts/enableService.sh {service}
```

This activates the service by uncommenting:
```nginx
# include /etc/nginx/http.d/transformers/{service}.conf;
# include /etc/nginx/http.d/apps/{service}.conf;
```

## Best Practices

1. **Validate early**: Check for required environment variables at the start of pre-init scripts
2. **Fail gracefully**: Exit with code 0 if service shouldn't be enabled (missing optional vars)
3. **Escape properly**: Use proper quoting in sed commands to handle special characters
4. **Log clearly**: Echo meaningful messages for debugging
5. **Test thoroughly**: Test with minimal config, full config, and error conditions
6. **Document**: Add service documentation to `docs/services/{service}.md`

## See Also

- [Architecture Overview](../architecture.md) - Understanding relay and transformer patterns
- [Environment Variables Reference](environment.md) - Complete variable reference
- [Testing Guide](testing.md) - How to test your implementation

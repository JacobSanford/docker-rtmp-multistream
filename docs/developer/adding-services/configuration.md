---
title: Service Configuration
description: Step-by-step configuration implementation for new services
audience: developers
doc_type: howto
tags: [development, configuration, nginx, services]
lastReviewed: 2025-10-21
version: 1.x
---

# Service Configuration

This guide walks through the configuration steps needed to add a new streaming service to docker-rtmp-multistream.

## Choose a Service Pattern

Before you begin, choose the appropriate pattern for your service. See **[Service Patterns Reference](../../techref/service-patterns.md)** for a detailed comparison of Simple Relay and Transformer patterns.

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

**Example**: [YouTube App Configuration](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/conf/nginx/http.d/apps/youtube.conf){target="_blank"}

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
- [Twitch Transformer Configuration](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/conf/nginx/http.d/transformers/twitch.conf){target="_blank"}
- [Twitch App Configuration](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/conf/nginx/http.d/apps/twitch.conf){target="_blank"}

### 2. Define Environment Variables

Add environment variables to two locations:

#### Dockerfile

Add default values (initialize secrets as empty strings):

```dockerfile
ENV SERVICE_KEY=""
ENV SERVICE_ENDPOINT="default-endpoint"
ENV SERVICE_BITRATE="3000k"
```

**Example**: [Dockerfile environment variables](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/Dockerfile#L6-L14){target="_blank"}

#### env/relay.env

Add user-configurable template:

```bash
# Service Name
SERVICE_KEY=
SERVICE_ENDPOINT=default-endpoint
SERVICE_BITRATE=3000k
```

**Example**: [relay.env template](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/env/relay.env#L4-L12){target="_blank"}

### 3. Register in Main Configuration

Add include directives to `build/conf/nginx/http.d/app.conf` (commented out):

```nginx
# Service: {Service Name}
# include /etc/nginx/http.d/transformers/{service}.conf;
# include /etc/nginx/http.d/apps/{service}.conf;
```

**Example**: [app.conf includes](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/conf/nginx/http.d/app.conf#L19-L26){target="_blank"}

### 4. Create Pre-init Script

Create `build/scripts/pre-init.d/90_configure_{service}.sh`:

```bash
#!/usr/bin/env sh
set -e

# Source validation functions
. /scripts/validate_input.sh

# Check if service should be enabled (required env vars present)
if [ -z "$SERVICE_KEY" ]; then
  echo "SERVICE_KEY not set. Skipping {service} configuration."
  exit 0
fi

# Validate inputs
validate_stream_key "$SERVICE_KEY" "SERVICE_KEY" || exit 1

# Additional validation for other variables
# validate_identifier "$SERVICE_ENDPOINT" "SERVICE_ENDPOINT" || exit 1
# validate_bitrate "$SERVICE_BITRATE" "SERVICE_BITRATE" || exit 1

# Escape values for safe sed substitution
SERVICE_KEY_ESC=$(escape_for_sed "$SERVICE_KEY")

# Replace placeholders in config files using sed
sed -i "s|SERVICE_KEY|$SERVICE_KEY_ESC|g" "${NGINX_CONFD_DIR}/apps/{service}.conf"
# sed -i "s|SERVICE_ENDPOINT|$SERVICE_ENDPOINT|g" "${NGINX_CONFD_DIR}/apps/{service}.conf"

# If using transformer, configure transformer variables
# sed -i "s|SERVICE_CODEC|$SERVICE_CODEC|g" "${NGINX_CONFD_DIR}/transformers/{service}.conf"

# Enable the service by uncommenting includes in app.conf
/scripts/enableService.sh {service}

echo "{Service} configuration complete, and service enabled."
```

**Example**: [90_configure_youtube.sh](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/scripts/pre-init.d/90_configure_youtube.sh){target="_blank"}

#### Make Script Executable

```bash
chmod +x build/scripts/pre-init.d/90_configure_{service}.sh
```

## Configuration Best Practices

1. **Validate early**: Check for required environment variables at the start of pre-init scripts
2. **Use validation functions**: Always validate all inputs using functions from `validate_input.sh` to prevent injection attacks
3. **Fail gracefully**: Exit with code 0 if service shouldn't be enabled (missing optional vars), but exit with code 1 for validation errors
4. **Escape properly**: Use `escape_for_sed()` when substituting values with sed to handle special characters safely
5. **Log clearly**: Echo meaningful messages for debugging (e.g., "SERVICE configured and enabled")

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

## Next Steps

After completing the configuration, proceed to [Adding Service Tests](testing.md) to ensure your service works correctly and securely.

## See Also

- [Adding Services Overview](../adding-services/overview.md) - Complete guide overview
- [Adding Service Tests](testing.md) - Testing your service implementation
- [Architecture Overview](../../techref/architecture.md) - Understanding relay and transformer patterns
- [Environment Variables Reference](../../techref/environment.md) - Complete variable reference

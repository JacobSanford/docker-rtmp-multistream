---
title: Adding New Streaming Services
description: Guide for adding support for new streaming platforms
audience: developers
doc_type: howto
tags: [development, services, extending, customization]
lastReviewed: 2025-10-21
version: 1.x
---

# Adding New Streaming Services

This guide explains how to add support for new streaming services to docker-rtmp-multistream.

## Overview

Adding a new streaming service involves two main steps:

1. **[Service Configuration](configuration.md)** - Create nginx configs, environment variables, and pre-init scripts
2. **[Service Testing](testing.md)** - Add comprehensive automated tests

Both steps are required for a complete service implementation.

## Service Patterns

Before implementing a new service, choose the appropriate pattern. See **[Service Patterns Reference](../../techref/service-patterns.md)** for a detailed comparison of Simple Relay and Transformer patterns, including use cases, pros/cons, and examples.

## Quick Start

### 1. Configuration

Follow the [Service Configuration](configuration.md) guide to:

- Create nginx RTMP configuration files (`apps/` and optionally `transformers/`)
- Define environment variables in `Dockerfile` and `env/relay.env`
- Add commented includes to `app.conf`
- Create pre-init script (`90_configure_{service}.sh`)
- Make script executable

### 2. Testing

Follow the [Service Testing](testing.md) guide to:

- Add unit tests to `tests/02_unit_tests.sh` (service enablement, variable replacement, security)
- Add integration test to `tests/03_integration_tests.sh` (container startup)
- Add validation tests to `tests/00_validation_tests.sh` (if new validation functions added)
- Run all tests: `./tests/test.sh`
- Perform manual end-to-end testing

### 3. Documentation

Add service-specific documentation:

- Create `docs/services/{service}.md` with:
  - Overview and configuration variables
  - Quality settings and recommendations
  - Troubleshooting tips
- Update `mkdocs.yml` navigation to include your service

## Implementation Checklist

Use this checklist to track your progress:

### Configuration
- [ ] Created nginx config files (`apps/` and/or `transformers/`)
- [ ] Added environment variables to `Dockerfile`
- [ ] Added environment variables to `env/relay.env`
- [ ] Added commented includes to `app.conf`
- [ ] Created pre-init script with validation
- [ ] Made script executable (`chmod +x`)

### Testing
- [ ] Added 4-5 unit tests (enable, skip, variables, security, transformer if applicable)
- [ ] Added integration test (container startup)
- [ ] Added validation tests (if new functions added)
- [ ] All tests pass: `./tests/test.sh` exits with code 0
- [ ] Manual end-to-end testing completed

### Documentation
- [ ] Created service documentation page
- [ ] Updated navigation in `mkdocs.yml`
- [ ] Added to main README (if appropriate)

## Best Practices

1. **Validate early**: Check for required environment variables at the start of pre-init scripts
2. **Use validation functions**: Always validate inputs using `validate_input.sh` to prevent injection attacks
3. **Fail gracefully**: Exit with code 0 if service shouldn't be enabled, exit with code 1 for validation errors
4. **Escape properly**: Use `escape_for_sed()` when substituting values to handle special characters safely
5. **Log clearly**: Echo meaningful messages (e.g., "SERVICE configured and enabled")
6. **Test thoroughly**: Add tests to all relevant test suites
7. **Security first**: Always test that malicious inputs are rejected
8. **Document comprehensively**: Help users configure and troubleshoot your service

## Examples

Study existing service implementations:

### Simple Relay (YouTube)
- Config: [`apps/youtube.conf`](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/conf/nginx/http.d/apps/youtube.conf){target="_blank"}
- Script: [`90_configure_youtube.sh`](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/scripts/pre-init.d/90_configure_youtube.sh){target="_blank"}
- Docs: [YouTube Configuration](../../services/youtube.md)

### Transformer (Twitch)
- Transformer: [`transformers/twitch.conf`](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/conf/nginx/http.d/transformers/twitch.conf){target="_blank"}
- App: [`apps/twitch.conf`](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/conf/nginx/http.d/apps/twitch.conf){target="_blank"}
- Script: [`90_configure_twitch.sh`](https://github.com/JacobSanford/docker-rtmp-multistream/blob/1.x/build/scripts/pre-init.d/90_configure_twitch.sh){target="_blank"}
- Docs: [Twitch Configuration](../../services/twitch.md)

## Detailed Guides

- **[Service Configuration](configuration.md)** - Step-by-step configuration implementation
- **[Service Testing](testing.md)** - Comprehensive testing guide

## See Also

- [Architecture Overview](../../techref/architecture.md) - Understanding relay and transformer patterns
- [Environment Variables Reference](../../techref/environment.md) - Complete variable reference
- [Security](../../security.md) - Input validation and security features
- [Testing Guide](../testing.md) - General testing documentation

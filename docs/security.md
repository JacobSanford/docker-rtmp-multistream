---
title: Security
description: Security features, input validation, and access control for docker-rtmp-multistream
audience: users
doc_type: explanation
tags: [security, validation, authentication, safety]
lastReviewed: 2026-09-29
version: 1.x
---

# Security

This document describes the security features and considerations for docker-rtmp-multistream.

## Reporting Security Issues

If you discover a security vulnerability, please email the maintainer directly rather than opening a public issue.

## Input Validation

Every variable you set in `env/relay.env` is checked against a whitelist or a pattern before a startup script writes it into the nginx configuration. Stream keys, `TWITCH_ENDPOINT` and `ARCHIVE_PATH` are also escaped for `sed` with `escape_for_sed`.

`NGINX_CONFD_DIR`, `NGINX_APP_CONF_FILE` and `NGINX_RUN_USER` come from the base image. They are trusted and not validated.

If a value fails validation, its startup script exits with status 1, and `build/scripts/run.sh` stops the container before nginx starts. The container log names the variable, for example `ERROR: TWITCH_KEY contains invalid characters.`

### Validation Functions

The validation framework is implemented in `build/scripts/validate_input.sh` and includes:

#### `validate_stream_key(key, name)`
Validates stream keys (Twitch, YouTube) to prevent command injection.

**Allowed characters:** `a-z A-Z 0-9 . _ : -`

**Blocks:**
- Every character outside the allowed set, including spaces, `/`, and shell metacharacters such as `` ;|&$`()<>{}[] ``
- Newlines and null bytes
- More than 200 characters

An empty key is accepted, and the service is skipped.

**Usage:**
```bash
validate_stream_key "$TWITCH_KEY" "TWITCH_KEY" || exit 1
```

#### `validate_path(path, name)`
Validates the archive path.

**Requirements:**
- Must be an absolute path (start with `/`)

**Blocks:**
- Relative paths
- Spaces and tabs (nginx would split the path into several arguments)
- `..` path segments (`/tmp/../etc` is rejected; `/tmp/a..b` is accepted)
- The characters `` ; | & $ ` ( ) { } < > ``
- `#` (starts an nginx comment) and `'` or `"` (change how nginx reads the directive)
- Newlines and null bytes
- More than 500 characters

**Not blocked:** `[ ] * ? ~`

An empty path is accepted, and Archive is skipped.

**Usage:**
```bash
validate_path "$ARCHIVE_PATH" "ARCHIVE_PATH" || exit 1
```

#### `validate_ip_range(range, name)` and `validate_ip_ranges(ranges, name)`
Validate IP ranges in CIDR (Classless Inter-Domain Routing) notation for publish authorization. `validate_ip_ranges` splits a comma-separated list, trims spaces around each entry, and checks each one with `validate_ip_range`.

**Format:** `x.x.x.x/y`, where each `x` is 0–255 and `y` is 0–32. The prefix is required: for a single host, write `/32`.

**Examples:**
- Valid: `192.168.1.0/24`, `10.0.0.0/8`, `192.168.1.10/32`
- Invalid: `192.168.1.10` (no prefix), `192.168.1`, `999.1.1.1/8`, `10.0.0.0/33`, `not-an-ip`

**Usage:**
```bash
validate_ip_ranges "$PUBLISH_IP_RANGE" "PUBLISH_IP_RANGE" || exit 1
```

#### `validate_number(value, name, min, max)`
Validates numeric values with optional range constraints.

**Allowed:** Non-negative integers (`0` is accepted) of at most 9 digits. No decimals, no signs.

The 9-digit limit exists because a value too large for the shell's integer tests would otherwise pass the min and max checks.

**Usage:**
```bash
validate_number "$TWITCH_FPS" "TWITCH_FPS" 1 120 || exit 1
validate_number "$TWITCH_HEIGHT" "TWITCH_HEIGHT" 144 4320 || exit 1
```

#### `validate_identifier(value, name)`
Validates alphanumeric identifiers (codecs, presets, endpoints).

**Allowed characters:** `a-z A-Z 0-9 _ -`

**Blocks:**
- Spaces, periods, special characters
- More than 100 characters

This checks the characters only, not the value. A misspelled preset such as `mediun` passes validation and fails only when FFmpeg starts, at the first publish to Twitch.

**Usage:**
```bash
validate_identifier "$TWITCH_CODEC" "TWITCH_CODEC" || exit 1
validate_identifier "$TWITCH_X264_PRESET" "TWITCH_X264_PRESET" || exit 1
```

#### `validate_bitrate(value, name)`
Validates audio/video bitrate specifications.

**Allowed formats:**
- Numeric only: `160000`
- With k suffix: `160k` or `160K`

**Blocks:**
- Decimals: `160.5k`
- Wrong suffix: `160m`
- Spaces: `160 k`

There is no length limit.

**Usage:**
```bash
validate_bitrate "$TWITCH_AUDIO_BITRATE" "TWITCH_AUDIO_BITRATE" || exit 1
```

#### `validate_log_level(level, name)`
Validates nginx log level using whitelist approach.

**Allowed values:** `debug`, `info`, `notice`, `warn`, `error`, `crit`, `alert`, `emerg`

**Blocks:** Any other value (case-sensitive)

**Usage:**
```bash
validate_log_level "$NGINX_ERROR_LOG_LEVEL" "NGINX_ERROR_LOG_LEVEL" || exit 1
```

#### `validate_suffix(suffix, name)`
Validates file extensions for archive recordings.

**Allowed characters:** `a-z A-Z 0-9`

**Blocks:**
- Leading dots: `.mp4`
- Paths: `mp4/flv`
- Special characters: `mp4-flv`
- More than 10 characters

**Usage:**
```bash
validate_suffix "$ARCHIVE_SUFFIX" "ARCHIVE_SUFFIX" || exit 1
```

#### `validate_boolean(value, name)`
Validates on/off settings such as `TWITCH_PARTNER`.

**Allowed values:** `TRUE` or `FALSE`, in any case (`true`, `True` and `FALSE` are all accepted)

**Blocks:** Any other value, including `yes`, `1` and empty

**Usage:**
```bash
validate_boolean "$TWITCH_PARTNER" "TWITCH_PARTNER" || exit 1
```

#### `escape_for_sed(value)`
Escapes special characters for safe sed substitution.

**Escapes:** `\ | &`

**Returns:** Escaped string safe for use in sed commands

**Usage:**
```bash
SAFE_KEY=$(escape_for_sed "$TWITCH_KEY")
sed -i "s|TWITCH_KEY|$SAFE_KEY|g" config.conf
```

## Security Best Practices

### 1. Stream Keys
- **Never commit** stream keys to version control
- `env/relay.env` is tracked by git, and `.gitignore` does not exclude it. After adding keys, run `git update-index --skip-worktree env/relay.env` so a later `git commit -a` cannot publish them. See [Change Relay Settings](configuration.md).
- Keys reach the container as environment variables. Anyone who can run `docker inspect` on the container can read them, and they are written in plain text into the generated nginx config inside the container
- Rotate keys regularly

### 2. Network Security
- Restrict `PUBLISH_IP_RANGE` to trusted networks only
- The default, `172.16.0.0/12,192.168.0.0/16`, admits the Docker networks and typical home networks
- Use `/32` for single-host authorization
- `PUBLISH_IP_RANGE` controls publishing only. Anyone who can reach port 1935 can watch the stream: see [What Is Not Protected](#what-is-not-protected)

### 3. Log Level Configuration
- Production: Use `error` or `warn` (default: `error`)
- Troubleshooting: `info` or `debug`
- At `info` or more verbose, nginx logs the full push URL, including the stream key, when it starts relaying. Return to `error` afterwards, and remove keys before sharing logs

### 4. Archive Paths
- The path must be writable by the nginx user. If it is not, the container stops at startup with `ERROR: ARCHIVE_PATH is not writable by the nginx user.`
- Use a dedicated directory with appropriate permissions
- Monitor disk space. Archive writes every stream published to `relay` at its source bitrate, so a 6000 kbps stream uses about 2.7 GB per hour

### 5. Container Security
- Run with minimal privileges when possible
- A read-only root filesystem breaks startup: the startup scripts rewrite files under `NGINX_CONFD_DIR` in place with `sed -i` and `mv`
- Implement resource limits (CPU/memory)
- Keep base image updated

## What Is Not Protected

- **Playback is open.** `auth.conf` has `allow publish` and `deny publish` rules only, and no `play` rule. Anyone who can reach port 1935 can play `rtmp://<RELAY_HOST>/relay/<STREAM_NAME>`, and the transcoded Twitch stream at `/twitch/<STREAM_NAME>`. This was checked against a running container: with `PUBLISH_IP_RANGE=10.99.0.0/24`, a host outside that range was refused as a publisher but could play `relay/<STREAM_NAME>`.
- **The port is published on every host interface.** `docker-compose.yml` maps `1935:1935`. To limit it to one network, bind to an address, for example `"192.168.1.20:1935:1935"`, or block the port at a firewall in front of the host. Docker writes its own iptables rules for published ports, so host firewall tools such as `ufw` may not block them.
- **`127.0.0.1` can always publish.** `auth.conf` allows it whatever `PUBLISH_IP_RANGE` is set to.
- **The `twitch` application accepts publishes directly.** It includes `auth.conf`, so any address in `PUBLISH_IP_RANGE` can publish to `/twitch/<STREAM_NAME>` and send a stream to Twitch without going through the transcoder.

## Attack Vectors Mitigated

### Command Injection
**Risk:** Malicious environment variables containing shell commands

**Mitigation:**
- Every user-set variable validated before use
- Stream keys, identifiers, suffixes and booleans are whitelisted, so shell metacharacters such as `` ;|&$`()<>{}[] `` cannot appear in them
- Stream keys, `TWITCH_ENDPOINT` and `ARCHIVE_PATH` escaped before `sed` substitution
- A failing startup script stops the container before nginx starts (`build/scripts/run.sh`)

**Example blocked:**
```bash
TWITCH_KEY="key123;rm -rf /"  # Rejected by validate_stream_key()
```

### Configuration Injection
**Risk:** Newlines or control characters injecting malicious config directives

**Mitigation:**
- Stream keys and paths containing a newline or null byte are rejected
- Every other validator matches the whole value against a single-line pattern or a fixed list

**Example blocked:**
```bash
TWITCH_KEY=$'abc\ndef'  # Rejected (newline)
```

In `env/relay.env`, `\n` is a literal backslash and `n`, not a newline. A key written that way is rejected because `\` is outside the allowed characters.

### Path Traversal
**Risk:** Archive paths escaping intended directory structure

**Mitigation:**
- Only absolute paths accepted
- Relative paths rejected
- `..` path segments blocked
- Spaces and tabs rejected (nginx would split the path into several arguments)
- Path validation before writability check

**Example blocked:**
```bash
ARCHIVE_PATH="../../etc/passwd"  # Rejected (relative)
ARCHIVE_PATH="/tmp/../../../etc"  # Rejected (traversal)
```

### Length Limits
These are sanity limits on values that end up in nginx and FFmpeg configuration.

- Stream keys: 200 characters
- Paths: 500 characters
- Identifiers: 100 characters
- File extensions: 10 characters
- Numbers: 9 digits

Bitrates and IP ranges have no length limit. Each IP range must still match the `x.x.x.x/y` shape.

**Example blocked:**
```bash
TWITCH_KEY=$(printf 'a%.0s' {1..201})  # Rejected (too long)
```

## Testing

All validation functions are tested with test cases covering:
- Valid inputs (alphanumeric, special chars where allowed)
- Invalid inputs (injection attempts, traversal, length limits)
- Edge cases (empty, boundaries, special formats)

Run validation tests:
```bash
bash tests/00_validation_tests.sh
```

See `tests/README.md` for detailed test documentation.

## See Also

- [Change Relay Settings](configuration.md) - Environment variable configuration
- [Architecture](techref/architecture.md) - How configuration is processed
- [IP Authentication Troubleshooting](troubleshooting/ip_authentication.md) - Connection authorization issues

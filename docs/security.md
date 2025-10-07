# Security

This document describes the security features and considerations for docker-rtmp-multistream.

## Reporting Security Issues

If you discover a security vulnerability, please email the maintainer directly rather than opening a public issue.

## Input Validation

All environment variables are validated before being used in configuration files to prevent injection attacks and configuration tampering.

### Validation Functions

The validation framework is implemented in `build/scripts/validate_input.sh` and includes:

#### `validate_stream_key(key, name)`
Validates stream keys (Twitch, YouTube) to prevent command injection.

**Allowed characters:** `a-z A-Z 0-9 . _ : -`

**Blocks:**
- Shell metacharacters: `;|&$\`()<>{}[]`
- Path traversal: `../`
- Control characters: newlines, null bytes
- Excessive length: >200 characters

**Usage:**
```bash
validate_stream_key "$TWITCH_KEY" "TWITCH_KEY" || exit 1
```

#### `validate_path(path, name)`
Validates file system paths (archive paths) to prevent path traversal and command injection.

**Requirements:**
- Must be absolute path (start with `/`)

**Blocks:**
- Shell metacharacters: `;|&$\`()<>{}[]`
- Relative paths
- Control characters: newlines, null bytes
- Excessive length: >500 characters

**Usage:**
```bash
validate_path "$ARCHIVE_PATH" "ARCHIVE_PATH" || exit 1
```

#### `validate_ip_range(range, name)`
Validates IP ranges in CIDR notation for publish authorization.

**Format:** `x.x.x.x/y` where x is 0-255 and y is 0-32

**Examples:**
- Valid: `192.168.1.0/24`, `10.0.0.0/8`, `172.16.0.0/16`
- Invalid: `192.168.1`, `not-an-ip`, `192.168/16`

**Usage:**
```bash
validate_ip_range "$PUBLISH_IP_RANGE" "PUBLISH_IP_RANGE" || exit 1
```

#### `validate_number(value, name, min, max)`
Validates numeric values with optional range constraints.

**Allowed:** Positive integers only (no decimals, no negatives)

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
- Excessive length: >100 characters

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
- Excessive length: >10 characters

**Usage:**
```bash
validate_suffix "$ARCHIVE_SUFFIX" "ARCHIVE_SUFFIX" || exit 1
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
- Store keys in `env/relay.env` (gitignored)
- Use Docker secrets for production deployments
- Rotate keys regularly

### 2. Network Security
- Restrict `PUBLISH_IP_RANGE` to trusted networks only
- Default `192.168.0.0/16` is suitable for home networks
- Use `/32` for single-host authorization
- Consider VPN/firewall rules for additional protection

### 3. Log Level Configuration
- Production: Use `error` or `warn` (default: `error`)
- Development: Use `debug` for troubleshooting
- **Never** use `debug` in production (may expose stream keys)

### 4. Archive Paths
- Ensure archive paths are writable by nginx user
- Use dedicated directory with appropriate permissions
- Monitor disk space to prevent exhaustion
- Implement log rotation if storing long-term

### 5. Container Security
- Run with minimal privileges when possible
- Use read-only filesystem where applicable
- Implement resource limits (CPU/memory)
- Keep base image updated

## Attack Vectors Mitigated

### Command Injection
**Risk:** Malicious environment variables containing shell commands

**Mitigation:**
- All inputs validated before use
- Shell metacharacters blocked: `;|&$\`()<>{}[]`
- Values escaped before sed substitution
- Scripts use `set -e` for fail-fast behavior

**Example blocked:**
```bash
TWITCH_KEY="key123;rm -rf /"  # Rejected by validate_stream_key()
```

### Configuration Injection
**Risk:** Newlines or control characters injecting malicious config directives

**Mitigation:**
- Newlines and null bytes detected and rejected
- Single-line validation for all inputs
- No multi-line environment variables accepted

**Example blocked:**
```bash
TWITCH_KEY="key\ninclude malicious.conf"  # Rejected
```

### Path Traversal
**Risk:** Archive paths escaping intended directory structure

**Mitigation:**
- Only absolute paths accepted
- Relative paths rejected
- `../` sequences blocked
- Path validation before writability check

**Example blocked:**
```bash
ARCHIVE_PATH="../../etc/passwd"  # Rejected (relative)
ARCHIVE_PATH="/tmp/../../../etc"  # Rejected (traversal)
```

### Buffer Overflow
**Risk:** Excessively long inputs causing buffer overflows

**Mitigation:**
- Length limits on all inputs
- Stream keys: 200 chars max
- Paths: 500 chars max
- Identifiers: 100 chars max
- File extensions: 10 chars max

**Example blocked:**
```bash
TWITCH_KEY=$(printf 'a%.0s' {1..201})  # Rejected (too long)
```

## Testing

All validation functions are tested with 113 comprehensive test cases covering:
- Valid inputs (alphanumeric, special chars where allowed)
- Invalid inputs (injection attempts, traversal, length limits)
- Edge cases (empty, boundaries, special formats)

Run validation tests:
```bash
bash tests/00_validation_tests.sh
```

See `tests/README.md` for detailed test documentation.

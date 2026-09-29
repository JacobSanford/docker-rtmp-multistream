---
title: Input Validation Reference
description: Every validation function in validate_input.sh, what it accepts and rejects, and which variables use it
audience: developers
doc_type: reference
tags: [security, validation, development]
lastReviewed: 2026-09-29
version: 1.x
---

# Input Validation Reference

This page lists the validation functions in `build/scripts/validate_input.sh` and the variables each one checks. It is written by hand from that file: update it when you change a validator. For what validation does and does not protect against, see [Security](../security.md).

The startup scripts in `build/scripts/pre-init.d/` check every variable you set in `env/relay.env` against a whitelist or a pattern before writing it into the nginx configuration. Stream keys, `TWITCH_ENDPOINT` and `ARCHIVE_PATH` are also escaped for `sed` with `escape_for_sed`.

`NGINX_CONFD_DIR`, `NGINX_APP_CONF_FILE` and `NGINX_RUN_USER` come from the base image. They are trusted and not validated.

If a value fails validation, its startup script exits with status 1, and `build/scripts/run.sh` stops the container before nginx starts. The container log names the variable, for example `ERROR: TWITCH_KEY contains invalid characters.`

## Variables and Their Validators

| Variable | Function | Script |
|---|---|---|
| `PUBLISH_IP_RANGE` | `validate_ip_ranges` | `89_configure_app.sh` |
| `NGINX_ERROR_LOG_LEVEL` | `validate_log_level` | `89_configure_app.sh` |
| `ARCHIVE_PATH` | `validate_path` | `90_configure_archive.sh` |
| `TWITCH_KEY`, `YOUTUBE_KEY` | `validate_stream_key` | `90_configure_twitch.sh`, `90_configure_youtube.sh` |
| `TWITCH_PARTNER` | `validate_boolean` | `90_configure_twitch.sh` |
| `TWITCH_ENDPOINT`, `TWITCH_CODEC`, `TWITCH_X264_PRESET` | `validate_identifier` | `90_configure_twitch.sh` |
| `TWITCH_FPS` (1–120), `TWITCH_HEIGHT` (144–4320), `TWITCH_KBITS_PER_VIDEO_FRAME` (1–1000), `TWITCH_FFMPEG_THREADS` (0–64), `TWITCH_AUDIO_CHANNELS` (1–2) | `validate_number` | `90_configure_twitch.sh` |
| `TWITCH_AUDIO_BITRATE` | `validate_bitrate` | `90_configure_twitch.sh` |

The Twitch encoder variables are validated only in non-partner mode. A new service must validate each of its variables the same way: see [Add a Streaming Service](adding-services/overview.md).

## Validation Functions

The validation framework is implemented in `build/scripts/validate_input.sh` and includes:

### `validate_stream_key(key, name)`
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

### `validate_path(path, name)`
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

### `validate_ip_range(range, name)` and `validate_ip_ranges(ranges, name)`
Validate IP ranges in CIDR (Classless Inter-Domain Routing) notation for publish authorization. `validate_ip_ranges` splits a comma-separated list, trims spaces around each entry, and checks each one with `validate_ip_range`.

**Format:** `x.x.x.x/y`, where each `x` is 0–255 and `y` is 0–32. The prefix is required: for a single host, write `/32`.

**Examples:**
- Valid: `192.168.1.0/24`, `10.0.0.0/8`, `192.168.1.10/32`
- Invalid: `192.168.1.10` (no prefix), `192.168.1`, `999.1.1.1/8`, `10.0.0.0/33`, `not-an-ip`

**Usage:**
```bash
validate_ip_ranges "$PUBLISH_IP_RANGE" "PUBLISH_IP_RANGE" || exit 1
```

### `validate_number(value, name, min, max)`
Validates numeric values with optional range constraints.

**Allowed:** Non-negative integers (`0` is accepted) of at most 9 digits. No decimals, no signs.

The 9-digit limit exists because a value too large for the shell's integer tests would otherwise pass the min and max checks.

**Usage:**
```bash
validate_number "$TWITCH_FPS" "TWITCH_FPS" 1 120 || exit 1
validate_number "$TWITCH_HEIGHT" "TWITCH_HEIGHT" 144 4320 || exit 1
```

### `validate_identifier(value, name)`
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

### `validate_bitrate(value, name)`
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

### `validate_log_level(level, name)`
Validates nginx log level using whitelist approach.

**Allowed values:** `debug`, `info`, `notice`, `warn`, `error`, `crit`, `alert`, `emerg`

**Blocks:** Any other value (case-sensitive)

**Usage:**
```bash
validate_log_level "$NGINX_ERROR_LOG_LEVEL" "NGINX_ERROR_LOG_LEVEL" || exit 1
```

### `validate_boolean(value, name)`
Validates on/off settings such as `TWITCH_PARTNER`.

**Allowed values:** `TRUE` or `FALSE`, in any case (`true`, `True` and `FALSE` are all accepted)

**Blocks:** Any other value, including `yes`, `1` and empty

**Usage:**
```bash
validate_boolean "$TWITCH_PARTNER" "TWITCH_PARTNER" || exit 1
```

### `escape_for_sed(value)`
Escapes special characters for safe sed substitution.

**Escapes:** `\ | &`

**Returns:** Escaped string safe for use in sed commands

**Usage:**
```bash
SAFE_KEY=$(escape_for_sed "$TWITCH_KEY")
sed -i "s|TWITCH_KEY|$SAFE_KEY|g" config.conf
```

## Attack Vectors Mitigated

### Command Injection
**Risk:** Malicious environment variables containing shell commands

**Mitigation:**
- Every user-set variable validated before use
- Stream keys, identifiers and booleans are whitelisted, so shell metacharacters such as `` ;|&$`()<>{}[] `` cannot appear in them
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

- [Security](../security.md) - What the relay protects against, and what it does not
- [Run the Tests](testing.md) - Running the test suites
- [Add a Streaming Service](adding-services/overview.md) - Validating a new service's variables

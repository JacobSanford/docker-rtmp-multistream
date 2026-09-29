---
title: Service Contract Reference
description: The rules a service's config files, include lines and startup script must follow
audience: developers
doc_type: reference
tags: [development, configuration, nginx, services]
lastReviewed: 2026-09-29
version: 1.x
---

# Service Contract Reference

This page lists the rules a service's files must follow. Break an include or naming rule and `enableService.sh` stops the container at startup with an `ERROR:` line. Break a placeholder or auth rule and the container starts but the service misbehaves. For the steps, see [Add a Streaming Service](overview.md).

In the examples, `<SERVICE>` is the lowercase service name, such as `youtube`.

## Files

| File | Pattern | Contents | Included from |
|---|---|---|---|
| `build/conf/nginx/http.d/apps/<SERVICE>.conf` | Simple Relay | Directives only (`include http.d/auth.conf;`, `push ...;`) | Inside `application relay` |
| `build/conf/nginx/http.d/apps/<SERVICE>.conf` | Transformer | One `application <SERVICE> { ... }` block that pushes to the service | Server level, after `application relay` |
| `build/conf/nginx/http.d/transformers/<SERVICE>.conf` | Transformer | One `exec ffmpeg ...;` directive that publishes to `rtmp://127.0.0.1/<SERVICE>/$name` | Inside `application relay` |
| `build/scripts/pre-init.d/90_configure_<SERVICE>.sh` | Both | Startup script, executable | Run by `build/scripts/run.sh` |

Real examples: `apps/youtube.conf` (Simple Relay), and `transformers/twitch.conf` with `apps/twitch.conf` (Transformer).

Every `application` block must contain `include http.d/auth.conf;`. An application without it accepts a publish from any address.

## Include Markers

`build/conf/nginx/http.d/app.conf` ships every service include commented out:

```nginx
#include NGINX_CONFD_DIR/apps/<SERVICE>.conf;
#include NGINX_CONFD_DIR/transformers/<SERVICE>.conf;
```

- Write `#include` with no space. `enableService.sh` matches `#include <PATH>;` exactly. With `# include`, with a space, it finds no line to enable and stops the container with `ERROR: No '#include <PATH>;' line in /etc/nginx/http.d/app.conf. Cannot enable <SERVICE>.`
- Keep the literal token `NGINX_CONFD_DIR`. `89_configure_app.sh` replaces it with `/etc/nginx/http.d` before any `90_` script runs, and `enableService.sh` matches the replaced path.
- Put each line where the [Files](#files) table says it is included from.

## Placeholder Tokens

- A placeholder is a bare uppercase word, named after its variable: `EXAMPLE_KEY`, not `{EXAMPLE_KEY}`. `sed` replaces the word and leaves any braces around it.
- `sed` replaces every occurrence, including inside a longer token. If one token contains another, substitute the longer one first. `90_configure_twitch.sh` substitutes `TWITCH_DOUBLE_FPS` before `TWITCH_FPS` for this reason.
- Values derived from variables, such as a bitrate, are computed in the startup script and substituted like any other token. See `TWITCH_VIDEO_BITRATE` in `90_configure_twitch.sh`.
- Escape free-form values, such as stream keys, host names and paths, with `escape_for_sed` before substituting them. Whitelisted values, such as numbers and identifiers, need no escaping.

## Startup Script

`build/scripts/run.sh` runs every `/scripts/pre-init.d/*sh` in glob (alphanumeric) order, then starts nginx.

| Rule | Why |
|---|---|
| Name it `90_configure_<SERVICE>.sh`, so it sorts after `89_configure_app.sh` | It must run after `89_` has replaced `NGINX_CONFD_DIR` in `app.conf`. Before that, the include marker does not match and `enableService.sh` stops the container |
| Start with `set -e` and source `/scripts/validate_input.sh` | Any failing command stops the script |
| If the required variable is empty, print `<VARIABLE> is not set. Skipping <Service> configuration.` and exit 0 | The service is optional. Docs and tests grep for `is not set` |
| Validate every variable before using it, and exit 1 on failure | A non-zero exit makes `run.sh` stop the container, so a bad value never reaches nginx |
| Call `/scripts/enableService.sh <SERVICE>` last, then print `<Service> configuration complete, and service enabled.` | Docs and tests grep for `service enabled` |

Variables from the base image are available to every script: `NGINX_CONFD_DIR` (`/etc/nginx/http.d`), `NGINX_APP_CONF_FILE` (`/etc/nginx/http.d/app.conf`) and `NGINX_RUN_USER` (`nginx`).

## enableService.sh

`/scripts/enableService.sh <SERVICE>`:

1. Exits 1 if no argument is given, or if `apps/<SERVICE>.conf` does not exist: `ERROR: /etc/nginx/http.d/apps/<SERVICE>.conf not found. Cannot enable <SERVICE>.` A misspelled `<SERVICE>` fails this way.
2. Removes the `#` from `#include /etc/nginx/http.d/apps/<SERVICE>.conf;` in `app.conf`, then exits 1 if `app.conf` has no active `include` line for that file.
3. If `transformers/<SERVICE>.conf` exists, does the same for its include line.

The startup scripts run with `set -e`, so any of these failures stops the script, and `run.sh` stops the container before nginx starts.

The argument must equal the app file's base name. Twitch partner mode uses this rule: `enableService.sh twitch-partner` enables `apps/twitch-partner.conf`.

## See Also

- [Add a Streaming Service](overview.md) - Step-by-step guide
- [Test a New Service](testing.md) - Tests to add for a new service
- [Input Validation Reference](../validation.md) - Validation functions and what they reject
- [Architecture](../../techref/architecture.md) - How the relay processes configuration

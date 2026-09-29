---
title: Change Relay Settings
description: Edit a relay setting in env/relay.env, apply it, and confirm it took effect
audience: users
doc_type: howto
tags: [configuration, environment-variables, setup]
lastReviewed: 2026-09-25
version: 1.x
---

# Change Relay Settings

Every relay setting is an environment variable in `env/relay.env`. The container reads the file only when it is created, so a change takes effect after you recreate the container.

For every variable, its default and its valid values, see the [Environment Variables Reference](techref/environment.md).

`env/relay.env` is your own copy of `env/relay.env.example`, and `.gitignore` excludes it, so your stream keys cannot be committed and `git pull` never changes the file. If you have not created it yet:

```bash
cp env/relay.env.example env/relay.env
```

Without it, `docker compose` stops with `env file …/env/relay.env not found`.

The file only needs the values you change. Any variable that is commented out or missing uses the image's default, so a new variable in a later release needs no edit to your file.

## Change a Setting

1. In `env/relay.env`, set the variable and save the file. For example, to lower the Twitch resolution:

    ```bash
    TWITCH_HEIGHT=540
    ```

    Write one `NAME=value` per line, with no spaces around `=` and no quotes. A variable that is commented out, or missing from the file, uses its default.

2. Recreate the container so it reads the new values:

    ```bash
    docker compose up -d --force-recreate
    ```

3. Confirm the container is running and each service is enabled:

    ```bash
    docker compose ps relay
    docker compose logs relay | grep -E "service enabled|Skipping|ERROR"
    ```

    The status is `Up`, and each service you configured prints `… configuration complete, and service enabled.`

    If you see an `ERROR:` line, the value was rejected and the container stopped. The line names the variable. Correct it and repeat from step 2, or undo your edit to get the relay back. See [Invalid Environment Value](troubleshooting/connection-issues.md#invalid-environment-value).

## What Turns Each Service On

| Service | Enabled when | Setup guide |
|---|---|---|
| Twitch | `TWITCH_KEY` is set | [Stream to Twitch](services/twitch.md) |
| YouTube | `YOUTUBE_KEY` is set | [Stream to YouTube](services/youtube.md) |
| Archive | `ARCHIVE_PATH` is set to an absolute path inside the container that the nginx user can write to. An unwritable or invalid path stops the container. | [Archive Streams to Disk](services/archive.md) |

`PUBLISH_IP_RANGE` controls which addresses may send a stream to the relay; see [OBS Is Refused](troubleshooting/ip_authentication.md). `NGINX_ERROR_LOG_LEVEL` controls how much the relay logs; see [Increase Log Verbosity](troubleshooting/connection-issues.md#increase-log-verbosity).

## Upgrade From a Tracked `env/relay.env`

Clones made before `env/relay.env.example` was added track `env/relay.env` itself. If `git pull` stops with `Your local changes to the following files would be overwritten by merge: env/relay.env`, move your file aside, pull, then put it back:

```bash
cp env/relay.env ~/relay.env.mine
git update-index --no-skip-worktree env/relay.env
git checkout -- env/relay.env
git pull
mv ~/relay.env.mine env/relay.env
```

`git status` no longer lists `env/relay.env`, and your settings are unchanged. The `--no-skip-worktree` line undoes the workaround that older versions of this page recommended, and does nothing if you never ran it.

## See Also

- [Environment Variables Reference](techref/environment.md) - Every variable, its default and valid values
- [Architecture](techref/architecture.md) - How configuration is processed internally
- [Quick Start](quickstart.md) - First-time setup

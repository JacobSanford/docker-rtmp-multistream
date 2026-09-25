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

!!! warning "`env/relay.env` is tracked by git"
    The file ships with the repository, and `.gitignore` does not exclude it. After you add stream keys, run this once so git stops tracking your edits and a later `git commit -a` cannot publish them:

    ```bash
    git update-index --skip-worktree env/relay.env
    ```

    If a later `git pull` stops with `Your local changes to the following files would be overwritten by merge: env/relay.env`, the file changed upstream. Save your copy, take the new version, then put your keys back:

    ```bash
    cp env/relay.env ~/relay.env.mine
    git update-index --no-skip-worktree env/relay.env
    git checkout -- env/relay.env
    git pull
    ```

    Copy your keys from `~/relay.env.mine` into the new `env/relay.env`, run the `--skip-worktree` command again, then delete `~/relay.env.mine`.

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

    If you see an `ERROR:` line, the value was rejected and the container stopped. The line names the variable. Correct it and repeat from step 2, or undo your edit to get the relay back. See [Invalid Environment Value](troubleshooting/connection-issues.md#1-invalid-environment-value).

## What Turns Each Service On

| Service | Enabled when | Setup guide |
|---|---|---|
| Twitch | `TWITCH_KEY` is set | [Stream to Twitch](services/twitch.md) |
| YouTube | `YOUTUBE_KEY` is set | [Stream to YouTube](services/youtube.md) |
| Archive | `ARCHIVE_PATH` is set to an absolute path inside the container that the nginx user can write to. An unwritable or invalid path stops the container. | [Archive Streams to Disk](services/archive.md) |

`PUBLISH_IP_RANGE` controls which addresses may send a stream to the relay; see [OBS Is Refused](troubleshooting/ip_authentication.md). `NGINX_ERROR_LOG_LEVEL` controls how much the relay logs; see [Increase Log Verbosity](troubleshooting/connection-issues.md#increase-log-verbosity).

## See Also

- [Environment Variables Reference](techref/environment.md) - Every variable, its default and valid values
- [Architecture](techref/architecture.md) - How configuration is processed internally
- [Quick Start](quickstart.md) - First-time setup

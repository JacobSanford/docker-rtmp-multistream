#!/usr/bin/env bash
docker compose rm -v --stop --force

set -e
docker compose build
docker compose up

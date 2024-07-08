#!/usr/bin/env bash
docker compose rm -v --stop --force
docker pull ghcr.io/jacobsanford/rtmp-multistream:1.x

set -e
docker compose build
docker compose up

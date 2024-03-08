#!/usr/bin/env bash
docker compose rm -v --stop --force
docker pull ghcr.io/unb-libraries/nginx:3.x
docker compose build
docker compose up

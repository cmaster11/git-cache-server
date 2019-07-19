#!/usr/bin/env bash
set -Eeuxmo pipefail
DIR="$(dirname "$(command -v greadlink >/dev/null 2>&1 && greadlink -f "$0" || readlink -f "$0")")"

# --- Config
IMAGE_NAME="git-cache-server"

# ---
VERSION=$(git describe --tags 2>/dev/null || echo 'master')

docker build -t "$IMAGE_NAME:$VERSION" "$DIR"
docker run --rm -it -p 8098:80 --env GIT_MASTER_URL="https://github.com/cmaster11/alpine-util" --env GIT_SIBLING_URL="http://192.168.1.108:8099/alpine-util.git" "$IMAGE_NAME:$VERSION"
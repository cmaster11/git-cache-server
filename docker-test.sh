#!/usr/bin/env bash
set -Eeuxmo pipefail
DIR="$(dirname "$(command -v greadlink >/dev/null 2>&1 && greadlink -f "$0" || readlink -f "$0")")"

# --- Config
IMAGE_NAME="git-cache-server"

# ---
VERSION=$(git describe --tags 2>/dev/null || echo 'master')

docker build -t "$IMAGE_NAME:$VERSION" "$DIR"

docker run --rm -it -p 8099:80 \
  --env GIT_REPO_NAME="cmaster11/alpine-util" \
  --env GIT_MASTER_HOST="github.com" \
  "$IMAGE_NAME:$VERSION"
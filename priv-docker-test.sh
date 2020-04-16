#!/usr/bin/env bash
set -Eeumo pipefail
DIR="$(dirname "$(command -v greadlink >/dev/null 2>&1 && greadlink -f "$0" || readlink -f "$0")")"

# --- Config
IMAGE_NAME="git-cache-server"

# ---
VERSION=$(git describe --tags 2>/dev/null || echo 'master')

docker build -t "$IMAGE_NAME:$VERSION" "$DIR"

GIT_MASTER_SSH_KEY_CONTENT=$(cat "$HOME/.ssh/gogs")
docker run --rm -it -p 8099:80 \
  --env GIT_REPO_NAME="n17/n17-config-local" \
  --env GIT_MASTER_HOST="gogs-ssh.n17-util.notify17.net" \
  --env GIT_MASTER_PROTOCOL="ssh" \
  --env GIT_MASTER_SSH_KEY_CONTENT="$GIT_MASTER_SSH_KEY_CONTENT" \
  "$IMAGE_NAME:$VERSION"
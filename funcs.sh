#!/usr/bin/env bash
set -Eeuxmo pipefail
DIR="$(dirname "$(command -v greadlink >/dev/null 2>&1 && greadlink -f "$0" || readlink -f "$0")")"

# --- ENV VARS

GIT_REPO_NAME="$GIT_REPO_NAME"
GIT_CLONED_REPO_NAME="${GIT_CLONED_REPO_NAME:-}"

GIT_MASTER_HOST="$GIT_MASTER_HOST"
GIT_MASTER_USERNAME="${GIT_MASTER_USERNAME:-}"
GIT_MASTER_PASSWORD="${GIT_MASTER_PASSWORD:-}"
GIT_MASTER_PROTOCOL="${GIT_MASTER_PROTOCOL:-https}"

GIT_MASTER_LOGIN=
if [[ -n "$GIT_MASTER_USERNAME" ]]; then
  GIT_MASTER_LOGIN="$GIT_MASTER_USERNAME@"

  if [[ -n "$GIT_MASTER_PASSWORD" ]]; then
    GIT_MASTER_LOGIN="$GIT_MASTER_USERNAME:$GIT_MASTER_PASSWORD@"
  fi
fi

# The source of truth
GIT_MASTER_URL="${GIT_MASTER_PROTOCOL}://${GIT_MASTER_LOGIN}${GIT_MASTER_HOST}/${GIT_REPO_NAME}.git"

# Any other cache servers (e.g. k8s service)
# Empty to only use FALLBACK url
GIT_FALLBACK_HOST="${GIT_FALLBACK_HOST:-}"
GIT_FALLBACK_USERNAME="${GIT_FALLBACK_USERNAME:-}"
GIT_FALLBACK_PASSWORD="${GIT_FALLBACK_PASSWORD:-}"
GIT_FALLBACK_PROTOCOL="${GIT_FALLBACK_PROTOCOL:-https}"

GIT_FALLBACK_LOGIN=
if [[ -n "$GIT_FALLBACK_USERNAME" ]]; then
  GIT_FALLBACK_LOGIN="$GIT_FALLBACK_USERNAME@"

  if [[ -n "$GIT_FALLBACK_PASSWORD" ]]; then
    GIT_FALLBACK_LOGIN="$GIT_FALLBACK_USERNAME:$GIT_FALLBACK_PASSWORD@"
  fi
fi

# Generated
GIT_REPO_NAME_SPLIT_LAST="${GIT_REPO_NAME##*/}"
GIT_FALLBACK_URL="${GIT_FALLBACK_PROTOCOL}://${GIT_FALLBACK_LOGIN}${GIT_FALLBACK_HOST}/${GIT_REPO_NAME_SPLIT_LAST}.git"

# Storage for repos
DIR_DATA="/usr/local/apache2/htdocs/"

# --- FUNCS

# Clones from repo and saves files in cache
syncGit() {
  GIT_URL="$1"

  TMP_DIR=$(mktemp -d)
  cd "$TMP_DIR" && \
    git clone --mirror "$GIT_URL" && \
    cd "$TMP_DIR"/* && \
    git update-server-info || {
    return 1
  }

  chown -R www-data:www-data "$TMP_DIR"

  # Overwrite local cache
  rm -rf "$DIR_DATA/*"

  if [[ -n "$GIT_CLONED_REPO_NAME" ]]; then
    mv "$TMP_DIR"/* "$DIR_DATA/$GIT_CLONED_REPO_NAME"
  else
    mv "$TMP_DIR"/* "$DIR_DATA"
  fi

  return 0
}

# Performs a sync with MASTER/FALLBACK repo, depending on availability
mainSync() {

  SUCCESS=false

  syncGit "$GIT_MASTER_URL" && {
      SUCCESS=true
    } || {
      echo "Failed to update from MASTER"
    }

  if [[ "$SUCCESS" == "false" ]]; then
    if [[ -n "$GIT_FALLBACK_HOST" ]]; then
      syncGit "${GIT_FALLBACK_URL}" && {
        SUCCESS=true
      } || {
        echo "Failed to update from FALLBACK"
      }
    fi
  fi

  if [[ "$SUCCESS" == "false" ]]; then
    return 1
  fi

  return 0
}
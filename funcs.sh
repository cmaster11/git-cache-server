#!/usr/bin/env bash
set -Eeuxmo pipefail
DIR="$(dirname "$(command -v greadlink >/dev/null 2>&1 && greadlink -f "$0" || readlink -f "$0")")"

# --- ENV VARS

# The source of truth
GIT_MASTER_URL="${GIT_MASTER_URL}"

# Any other cache servers (e.g. k8s service)
# Empty to only use master url
GIT_SIBLING_URL="${GIT_SIBLING_URL:-}"

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

  mv "$TMP_DIR"/* "$DIR_DATA"

  return 0
}

# Performs a sync with master/sibling repo, depending on availability
mainSync() {

  SUCCESS=false

  if [[ -n "$GIT_SIBLING_URL" ]]; then
    syncGit "$GIT_SIBLING_URL" && {
      SUCCESS=true
    } || {
      echo "Failed to update from sibling"
    }
  fi

  if [[ "$SUCCESS" == "false" ]]; then
    syncGit "$GIT_MASTER_URL" && {
      SUCCESS=true
    } || {
      echo "Failed to update from master"
    }
  fi

  if [[ "$SUCCESS" == "false" ]]; then
    return 1
  fi

  return 0
}
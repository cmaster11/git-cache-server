#!/usr/bin/env bash
set -Eeuxmo pipefail
DIR="$(dirname "$(command -v greadlink >/dev/null 2>&1 && greadlink -f "$0" || readlink -f "$0")")"

source "$DIR/funcs.sh"

# --- MAIN

# Sync needs to be successful
mainSync || {
  echo "Sync failed, exiting..."
  exit 1
}

# Start server
exec httpd-foreground
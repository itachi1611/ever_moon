#!/bin/bash
# Re-exec with bash if invoked via sh/dash. On macOS `sh` is bash in POSIX mode:
# BASH_VERSION is set there, but that mode rejects some syntax of this script,
# so it counts as "not bash" too.
reexec=0
case "${BASH_VERSION:-}" in '') reexec=1 ;; esac
case ":${SHELLOPTS:-}:" in *:posix:*) reexec=1 ;; esac
case "$reexec" in
  1) exec env -u SHELLOPTS -u POSIXLY_CORRECT bash "$0" "$@" ;;
esac

# setup_env.sh
# Create assets/env/.env.<flavor> from assets/env/.env.<flavor>.example. The
# real .env files are gitignored, so a fresh clone needs this once.
#
# Usage: bash scripts/setup/setup_env.sh [dev|prod]
#   (no argument)  both flavors
#   dev | prod     only that flavor
# An existing .env file is never overwritten without asking.

set -euo pipefail

# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
cd_project_root

FLAVORS=(dev prod)
ENV_DIR="assets/env"

# copy_env <flavor>: returns 1 when the example file is missing.
copy_env() {
  local flavor="$1"
  local src="$ENV_DIR/.env.$flavor.example"
  local dst="$ENV_DIR/.env.$flavor"

  if [[ ! -f "$src" ]]; then
    warn "[$flavor] $src not found, skipped."
    return 1
  fi
  if [[ -f "$dst" ]] && ! ask_yes_no "[$flavor] $dst already exists. Overwrite?"; then
    echo "[$flavor] kept the existing file."
    return 0
  fi
  cp "$src" "$dst"
  ok "[$flavor] $dst created. Open it and fill in the real values."
}

TARGETS=("${FLAVORS[@]}")
if [[ "$#" -gt 1 ]]; then die "Too many arguments. Use: bash scripts/setup/setup_env.sh [dev|prod]"; fi
if [[ "$#" -eq 1 ]]; then
  case "$1" in
    -h|--help) print_usage; exit 0 ;;
    dev|prod) TARGETS=("$1") ;;
    *) die "Unknown flavor '$1'. Use dev or prod." ;;
  esac
fi

failed=()
for flavor in "${TARGETS[@]}"; do
  copy_env "$flavor" || failed+=("$flavor")
done

if [[ "${#failed[@]}" -gt 0 ]]; then
  die "Failed for: ${failed[*]}"
fi
echo "Done. Fill in the values in each .env file before running the app."

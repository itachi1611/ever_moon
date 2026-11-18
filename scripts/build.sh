#!/usr/bin/env bash
# Builds an Android release locally through fastlane: asks for the flavor and
# the artifact type, then runs the matching lane.
#
#   dev  + apk -> build_dev        prod + apk -> build_prod
#   dev  + aab -> build_dev_aab    prod + aab -> build_prod_aab
#
# Usage: bash scripts/build.sh [--dry-run]
# prod needs android/key.properties (docs/ci-cd.md). No credentials are sent
# anywhere; the artifact is left in build/.
if [ -z "${BASH_VERSION:-}" ]; then exec bash "$0" "$@"; fi
set -euo pipefail

cd "$(dirname "$0")/.."

DRY_RUN=false
[ "${1:-}" = "--dry-run" ] && DRY_RUN=true

# Prints a numbered menu and sets REPLY_VALUE to the chosen option.
choose() {
  local title="$1"; shift
  local options=("$@") answer i
  echo
  echo "$title"
  for i in "${!options[@]}"; do
    echo "  $((i + 1))) ${options[$i]}"
  done
  while true; do
    read -r -p "Choose [1-${#options[@]}]: " answer
    answer="$(echo "$answer" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
    for i in "${!options[@]}"; do
      if [ "$answer" = "$((i + 1))" ] || [ "$answer" = "${options[$i]}" ]; then
        REPLY_VALUE="${options[$i]}"
        return
      fi
    done
    echo "Please type a number from 1 to ${#options[@]} or the name."
  done
}

choose "Flavor" prod dev
flavor="$REPLY_VALUE"
choose "Build type" apk aab
type="$REPLY_VALUE"

lane="build_${flavor}"
[ "$type" = "aab" ] && lane="${lane}_aab"

echo
echo "Flavor: $flavor | Type: $type | Lane: android $lane"

if [ "$DRY_RUN" = true ]; then
  echo "Dry run: bundle exec fastlane android $lane"
  exit 0
fi

bundle exec fastlane android "$lane"

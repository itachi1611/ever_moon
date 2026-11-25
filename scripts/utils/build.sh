#!/bin/bash
# Re-exec with bash if invoked via sh/dash. On macOS `sh` is bash in POSIX mode:
# BASH_VERSION is set there, but that mode rejects some syntax of this script,
# so it counts as "not bash" too.
reexec=0
if [ -z "${BASH_VERSION:-}" ]; then reexec=1; fi
case ":${SHELLOPTS:-}:" in *:posix:*) reexec=1 ;; esac
if [ "$reexec" = 1 ]; then
  exec env -u SHELLOPTS -u POSIXLY_CORRECT bash "$0" "$@"
fi

# build.sh
# Builds an Android release on this machine through fastlane, for testing. It
# uploads nothing; the artifact is left in build/. A release for the testers or
# for Google Play goes through scripts/distribution/release/release.sh.
#
# prod needs android/key.properties (docs/ci-cd.md). Whatever you leave out is
# asked.
#
# Usage: bash scripts/utils/build.sh [dev|prod] [apk|aab] [--dry-run]
#   dev  + apk -> build_dev        prod + apk -> build_prod
#   dev  + aab -> build_dev_aab    prod + aab -> build_prod_aab

set -euo pipefail

# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
cd_project_root

flavor=""; type=""; DRY=0
for arg in "$@"; do
  case "$arg" in
    dev|prod) flavor="$arg" ;;
    apk|aab) type="$arg" ;;
    --dry-run) DRY=1 ;;
    -h|--help) print_usage; exit 0 ;;
    *) die "Unknown argument '$arg'. Run with --help." ;;
  esac
done

if [ -z "$flavor" ]; then choose "Flavor" prod dev; flavor="$REPLY_VALUE"; fi
if [ -z "$type" ]; then choose "Build type" apk aab; type="$REPLY_VALUE"; fi

lane="build_${flavor}"
if [ "$type" = "aab" ]; then lane="${lane}_aab"; fi

echo
echo "Flavor: $flavor | Type: $type | Lane: android $lane"

if [ "$DRY" = 1 ]; then
  echo "Dry run: bundle exec fastlane android $lane"
  exit 0
fi

bundle exec fastlane android "$lane"

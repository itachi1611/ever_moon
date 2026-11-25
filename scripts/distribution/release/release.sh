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

# release.sh
# One entry point for the two release flows. Both are prod only. It picks the
# target and hands every other argument to that target's own script, so each
# one also runs on its own and prints its options with --help.
#
#   firebase  release_firebase.sh: start a release (version and pull request).
#             When the pull request merges, GitHub builds prod, uploads it to
#             Firebase App Distribution, tags it and tells the team.
#   play      release_play.sh: build the prod bundle and upload it to a Google
#             Play track you choose, from this machine.
#
# Usage: bash scripts/distribution/release/release.sh [firebase|play] [arguments]
#   release.sh                           ask for the target
#   release.sh firebase --dry-run
#   release.sh play internal --validate

set -euo pipefail

# shellcheck source=../../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

main() {
  local target="${1:-}"
  case "$target" in
    -h|--help) print_usage; return 0 ;;
    firebase|play) shift ;;
    "")
      choose "Release target (firebase: release on GitHub, play: upload to Google Play)" firebase play
      target="$REPLY_VALUE"
      ;;
    *) die "Unknown target '$target'. Use firebase or play (see --help)." ;;
  esac
  exec bash "$DIR/release_$target.sh" "$@"
}

main "$@"

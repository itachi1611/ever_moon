# shellcheck shell=bash
# common.sh
# Helpers shared by the scripts in scripts/. Source it, do not run it:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
#
# The caller must already be running under bash. The re-exec guard has to sit
# at the top of each entry script (not here), because it must run before any
# bash-only syntax is read; on macOS `sh` is bash in POSIX mode, which rejects
# some of that syntax.

# Project root, whatever directory the script was started from.
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Colors only when stdout is a terminal, so logs and pipes stay clean.
if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'
else
  BOLD=''; DIM=''; GREEN=''; YELLOW=''; RED=''; RESET=''
fi

die()  { printf '%sError:%s %s\n' "$RED" "$RESET" "$1" >&2; exit 1; }
warn() { printf '%sWarning:%s %s\n' "$YELLOW" "$RESET" "$1"; }
ok()   { printf '%s✓%s %s\n' "$GREEN" "$RESET" "$1"; }

cd_project_root() {
  cd "$PROJECT_ROOT" || die "Cannot cd to $PROJECT_ROOT"
}

# Absolute path of the script that sourced this file. Taken now, before the
# script changes directory, because $0 may be relative to where it was started.
SCRIPT_FILE="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)/$(basename "${BASH_SOURCE[1]}")"

# print_usage: print the header comment of the calling script, from its
# "# Usage:" line to the first line that is not a comment.
print_usage() {
  awk '/^# Usage:/ {p=1} p && !/^#/ {exit} p' "$SCRIPT_FILE" | sed 's/^# \{0,1\}//'
}

# ask_yes_no <question>: returns 0 for yes, 1 for no.
ask_yes_no() {
  local answer
  while true; do
    printf '%s (y/n): ' "$1"
    if ! read -r answer; then die "No input."; fi
    case "$(printf '%s' "$answer" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')" in
      y|yes) return 0 ;;
      n|no) return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

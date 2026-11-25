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
if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'
else
  BOLD=''; DIM=''; GREEN=''; YELLOW=''; RED=''; RESET=''
fi

die()  { printf '%sError:%s %s\n' "$RED" "$RESET" "$1" >&2; exit 1; }
warn() { printf '%sWarning:%s %s\n' "$YELLOW" "$RESET" "$1"; }
ok()   { printf '%s✓%s %s\n' "$GREEN" "$RESET" "$1"; }

# Directory the script was started from, taken before cd_project_root. A path
# given on the command line is relative to it, not to the project root.
START_DIR="$PWD"

# abs_path <path>: the path made absolute against START_DIR.
abs_path() {
  case "$1" in
    /*) printf '%s' "$1" ;;
    *) printf '%s/%s' "$START_DIR" "$1" ;;
  esac
}

# blocker <message>: a problem that stops a real run. With DRY=1 it is only
# reported, so a dry run can still show every later step.
blocker() {
  if [[ "${DRY:-0}" = 1 ]]; then warn "$1 (a real run would stop here)"; else die "$1"; fi
}

# pubspec_version: the version: line of pubspec.yaml, for example 1.2.1+8.
pubspec_version() {
  sed -n -E 's/^version:[[:space:]]*([^[:space:]]+).*/\1/p' "$PROJECT_ROOT/pubspec.yaml" | head -1
}

cd_project_root() {
  cd "$PROJECT_ROOT" || die "Cannot cd to $PROJECT_ROOT"
}

# default_branch: the branch origin calls HEAD, main when that is unknown.
default_branch() {
  local name
  name="$(git symbolic-ref --short refs/remotes/origin/HEAD 2> /dev/null | sed 's#^origin/##' || true)"
  printf '%s' "${name:-main}"
}

# is_greater <a> <b>: true when the x.y.z version a is higher than b.
is_greater() {
  local a1 a2 a3 b1 b2 b3
  IFS=. read -r a1 a2 a3 <<< "$1"
  IFS=. read -r b1 b2 b3 <<< "$2"
  if [[ "$a1" -ne "$b1" ]]; then [[ "$a1" -gt "$b1" ]]; return; fi
  if [[ "$a2" -ne "$b2" ]]; then [[ "$a2" -gt "$b2" ]]; return; fi
  [[ "$a3" -gt "$b3" ]]
}

# choose <title> <option>...: numbered menu; sets REPLY_VALUE to the option
# picked by number or by name.
choose() {
  local title="$1"; shift
  local options=("$@") answer i
  echo
  echo "$title"
  for i in "${!options[@]}"; do
    echo "  $((i + 1))) ${options[$i]}"
  done
  while true; do
    if ! read -r -p "Choose [1-${#options[@]}]: " answer; then die "No input."; fi
    answer="$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
    for i in "${!options[@]}"; do
      if [[ "$answer" = "$((i + 1))" ]] || [[ "$answer" = "${options[$i]}" ]]; then
        REPLY_VALUE="${options[$i]}"
        return 0
      fi
    done
    echo "Please type a number from 1 to ${#options[@]} or the name."
  done
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

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

# release_notes.sh
# Changelog from Conventional Commits, and the version bump they suggest.
# Used by scripts/distribution/release/release_firebase.sh and by the release workflow,
# so the notes that testers, the GitHub Release and the notification show are
# one text.
#
# [ref] is the end of the range (default HEAD): a tag, or a commit. The range
# starts at the newest release tag before it (tags start with a digit); with no
# earlier tag the range is the whole history.
#
# Usage:
#   bash scripts/distribution/release/release_notes.sh [ref] [--max-chars N]   notes, markdown
#   bash scripts/distribution/release/release_notes.sh [ref] --bump            major | minor | patch | none

set -euo pipefail

# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
cd_project_root

MODE=notes
TO=HEAD
MAX=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bump) MODE=bump ;;
    --max-chars) MAX="${2:?--max-chars needs a number}"; shift ;;
    -h|--help) print_usage; exit 0 ;;
    *) TO="$1" ;;
  esac
  shift
done

# --exclude keeps a tag from being its own predecessor.
PREV="$(git describe --tags --abbrev=0 --match '[0-9]*' --exclude "$TO" "$TO" 2>/dev/null || true)"
if [[ -n "$PREV" ]]; then RANGE="$PREV..$TO"; else RANGE="$TO"; fi

LOG="$(git log --no-merges --format='%h%x09%s' "$RANGE")"
BREAKING_HASHES="$(git log --no-merges --format=%h --grep='^BREAKING CHANGE' "$RANGE" | tr '\n' ' ')"

# One line per commit: kind<TAB>hash<TAB>text. kind is breaking, feat, fix or other.
classify() {
  awk -F'\t' -v breaking=" $BREAKING_HASHES " '
    {
      hash = $1; subj = $2; kind = "other"; brk = 0; text = subj
      # The release commit (release_firebase.sh makes it, the squash merge of its
      # pull request may add " (#n)" to the title) is not a change.
      if (subj ~ /^chore\(release\):/) next
      if (match(subj, /^[a-z]+(\([^)]*\))?!?:/)) {
        head = substr(subj, 1, RLENGTH)
        rest = substr(subj, RLENGTH + 1); sub(/^ +/, "", rest)
        type = head; sub(/[(!:].*$/, "", type)
        if (head ~ /!:$/) brk = 1
        if (type == "feat" || type == "fix") { kind = type; text = rest }
      }
      if (index(breaking, " " hash " ") > 0) brk = 1
      if (brk) kind = "breaking"
      print kind "\t" hash "\t" text
    }'
}

CLASSIFIED=""
if [[ -n "$LOG" ]]; then
  CLASSIFIED="$(printf '%s\n' "$LOG" | classify)"
fi

has_kind() {
  printf '%s\n' "$CLASSIFIED" | awk -F'\t' -v k="$1" '$1 == k { found = 1 } END { exit !found }'
}

section() {
  local title="$1" kind="$2" lines
  lines="$(printf '%s\n' "$CLASSIFIED" | awk -F'\t' -v k="$kind" '$1 == k { printf "- %s (%s)\n", $3, $2 }')"
  if [[ -n "$lines" ]]; then
    printf '### %s\n%s\n\n' "$title" "$lines"
  fi
}

if [[ "$MODE" = bump ]]; then
  if [[ -z "$CLASSIFIED" ]]; then echo none
  elif has_kind breaking; then echo major
  elif has_kind feat; then echo minor
  else echo patch
  fi
  exit 0
fi

if [[ -n "$PREV" ]]; then
  OUT="## Changes since $PREV"$'\n\n'
else
  OUT="## Changes (first release)"$'\n\n'
fi
if [[ -z "$CLASSIFIED" ]]; then
  OUT="${OUT}No changes."$'\n'
else
  # $(...) drops trailing newlines, so each section gets its blank line back
  # here; without it the next heading is glued to the last bullet.
  for spec in 'Breaking changes:breaking' 'Features:feat' 'Fixes:fix' 'Other changes:other'; do
    block="$(section "${spec%%:*}" "${spec##*:}")"
    if [[ -n "$block" ]]; then OUT="${OUT}${block}"$'\n\n'; fi
  done
fi

if [[ "$MAX" -gt 0 ]] && [[ "${#OUT}" -gt "$MAX" ]]; then
  OUT="$(printf '%s' "$OUT" | head -c "$MAX")"$'\n'"... (truncated)"
fi
printf '%s\n' "$OUT"

#!/bin/bash
# Re-exec with bash if invoked via sh/dash
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

# release_notes.sh
# Changelog from Conventional Commits, and the version bump they suggest.
# Used by scripts/distribution.sh and by the release workflow, so the notes
# that testers, the GitHub Release and the notification show are one text.
#
# Usage:
#   bash scripts/release_notes.sh [ref] [--max-chars N]   notes, markdown
#   bash scripts/release_notes.sh [ref] --bump            major | minor | patch | none
#
# [ref] is the end of the range (default HEAD): a tag, or a commit. The range
# starts at the newest release tag before it (tags start with a digit); with no
# earlier tag the range is the whole history.

set -euo pipefail

_PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$_PROJECT_ROOT" || { printf 'Cannot cd to project root\n' >&2; exit 1; }

MODE=notes
TO=HEAD
MAX=0
while [ $# -gt 0 ]; do
  case "$1" in
    --bump) MODE=bump ;;
    --max-chars) MAX="${2:?--max-chars needs a number}"; shift ;;
    -h|--help) sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) TO="$1" ;;
  esac
  shift
done

# --exclude keeps a tag from being its own predecessor.
PREV="$(git describe --tags --abbrev=0 --match '[0-9]*' --exclude "$TO" "$TO" 2>/dev/null || true)"
if [ -n "$PREV" ]; then RANGE="$PREV..$TO"; else RANGE="$TO"; fi

LOG="$(git log --no-merges --format='%h%x09%s' "$RANGE")"
BREAKING_HASHES="$(git log --no-merges --format=%h --grep='^BREAKING CHANGE' "$RANGE" | tr '\n' ' ')"

# One line per commit: kind<TAB>hash<TAB>text. kind is breaking, feat, fix or other.
classify() {
  awk -F'\t' -v breaking=" $BREAKING_HASHES " '
    {
      hash = $1; subj = $2; kind = "other"; brk = 0; text = subj
      # The version bump commit made by distribution.sh is not a change.
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
if [ -n "$LOG" ]; then
  CLASSIFIED="$(printf '%s\n' "$LOG" | classify)"
fi

has_kind() {
  printf '%s\n' "$CLASSIFIED" | awk -F'\t' -v k="$1" '$1 == k { found = 1 } END { exit !found }'
}

section() {
  local title="$1" kind="$2" lines
  lines="$(printf '%s\n' "$CLASSIFIED" | awk -F'\t' -v k="$kind" '$1 == k { printf "- %s (%s)\n", $3, $2 }')"
  if [ -n "$lines" ]; then
    printf '### %s\n%s\n\n' "$title" "$lines"
  fi
}

if [ "$MODE" = bump ]; then
  if [ -z "$CLASSIFIED" ]; then echo none
  elif has_kind breaking; then echo major
  elif has_kind feat; then echo minor
  else echo patch
  fi
  exit 0
fi

if [ -n "$PREV" ]; then
  OUT="## Changes since $PREV"$'\n\n'
else
  OUT="## Changes (first release)"$'\n\n'
fi
if [ -z "$CLASSIFIED" ]; then
  OUT="${OUT}No changes."$'\n'
else
  OUT="${OUT}$(section 'Breaking changes' breaking)$(section 'Features' feat)$(section 'Fixes' fix)$(section 'Other changes' other)"
fi

if [ "$MAX" -gt 0 ] && [ "${#OUT}" -gt "$MAX" ]; then
  OUT="$(printf '%s' "$OUT" | head -c "$MAX")"$'\n'"... (truncated)"
fi
printf '%s\n' "$OUT"

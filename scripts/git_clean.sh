#!/bin/bash
# Re-exec with bash if invoked via sh/dash
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

# git_clean.sh
# After a pull request is merged: go back to main, pull it, and delete the
# local branches that are no longer needed, so the local branch list matches
# the remote (GitHub deletes a branch when its pull request merges).
#
# A local branch is deleted when its branch on origin is gone. Squash merge
# leaves no trace of the branch in the history, so Git cannot tell merged from
# unmerged by itself; "gone from origin" is the signal. A branch that was never
# pushed, or that still exists on origin, is kept and listed with the reason.
#
# Usage: bash scripts/git_clean.sh [--dry-run] [--all] [--yes]
#   --dry-run  show what would happen; change nothing (the fetch still updates
#              the remote-tracking branches, which is how "gone" is seen)
#   --all      delete every local branch except main, also those never pushed
#              or still on origin; they can hold work that exists nowhere else
#   --yes      do not ask for confirmation

set -euo pipefail

_PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$_PROJECT_ROOT" || { printf 'Cannot cd to project root\n' >&2; exit 1; }

# ── Output helpers ───────────────────────────────────────────────────────────
if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'
else
  BOLD=''; DIM=''; GREEN=''; YELLOW=''; RED=''; RESET=''
fi

die()  { printf '%sError:%s %s\n' "$RED" "$RESET" "$1" >&2; exit 1; }
warn() { printf '%sWarning:%s %s\n' "$YELLOW" "$RESET" "$1"; }

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

DRY=0; ALL=0; YES=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --all) ALL=1 ;;
    --yes) YES=1 ;;
    -h|--help) sed -n '7,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "Unknown option '$arg'. Use --dry-run, --all or --yes." ;;
  esac
done

# ── Repository state ─────────────────────────────────────────────────────────
MAIN="$(git symbolic-ref --short refs/remotes/origin/HEAD 2> /dev/null | sed 's#^origin/##' || true)"
MAIN="${MAIN:-main}"

if [ -n "$(git status --porcelain)" ]; then
  die "The working tree has uncommitted changes. Commit or stash them first."
fi
if ! git fetch --prune --tags --quiet origin 2> /dev/null; then
  die "Could not reach origin; nothing was changed."
fi
if ! git rev-parse --verify --quiet "refs/heads/$MAIN" > /dev/null; then
  die "There is no local branch '$MAIN'."
fi

# ── Go back to main and pull ─────────────────────────────────────────────────
CURRENT="$(git rev-parse --abbrev-ref HEAD)"
if [ "$DRY" = 1 ]; then
  if [ "$CURRENT" != "$MAIN" ]; then printf 'Would switch from %s to %s.\n' "$CURRENT" "$MAIN"; fi
  printf 'Would pull %s (fast-forward only).\n' "$MAIN"
else
  if [ "$CURRENT" != "$MAIN" ]; then git checkout --quiet "$MAIN"; fi
  git pull --quiet --ff-only origin "$MAIN" || die "Could not fast-forward $MAIN to origin/$MAIN. Resolve it by hand."
  printf '%s%s%s is up to date with origin/%s.\n' "$GREEN" "$MAIN" "$RESET" "$MAIN"
fi

# ── Sort the local branches ──────────────────────────────────────────────────
# Each line of for-each-ref: name|upstream|track. track is "[gone]" when the
# upstream branch no longer exists on origin.
DELETE=(); KEEP=(); REASONS=()
while IFS='|' read -r name upstream track; do
  if [ "$name" = "$MAIN" ] || [ -z "$name" ]; then continue; fi
  if [ "$track" = "[gone]" ]; then
    DELETE+=("$name")
  elif [ "$ALL" = 1 ]; then
    DELETE+=("$name")
  elif [ -z "$upstream" ]; then
    KEEP+=("$name"); REASONS+=("never pushed")
  else
    KEEP+=("$name"); REASONS+=("still on origin")
  fi
done < <(git for-each-ref --format='%(refname:short)|%(upstream:short)|%(upstream:track)' refs/heads)

if [ "${#KEEP[@]}" -gt 0 ]; then
  printf '\n%sKept%s (use --all to delete these too):\n' "$BOLD" "$RESET"
  i=0
  for name in "${KEEP[@]}"; do
    printf '  %s  %s(%s)%s\n' "$name" "$DIM" "${REASONS[$i]}" "$RESET"
    i=$((i + 1))
  done
fi

if [ "${#DELETE[@]}" -eq 0 ]; then
  printf '\nNo local branch to delete.\n'
  exit 0
fi

printf '\n%sTo delete:%s\n' "$BOLD" "$RESET"
for name in "${DELETE[@]}"; do
  printf '  %s  %s%s%s\n' "$name" "$DIM" "$(git log -1 --format='%h %s' "refs/heads/$name")" "$RESET"
done
if [ "$ALL" = 1 ]; then
  warn "--all also deletes branches that may hold work that is not on origin."
fi

# ── Confirm and delete ───────────────────────────────────────────────────────
if [ "$DRY" = 1 ]; then
  echo "Dry run: nothing was changed."
  exit 0
fi
if [ "$YES" = 0 ] && ! ask_yes_no "Delete ${#DELETE[@]} local branch(es)?"; then
  echo "Cancelled; no branch was deleted."
  exit 0
fi

# -D is needed: after a squash merge Git does not see the branch as merged.
for name in "${DELETE[@]}"; do
  sha="$(git rev-parse --short "refs/heads/$name")"
  git branch -D --quiet "$name" > /dev/null
  printf 'Deleted %s (was %s; restore with: git branch %s %s)\n' "$name" "$sha" "$name" "$sha"
done
printf '\n%sLocal branches now:%s\n' "$BOLD" "$RESET"
git branch

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

# git_helper.sh
# Small git helpers for this repository, one command per task. To add a
# command: write a cmd_<name> function, add it to main() and to this text.
#
# Usage: bash scripts/utils/git_helper.sh <command> [options]
#
# Commands:
#   clean [--dry-run] [--all] [--yes]
#       After a pull request is merged: go back to main, pull it, and delete the
#       local branches that are no longer needed, so the local list matches the
#       remote (GitHub deletes a branch when its pull request merges).
#         --dry-run  show what would happen; change nothing (the fetch still
#                    updates the remote-tracking branches, which is how "gone"
#                    is seen)
#         --all      delete every local branch except main, also those never
#                    pushed or still on origin; they can hold work that exists
#                    nowhere else
#         --yes      do not ask for confirmation
#   help
#       Show this text.

set -euo pipefail

# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
cd_project_root

# CLEAN

clean_parse_args() {
  DRY=0; ALL=0; YES=0
  local arg
  for arg in "$@"; do
    case "$arg" in
      --dry-run) DRY=1 ;;
      --all) ALL=1 ;;
      --yes) YES=1 ;;
      -h|--help) print_usage; exit 0 ;;
      *) die "Unknown option '$arg'. Use --dry-run, --all or --yes." ;;
    esac
  done
}

# Sets MAIN and stops before any change when the repository is not ready.
clean_check_repo() {
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
}

clean_sync_main() {
  local current
  current="$(git rev-parse --abbrev-ref HEAD)"
  if [ "$DRY" = 1 ]; then
    if [ "$current" != "$MAIN" ]; then printf 'Would switch from %s to %s.\n' "$current" "$MAIN"; fi
    printf 'Would pull %s (fast-forward only).\n' "$MAIN"
    return 0
  fi
  if [ "$current" != "$MAIN" ]; then git checkout --quiet "$MAIN"; fi
  git pull --quiet --ff-only origin "$MAIN" || die "Could not fast-forward $MAIN to origin/$MAIN. Resolve it by hand."
  printf '%s%s%s is up to date with origin/%s.\n' "$GREEN" "$MAIN" "$RESET" "$MAIN"
}

# Fills DELETE, KEEP and REASONS (KEEP and REASONS line up by index).
# Each line of for-each-ref is name|upstream|track, where track is "[gone]"
# once the upstream branch no longer exists on origin. Squash merge leaves no
# trace of the branch in the history, so Git cannot tell merged from unmerged
# by itself; "gone from origin" is the signal.
clean_classify() {
  DELETE=(); KEEP=(); REASONS=()
  local refs line name rest upstream track
  local IFS=$'\n'
  refs="$(git for-each-ref --format='%(refname:short)|%(upstream:short)|%(upstream:track)' refs/heads)"
  for line in $refs; do
    # Split with parameter expansion: no here-string and no subshell, so the
    # arrays survive.
    name="${line%%|*}"
    rest="${line#*|}"
    upstream="${rest%%|*}"
    track="${rest#*|}"
    if [ "$name" = "$MAIN" ] || [ -z "$name" ]; then continue; fi
    if [ "$track" = "[gone]" ] || [ "$ALL" = 1 ]; then
      DELETE+=("$name")
    elif [ -z "$upstream" ]; then
      KEEP+=("$name"); REASONS+=("never pushed")
    else
      KEEP+=("$name"); REASONS+=("still on origin")
    fi
  done
}

clean_show_kept() {
  if [ "${#KEEP[@]}" -eq 0 ]; then return 0; fi
  printf '\n%sKept%s (use --all to delete these too):\n' "$BOLD" "$RESET"
  local i=0 name
  for name in "${KEEP[@]}"; do
    printf '  %s  %s(%s)%s\n' "$name" "$DIM" "${REASONS[$i]}" "$RESET"
    i=$((i + 1))
  done
}

clean_show_delete() {
  local name
  printf '\n%sTo delete:%s\n' "$BOLD" "$RESET"
  for name in "${DELETE[@]}"; do
    printf '  %s  %s%s%s\n' "$name" "$DIM" "$(git log -1 --format='%h %s' "refs/heads/$name")" "$RESET"
  done
  if [ "$ALL" = 1 ]; then
    warn "--all also deletes branches that may hold work that is not on origin."
  fi
}

clean_delete() {
  if [ "$DRY" = 1 ]; then
    echo "Dry run: nothing was changed."
    return 0
  fi
  if [ "$YES" = 0 ] && ! ask_yes_no "Delete ${#DELETE[@]} local branch(es)?"; then
    echo "Cancelled; no branch was deleted."
    return 0
  fi
  local name sha
  # -D is needed: after a squash merge Git does not see the branch as merged.
  for name in "${DELETE[@]}"; do
    sha="$(git rev-parse --short "refs/heads/$name")"
    git branch -D --quiet "$name" > /dev/null
    printf 'Deleted %s (was %s; restore with: git branch %s %s)\n' "$name" "$sha" "$name" "$sha"
  done
  printf '\n%sLocal branches now:%s\n' "$BOLD" "$RESET"
  git branch
}

cmd_clean() {
  clean_parse_args "$@"
  clean_check_repo
  clean_sync_main
  clean_classify
  clean_show_kept
  if [ "${#DELETE[@]}" -eq 0 ]; then
    printf '\nNo local branch to delete.\n'
    return 0
  fi
  clean_show_delete
  clean_delete
}

# MAIN

main() {
  local command="${1:-}"
  case "$command" in
    clean) shift; cmd_clean "$@" ;;
    help|-h|--help) print_usage ;;
    "") print_usage >&2; exit 1 ;;
    *) die "Unknown command '$command'. Run: bash scripts/utils/git_helper.sh help" ;;
  esac
}

main "$@"

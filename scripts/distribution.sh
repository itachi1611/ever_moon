#!/bin/bash
# Re-exec with bash if invoked via sh/dash
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

# distribution.sh
# Start a release: choose the version, update pubspec.yaml, commit, tag and push.
# The tag (for example 1.0.1+2) is what starts the release workflow on GitHub,
# which builds the prod flavor and uploads it to Firebase App Distribution.
#
# Usage: bash scripts/distribution.sh [--dry-run]
#   --dry-run  ask the same questions and show what would run; change nothing
#
# Run it on main, with a clean working tree, after your changes are merged.

set -euo pipefail

_PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$_PROJECT_ROOT" || { printf 'Cannot cd to project root\n' >&2; exit 1; }

DRY=0
if [ "${1:-}" = "--dry-run" ]; then DRY=1; fi

# ── Output helpers ───────────────────────────────────────────────────────────
if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'
else
  BOLD=''; DIM=''; GREEN=''; YELLOW=''; RED=''; RESET=''
fi

die()  { printf '%sError:%s %s\n' "$RED" "$RESET" "$1" >&2; exit 1; }
warn() { printf '%sWarning:%s %s\n' "$YELLOW" "$RESET" "$1"; }

# A dry run reports a blocking problem and goes on, so every step can be seen.
blocker() {
  if [ "$DRY" = 1 ]; then warn "$1 (a real run would stop here)"; else die "$1"; fi
}

# ask_yes_no <question>: returns 0 for yes, 1 for no.
ask_yes_no() {
  local answer
  while true; do
    printf '%s (yes/no): ' "$1"
    if ! read -r answer; then die "No input."; fi
    case "$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')" in
      y|yes) return 0 ;;
      n|no) return 1 ;;
      *) echo "Please answer yes or no." ;;
    esac
  done
}

# ── Versions ─────────────────────────────────────────────────────────────────
VERSION_RE='^[0-9]+\.[0-9]+\.[0-9]+$'

# true when $1 is a higher x.y.z than $2.
is_greater() {
  local a1 a2 a3 b1 b2 b3
  IFS=. read -r a1 a2 a3 <<< "$1"
  IFS=. read -r b1 b2 b3 <<< "$2"
  if [ "$a1" -ne "$b1" ]; then [ "$a1" -gt "$b1" ]; return; fi
  if [ "$a2" -ne "$b2" ]; then [ "$a2" -gt "$b2" ]; return; fi
  [ "$a3" -gt "$b3" ]
}

# next_version <x.y.z> <major|minor|patch>
next_version() {
  local major minor patch
  IFS=. read -r major minor patch <<< "$1"
  case "$2" in
    major) echo "$((major + 1)).0.0" ;;
    minor) echo "${major}.$((minor + 1)).0" ;;
    *) echo "${major}.${minor}.$((patch + 1))" ;;
  esac
}

PUBSPEC_VERSION="$(sed -n -E 's/^version:[[:space:]]*([^[:space:]]+).*/\1/p' pubspec.yaml | head -1)"
if ! printf '%s' "$PUBSPEC_VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$'; then
  die "pubspec.yaml version '$PUBSPEC_VERSION' must look like 1.0.0+1."
fi
CURRENT_NAME="${PUBSPEC_VERSION%%+*}"
CURRENT_BUILD="${PUBSPEC_VERSION##*+}"

# ── Flutter in use ───────────────────────────────────────────────────────────
# fvm when the project uses it, plain flutter otherwise.
flutter_in_use() {
  if [ -f .fvmrc ] && command -v fvm > /dev/null 2>&1; then
    printf 'fvm: %s' "$(fvm flutter --version 2> /dev/null | head -1)"
  elif command -v flutter > /dev/null 2>&1; then
    printf 'flutter: %s' "$(flutter --version 2> /dev/null | head -1)"
  else
    printf 'not found'
  fi
}

PINNED="$(sed -n -E 's/^[[:space:]]+flutter:[[:space:]]*([0-9][^[:space:]]*).*/\1/p' pubspec.yaml | head -1)"

# ── Repository state ─────────────────────────────────────────────────────────
RELEASE_BRANCH="$(git symbolic-ref --short refs/remotes/origin/HEAD 2> /dev/null | sed 's#^origin/##' || true)"
RELEASE_BRANCH="${RELEASE_BRANCH:-main}"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"

if [ "$BRANCH" != "$RELEASE_BRANCH" ]; then
  blocker "You are on '$BRANCH'; releases are made from '$RELEASE_BRANCH'."
fi
if [ -n "$(git status --porcelain)" ]; then
  blocker "The working tree has uncommitted changes. Commit or stash them first."
fi
if ! git fetch --tags --quiet origin 2> /dev/null; then
  warn "Could not reach origin; using the tags and commits already here."
fi
if git rev-parse --verify --quiet "origin/$RELEASE_BRANCH" > /dev/null; then
  BEHIND="$(git rev-list --count "HEAD..origin/$RELEASE_BRANCH")"
  if [ "$BEHIND" -gt 0 ]; then blocker "'$RELEASE_BRANCH' is $BEHIND commit(s) behind origin. Pull first."; fi
fi

LAST_TAG="$(git describe --tags --abbrev=0 --match '[0-9]*' 2> /dev/null || true)"

# ── Summary ──────────────────────────────────────────────────────────────────
printf '\n%sBuild version : %s%s%s  %s(build number %s)%s\n' "$BOLD" "$GREEN" "$CURRENT_NAME" "$RESET" "$DIM" "$CURRENT_BUILD" "$RESET"
printf 'Last release  : %s\n' "${LAST_TAG:-none yet}"
printf 'Flutter       : %s\n' "$(flutter_in_use)"
if [ -z "$PINNED" ]; then
  blocker "pubspec.yaml has no 'flutter: x.y.z' under environment:, and CI needs it."
else
  printf 'CI builds with : Flutter %s (pubspec.yaml)\n' "$PINNED"
fi

printf '\n%sChanges since %s%s\n\n' "$BOLD" "${LAST_TAG:-the beginning}" "$RESET"
bash scripts/release_notes.sh HEAD | sed '1,2d'
if [ -n "$LAST_TAG" ]; then
  printf '%s%s%s\n' "$DIM" "$(git diff --shortstat "$LAST_TAG"..HEAD)" "$RESET"
fi

# ── Choose the version ───────────────────────────────────────────────────────
NEW_NAME=""
NEW_BUILD=""

if [ -z "$LAST_TAG" ]; then
  printf '\nNo release has been made yet.\n'
  if ask_yes_no "Release the current version $PUBSPEC_VERSION as it is?"; then
    NEW_NAME="$CURRENT_NAME"; NEW_BUILD="$CURRENT_BUILD"
  fi
else
  LEVEL="$(bash scripts/release_notes.sh HEAD --bump)"
  if [ "$LEVEL" = none ]; then
    printf '\nNothing to release: no commits since %s.\n' "$LAST_TAG"
    exit 0
  fi
  SUGGESTED="$(next_version "$CURRENT_NAME" "$LEVEL")"
  printf '\nSuggested bump: %s%s%s (from the commit types)\n' "$BOLD" "$LEVEL" "$RESET"
  if ask_yes_no "Bump to $SUGGESTED?"; then
    NEW_NAME="$SUGGESTED"; NEW_BUILD="$((CURRENT_BUILD + 1))"
  fi
fi

if [ -z "$NEW_NAME" ]; then
  while true; do
    printf 'Enter the version (x.y.z): '
    if ! read -r NEW_NAME; then die "No input."; fi
    if ! printf '%s' "$NEW_NAME" | grep -Eq "$VERSION_RE"; then echo "Use the form 1.2.3."; continue; fi
    if [ -n "$LAST_TAG" ] && ! is_greater "$NEW_NAME" "${LAST_TAG%%+*}"; then
      echo "The version must be higher than the last release (${LAST_TAG%%+*})."; continue
    fi
    break
  done
  if [ "$NEW_NAME" = "$CURRENT_NAME" ]; then NEW_BUILD="$CURRENT_BUILD"; else NEW_BUILD="$((CURRENT_BUILD + 1))"; fi
fi

NEW_VERSION="${NEW_NAME}+${NEW_BUILD}"
if git rev-parse --verify --quiet "refs/tags/$NEW_VERSION" > /dev/null; then
  die "The tag $NEW_VERSION already exists."
fi

# ── Confirm and run ──────────────────────────────────────────────────────────
printf '\n%sRelease %s%s\n' "$BOLD" "$NEW_VERSION" "$RESET"
if [ "$NEW_VERSION" != "$PUBSPEC_VERSION" ]; then
  printf '  1. set version: %s in pubspec.yaml (was %s)\n  2. commit "chore(release): %s"\n' "$NEW_VERSION" "$PUBSPEC_VERSION" "$NEW_VERSION"
fi
printf '  - tag %s\n  - push %s and the tag to origin; GitHub Actions then builds and uploads prod\n\n' "$NEW_VERSION" "$RELEASE_BRANCH"

if ! ask_yes_no "Go ahead?"; then echo "Cancelled; nothing changed."; exit 0; fi

if [ "$DRY" = 1 ]; then
  echo "Dry run: nothing was changed."
  exit 0
fi

if [ "$NEW_VERSION" != "$PUBSPEC_VERSION" ]; then
  awk -v v="$NEW_VERSION" '!done && /^version:/ { print "version: " v; done = 1; next } { print }' pubspec.yaml > pubspec.yaml.tmp
  mv pubspec.yaml.tmp pubspec.yaml
  git add pubspec.yaml
  git commit --quiet -m "chore(release): $NEW_VERSION"
fi
git tag -a "$NEW_VERSION" -m "Release $NEW_VERSION"

if ! git push origin "$RELEASE_BRANCH" "refs/tags/$NEW_VERSION"; then
  printf '%sPush failed.%s The commit and tag exist only here. To undo: git tag -d %s && git reset --hard HEAD~1 (only if a release commit was made).\n' "$RED" "$RESET" "$NEW_VERSION" >&2
  exit 1
fi

REMOTE="$(git remote get-url origin | sed -E 's#^git@github.com:#https://github.com/#; s#\.git$##')"
printf '\n%sPushed %s.%s Follow the release at %s/actions\n' "$GREEN" "$NEW_VERSION" "$RESET" "$REMOTE"

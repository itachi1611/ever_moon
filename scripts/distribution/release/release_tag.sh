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

# release_tag.sh
# Fallback: tag main by hand. A normal release needs only
# scripts/distribution/release/release_firebase.sh, because merging its pull request makes the
# Distribute prod workflow build and tag by itself. Use this script for the
# first release (pubspec.yaml already holds the version, so no pull request) or
# when that workflow failed and has to be started again from a tag.
# The tag (for example 1.0.1+2) starts the release workflow on GitHub, which
# builds the prod flavor and uploads it to Firebase App Distribution.
#
# Usage: bash scripts/distribution/release/release_tag.sh [--dry-run]
#   --dry-run  run every check and show what would happen; change nothing
#
# It reads the version from pubspec.yaml on origin/main, so it works from any
# branch with a clean working tree; a real run then moves to main and pulls.

set -euo pipefail

# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
cd_project_root

DRY=0
if [ "${1:-}" = "--dry-run" ]; then DRY=1; fi

# ── Repository state ─────────────────────────────────────────────────────────
RELEASE_BRANCH="$(default_branch)"

if ! git fetch --tags --quiet origin 2> /dev/null; then
  die "Could not reach origin: the tag must be made from the commit that is on origin/$RELEASE_BRANCH."
fi
if ! git rev-parse --verify --quiet "origin/$RELEASE_BRANCH" > /dev/null; then
  die "origin/$RELEASE_BRANCH does not exist."
fi
if [ -n "$(git status --porcelain)" ]; then
  blocker "The working tree has uncommitted changes. Commit or stash them first."
fi

TARGET="$(git rev-parse "origin/$RELEASE_BRANCH")"
SUBJECT="$(git log -1 --format=%s "$TARGET")"

# The version comes from origin/main itself, not from the working tree.
PUBSPEC_VERSION="$(git show "$TARGET:pubspec.yaml" | sed -n -E 's/^version:[[:space:]]*([^[:space:]]+).*/\1/p' | head -1)"
if ! printf '%s' "$PUBSPEC_VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$'; then
  die "pubspec.yaml on origin/$RELEASE_BRANCH has version '$PUBSPEC_VERSION'; it must look like 1.0.0+1."
fi
NEW_NAME="${PUBSPEC_VERSION%%+*}"
NEW_BUILD="${PUBSPEC_VERSION##*+}"
NEW_VERSION="$PUBSPEC_VERSION"

LAST_TAG="$(git describe --tags --abbrev=0 --match '[0-9]*' "$TARGET" 2> /dev/null || true)"

printf '\n%sVersion on %s: %s%s%s\n' "$BOLD" "origin/$RELEASE_BRANCH" "$GREEN" "$NEW_VERSION" "$RESET"
printf 'Last release       : %s\n' "${LAST_TAG:-none yet}"
printf 'Commit to tag      : %s  %s\n\n' "$(git rev-parse --short "$TARGET")" "$SUBJECT"

# ── Checks ───────────────────────────────────────────────────────────────────
if [ "$NEW_VERSION" = "$LAST_TAG" ]; then
  die "origin/$RELEASE_BRANCH is at $LAST_TAG, which is already tagged, so there is nothing to tag. If you prepared a release, merge its pull request first and run this script again; to start a new release run scripts/distribution/release/release_firebase.sh."
fi
if git rev-parse --verify --quiet "refs/tags/$NEW_VERSION" > /dev/null \
  || git ls-remote --exit-code --tags origin "refs/tags/$NEW_VERSION" > /dev/null 2>&1; then
  die "The tag $NEW_VERSION already exists. Nothing to do; if the release has not run, merge the release pull request first."
fi

if [ -n "$LAST_TAG" ]; then
  LAST_NAME="${LAST_TAG%%+*}"
  LAST_BUILD="${LAST_TAG##*+}"
  if [ "$NEW_NAME" != "$LAST_NAME" ] && ! is_greater "$NEW_NAME" "$LAST_NAME"; then
    die "The version $NEW_NAME is not higher than the last release ($LAST_NAME). Has the release pull request been merged?"
  fi
  if [ "$NEW_BUILD" -le "$LAST_BUILD" ]; then
    die "The build number $NEW_BUILD is not higher than the last release ($LAST_BUILD); Android needs a higher number on every upload."
  fi
fi

# A release commit is the squashed release pull request: its title starts with
# the version. Anything else means the merge has not happened or a different
# change landed after it, and the tag would point at the wrong commit.
case "$SUBJECT" in
  "chore(release): $NEW_VERSION"*) ;;
  *) die "The newest commit on origin/$RELEASE_BRANCH is not the release commit for $NEW_VERSION (expected a title starting 'chore(release): $NEW_VERSION'). Merge the release pull request, and tag before anything else is merged." ;;
esac

# ── Confirm and run ──────────────────────────────────────────────────────────
printf '%sTag %s%s\n' "$BOLD" "$NEW_VERSION" "$RESET"
printf '  1. move to %s and pull (fast-forward only)\n' "$RELEASE_BRANCH"
printf '  2. create the tag %s on %s\n' "$NEW_VERSION" "$(git rev-parse --short "$TARGET")"
printf '  3. push the tag; GitHub Actions then builds and uploads prod\n\n'

if ! ask_yes_no "Tag $NEW_VERSION on $RELEASE_BRANCH?"; then echo "Cancelled; nothing changed."; exit 0; fi

if [ "$DRY" = 1 ]; then
  echo "Dry run: nothing was changed."
  exit 0
fi

git checkout --quiet "$RELEASE_BRANCH"
git pull --quiet --ff-only origin "$RELEASE_BRANCH" || die "Could not fast-forward $RELEASE_BRANCH to origin."
if [ "$(git rev-parse HEAD)" != "$TARGET" ]; then
  die "$RELEASE_BRANCH moved while you were answering. Run the script again."
fi

git tag -a "$NEW_VERSION" -m "Release $NEW_VERSION" "$TARGET"

if ! git push origin "refs/tags/$NEW_VERSION"; then
  printf '%sPush failed.%s The tag exists only here. To undo: git tag -d %s\n' "$RED" "$RESET" "$NEW_VERSION" >&2
  exit 1
fi

REMOTE="$(git remote get-url origin | sed -E 's#^git@github.com:#https://github.com/#; s#\.git$##')"
printf '\n%sTagged %s.%s Follow the release at %s/actions\n' "$GREEN" "$NEW_VERSION" "$RESET" "$REMOTE"

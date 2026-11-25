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

# release_firebase.sh
# Starts a release: choose the version, put it in pubspec.yaml on a release
# branch, push the branch and open the pull request (with auto-merge when the
# GitHub CLI `gh` is installed and signed in; otherwise it prints a link whose
# title and description are already filled in).
#
# main only accepts pull requests (repository ruleset). When the release pull
# request is merged, the commit "chore(release): <version>" lands on main and
# the Distribute prod workflow tags it, builds prod and uploads it to Firebase
# App Distribution by itself. Nothing else has to be run.
# scripts/distribution/release/release_tag.sh is only the fallback (first release, or a failed run).
#
# Usage: bash scripts/distribution/release/release_firebase.sh [--dry-run]
#   --dry-run  ask the same questions and show what would run; change nothing
#
# Run it on main, with a clean working tree, after your changes are merged.

set -euo pipefail

# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
cd_project_root

DRY=0
if [ "${1:-}" = "--dry-run" ]; then DRY=1; fi

# ── Versions ─────────────────────────────────────────────────────────────────
VERSION_RE='^[0-9]+\.[0-9]+\.[0-9]+$'

# url_encode <text>: percent-encodes every byte except the unreserved ones, so
# a title or description can travel in a query string. perl reads bytes, which
# keeps non-ASCII text intact.
url_encode() {
  printf '%s' "$1" | perl -0777 -pe 's/([^A-Za-z0-9._~-])/sprintf("%%%02X", ord($1))/ge'
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
RELEASE_BRANCH="$(default_branch)"
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
bash scripts/distribution/release/release_notes.sh HEAD | sed '1,2d'
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
  LEVEL="$(bash scripts/distribution/release/release_notes.sh HEAD --bump)"
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

REMOTE="$(git remote get-url origin | sed -E 's#^git@github.com:#https://github.com/#; s#\.git$##')"

# pubspec.yaml already says the version to release (the very first release):
# there is nothing to put on a branch, only the tag is missing.
if [ "$NEW_VERSION" = "$PUBSPEC_VERSION" ]; then
  printf '\n%s%s%s is already the version on %s; no pull request is needed.\n' "$BOLD" "$NEW_VERSION" "$RESET" "$RELEASE_BRANCH"
  printf 'Tag it with:  bash scripts/distribution/release/release_tag.sh\n'
  exit 0
fi

# The release branch is named after the version name, without the build number.
RELEASE_WORK_BRANCH="release/${NEW_NAME}"
if git rev-parse --verify --quiet "refs/heads/$RELEASE_WORK_BRANCH" > /dev/null; then
  blocker "The branch $RELEASE_WORK_BRANCH already exists here. Open its pull request, or delete it: git branch -D $RELEASE_WORK_BRANCH"
fi
if git ls-remote --exit-code --heads origin "$RELEASE_WORK_BRANCH" > /dev/null 2>&1; then
  blocker "The branch $RELEASE_WORK_BRANCH already exists on origin. Open its pull request, or delete it on GitHub first."
fi

# ── Confirm and run ──────────────────────────────────────────────────────────
PR_TITLE="chore(release): $NEW_VERSION"
# The description is the start of the changelog, cut short so the link that
# carries it stays well under the length browsers and GitHub accept. The full
# changelog is in the GitHub Release.
PR_BODY="Release ${NEW_VERSION}. Merging this pull request starts the Distribute prod workflow: it builds prod, uploads it to Firebase App Distribution, tags ${NEW_VERSION} and publishes the GitHub Release."$'\n\n'"$(bash scripts/distribution/release/release_notes.sh HEAD --max-chars 1200)"
printf '\n%sRelease %s%s\n' "$BOLD" "$NEW_VERSION" "$RESET"
printf '  1. create the branch %s from %s\n' "$RELEASE_WORK_BRANCH" "$RELEASE_BRANCH"
printf '  2. set version: %s in pubspec.yaml (was %s)\n' "$NEW_VERSION" "$PUBSPEC_VERSION"
printf '  3. commit "%s" and push the branch\n' "$PR_TITLE"
printf '  4. open the pull request and turn on auto-merge; the merge starts the release\n\n'

if ! ask_yes_no "Go ahead?"; then echo "Cancelled; nothing changed."; exit 0; fi

if [ "$DRY" = 1 ]; then
  echo "Dry run: nothing was changed."
  exit 0
fi

git checkout --quiet -b "$RELEASE_WORK_BRANCH"
awk -v v="$NEW_VERSION" '!done && /^version:/ { print "version: " v; done = 1; next } { print }' pubspec.yaml > pubspec.yaml.tmp
mv pubspec.yaml.tmp pubspec.yaml
git add pubspec.yaml
git commit --quiet -m "$PR_TITLE"

if ! git push --quiet -u origin "$RELEASE_WORK_BRANCH"; then
  git checkout --quiet "$RELEASE_BRANCH"
  printf '%sPush failed.%s The release commit exists only on the branch %s. Back on %s. To undo: git branch -D %s\n' "$RED" "$RESET" "$RELEASE_WORK_BRANCH" "$RELEASE_BRANCH" "$RELEASE_WORK_BRANCH" >&2
  exit 1
fi
git checkout --quiet "$RELEASE_BRANCH"

printf '\n%sPushed %s.%s Back on %s.\n\n' "$GREEN" "$RELEASE_WORK_BRANCH" "$RESET" "$RELEASE_BRANCH"

# open_pull_request: gh creates the pull request and asks GitHub to squash
# merge it as soon as the required check passes. Returns 1 when gh is missing,
# not signed in, or any step fails, so the caller prints the manual steps.
open_pull_request() {
  command -v gh > /dev/null 2>&1 || return 1
  gh auth status > /dev/null 2>&1 || return 1
  gh pr create --base "$RELEASE_BRANCH" --head "$RELEASE_WORK_BRANCH" \
    --title "$PR_TITLE" --body "$PR_BODY" || return 1
  gh pr merge "$RELEASE_WORK_BRANCH" --auto --squash || return 1
}

if open_pull_request; then
  printf '\n%sAuto-merge is on.%s When the check passes the pull request merges and the release starts by itself.\n' "$GREEN" "$RESET"
else
  PR_LINK="$REMOTE/compare/${RELEASE_BRANCH}...${RELEASE_WORK_BRANCH}?expand=1"
  if command -v perl > /dev/null 2>&1; then
    PR_LINK+="&title=$(url_encode "$PR_TITLE")&body=$(url_encode "$PR_BODY")"
  fi
  printf 'Next (the GitHub CLI is not available, so do this on GitHub):\n'
  printf '  1. Open the pull request (title and description are filled in): %s\n' "$PR_LINK"
  printf '     The title must stay exactly:  %s%s%s\n' "$BOLD" "$PR_TITLE" "$RESET"
  printf '  2. Press "Create pull request", then "Enable auto-merge" (Squash and merge). Once the check passes it merges.\n'
  printf '  3. The merge starts the release of %s; there is nothing else to run.\n' "$NEW_VERSION"
fi
printf 'Follow it at %s/actions\n' "$REMOTE"
printf 'After the merge, go back to main and remove the merged local branches:  bash scripts/utils/git_helper.sh clean\n'
printf 'To put the same version on Google Play afterwards (from main):  bash scripts/distribution/release/release_play.sh\n'

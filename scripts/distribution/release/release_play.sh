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

# release_play.sh
# Build the prod app bundle (.aab) and upload it to Google Play from this
# machine. Nothing else runs it: a release on GitHub goes to Firebase only.
# Only the bundle is uploaded; the store listing and "What's new" are edited in
# the Play Console.
#
# Usage: bash scripts/distribution/release/release_play.sh [track] [options]
#   track                 internal | alpha | beta | production (default: ask)
#                           internal    testers you invite by email
#                           alpha       closed testing
#                           beta        open testing
#                           production  everybody
#   --rollout FRACTION    staged rollout, production only, for example 0.1
#   --draft               leave the release as a draft in the Play Console
#   --validate            let Google Play check the upload and publish nothing
#   --credentials FILE    Google Play service account JSON
#                         (or set PLAY_SERVICE_CREDENTIALS)
#   --dry-run             check everything and show the command; run nothing
#   --yes                 do not ask for confirmation
#
# Needs Ruby and Bundler (docs/ci-cd.md, Build dev on your machine), the prod
# keystore (android/key.properties) and a Play service account (docs/ci-cd.md,
# Google Play). The version comes from pubspec.yaml; its build number must be
# higher than every bundle already on Google Play.

set -euo pipefail

# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
cd_project_root

TRACK=""; ROLLOUT=""; DRAFT=0; VALIDATE=0; DRY=0; YES=0

parse_args() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      internal|alpha|beta|production) TRACK="$1" ;;
      --rollout) ROLLOUT="${2:?--rollout needs a fraction such as 0.1}"; shift ;;
      --draft) DRAFT=1 ;;
      --validate) VALIDATE=1 ;;
      --credentials) PLAY_SERVICE_CREDENTIALS="${2:?--credentials needs a file}"; export PLAY_SERVICE_CREDENTIALS; shift ;;
      --dry-run) DRY=1 ;;
      --yes) YES=1 ;;
      -h|--help) print_usage; exit 0 ;;
      *) die "Unknown argument '$1'. Run with --help." ;;
    esac
    shift
  done
}

# valid_rollout <value>: a number above 0 and up to 1.
valid_rollout() {
  printf '%s' "$1" | grep -Eq '^([01]|0?\.[0-9]+|[01]\.[0-9]+)$' \
    && awk -v r="$1" 'BEGIN { exit !(r + 0 > 0 && r + 0 <= 1) }'
}

# Asks for a staged rollout on production when none was given.
ask_rollout() {
  local answer
  printf 'Staged rollout? Enter a fraction such as 0.1, or press Enter to release to everybody: '
  if ! read -r answer; then die "No input."; fi
  answer="$(printf '%s' "$answer" | tr -d '[:space:]')"
  if [[ -z "$answer" ]]; then return 0; fi
  valid_rollout "$answer" || die "A rollout must be a number above 0 and up to 1."
  ROLLOUT="$answer"
}

check_options() {
  if [[ -n "$ROLLOUT" ]]; then
    valid_rollout "$ROLLOUT" || die "A rollout must be a number above 0 and up to 1."
    if [[ "$TRACK" != production ]]; then die "A staged rollout is only for the production track."; fi
    if [[ "$DRAFT" = 1 ]]; then die "A staged rollout cannot be a draft."; fi
  fi
}

check_requirements() {
  if ! command -v bundle > /dev/null 2>&1; then
    blocker "Bundler not found. Set up Ruby first: docs/ci-cd.md, Build dev on your machine."
  fi
  local key="${PLAY_SERVICE_CREDENTIALS:-}"
  if [[ -z "$key" ]] || [[ ! -f "$key" ]]; then
    blocker "PLAY_SERVICE_CREDENTIALS must point to the Google Play service account JSON (or pass --credentials FILE)."
  fi
  if [[ ! -f android/key.properties ]] && [[ -z "${ANDROID_KEYSTORE_PATH:-}" ]]; then
    blocker "A prod bundle needs android/key.properties (docs/ci-cd.md, One-time setup, step 3)."
  fi
}

# build_command: the fastlane command, in the global array CMD.
build_command() {
  CMD=(bundle exec fastlane android publish_play "track:$TRACK")
  if [[ -n "$ROLLOUT" ]]; then CMD+=("rollout:$ROLLOUT"); fi
  if [[ "$DRAFT" = 1 ]]; then CMD+=("release_status:draft"); fi
  if [[ "$VALIDATE" = 1 ]]; then CMD+=("validate_only:true"); fi
}

show_plan() {
  local mode="upload and publish" reach="everybody"
  if [[ "$VALIDATE" = 1 ]]; then mode="validate only (nothing is published)"; fi
  if [[ "$DRAFT" = 1 ]]; then mode="upload as a draft"; fi
  if [[ -n "$ROLLOUT" ]]; then reach="$ROLLOUT of the users"; fi
  printf '\n%sGoogle Play%s\n' "$BOLD" "$RESET"
  printf '  Track   : %s\n  Version : %s (pubspec.yaml; the build number must be new on Google Play)\n' "$TRACK" "$(pubspec_version)"
  printf '  Mode    : %s\n' "$mode"
  if [[ "$TRACK" = production ]]; then printf '  Reaches : %s\n' "$reach"; fi
  printf '  Command : %s\n\n' "${CMD[*]}"
}

main() {
  parse_args "$@"
  if [[ -n "${PLAY_SERVICE_CREDENTIALS:-}" ]]; then
    PLAY_SERVICE_CREDENTIALS="$(abs_path "$PLAY_SERVICE_CREDENTIALS")"
    export PLAY_SERVICE_CREDENTIALS
  fi
  if [[ -z "$TRACK" ]]; then
    choose "Google Play track (internal: invited testers, alpha: closed, beta: open, production: everybody)" \
      internal alpha beta production
    TRACK="$REPLY_VALUE"
  fi
  if [[ "$TRACK" = production ]] && [[ -z "$ROLLOUT" ]] && [[ "$YES" = 0 ]] && [[ "$DRY" = 0 ]] \
    && [[ "$DRAFT" = 0 ]] && [[ "$VALIDATE" = 0 ]]; then
    ask_rollout
  fi
  check_options
  check_requirements
  build_command
  show_plan

  if [[ "$DRY" = 1 ]]; then echo "Dry run: nothing was run."; return 0; fi
  if [[ "$TRACK" = production ]] && [[ "$DRAFT" = 0 ]] && [[ "$VALIDATE" = 0 ]]; then
    warn "This release reaches real users."
  fi
  if [[ "$YES" = 0 ]] && ! ask_yes_no "Build the bundle and upload it to the $TRACK track?"; then
    echo "Cancelled; nothing was uploaded."
    return 0
  fi
  if ! "${CMD[@]}"; then
    die "The upload failed. If this app has never been uploaded to Google Play, create it in the Play Console and upload the first bundle by hand (docs/ci-cd.md, Google Play)."
  fi
}

main "$@"

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

# config_firebase.sh
# Run `flutterfire configure` for the Evermoon Firebase projects, then copy the
# native config files into the per-flavor folders. The native files and the
# generated options are what a fresh clone lacks (google-services.json and
# GoogleService-Info.plist are gitignored).
#
# Usage: bash scripts/setup/config_firebase.sh [dev|prod]
#   (no argument)  both flavors, dev then prod
#   dev | prod     only that flavor
#
# Needs: firebase-tools (npm install -g firebase-tools), fvm, and flutterfire_cli
# (fvm dart pub global activate flutterfire_cli).
# The root copies android/app/google-services.json and
# ios/Runner/GoogleService-Info.plist end up holding the last flavor configured;
# the per-flavor folders are the source of truth.

set -euo pipefail

# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
cd_project_root

FLAVORS=(dev prod)

# flavor_config <flavor>: sets PROJECT_ID and APP_ID. The Android package and
# the iOS bundle id are the same string for each flavor.
flavor_config() {
  case "$1" in
    dev)  PROJECT_ID="evermoon-dev";   APP_ID="com.fox.evermoon.dev" ;;
    prod) PROJECT_ID="evermoon-2cc28"; APP_ID="com.fox.evermoon" ;;
    *) die "No Firebase config for flavor '$1'." ;;
  esac
}

check_tools() {
  command -v firebase > /dev/null 2>&1 \
    || die "Firebase CLI not found. Install it: npm install -g firebase-tools"
  command -v fvm > /dev/null 2>&1 \
    || die "fvm not found. Install it first; this project pins Flutter with fvm."
  local globals
  globals="$(fvm dart pub global list 2> /dev/null || true)"
  case "$globals" in
    *flutterfire_cli*) ;;
    *) die "flutterfire_cli not found. Install it: fvm dart pub global activate flutterfire_cli" ;;
  esac
}

# Shows the logged-in account and lets the user switch; logs in when needed.
check_login() {
  local listing user
  listing="$(firebase login:list 2> /dev/null || true)"
  user="$(printf '%s' "$listing" | grep -oE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' | head -1 || true)"

  if [[ -z "$user" ]]; then
    echo "Not logged in to Firebase. Running: firebase login"
    firebase login
    return
  fi
  echo "Logged in to Firebase as $user"
  if ask_yes_no "Switch to another account?"; then
    firebase logout
    firebase login
  fi
}

# copy_native_config <source file> <destination dir> <flavor>
copy_native_config() {
  local src="$1" dest_dir="$2" flavor="$3"
  if [[ ! -f "$src" ]]; then
    warn "[$flavor] $src not found, skipped."
    return 0
  fi
  mkdir -p "$dest_dir"
  cp "$src" "$dest_dir/$(basename "$src")"
  ok "[$flavor] $(basename "$src") copied to $dest_dir/"
}

# configure_flavor <flavor>: returns 1 when flutterfire fails. The failure is
# checked here by hand because set -e is off inside a function called from ||.
configure_flavor() {
  local flavor="$1"
  local out="lib/firebase/$flavor/firebase_options.dart"
  flavor_config "$flavor"

  printf '\n%s[%s]%s project=%s  app id=%s\n' "$BOLD" "$flavor" "$RESET" "$PROJECT_ID" "$APP_ID"
  if ! fvm dart pub global run flutterfire_cli:flutterfire configure \
    --project="$PROJECT_ID" \
    --out="$out" \
    --platforms=android,ios \
    --android-package-name="$APP_ID" \
    --ios-bundle-id="$APP_ID" \
    --yes; then
    warn "[$flavor] flutterfire configure failed."
    return 1
  fi
  ok "[$flavor] firebase_options.dart written to $out"

  copy_native_config android/app/google-services.json "android/app/src/$flavor" "$flavor"
  copy_native_config ios/Runner/GoogleService-Info.plist "ios/config/$flavor" "$flavor"
}

TARGETS=("${FLAVORS[@]}")
if [[ "$#" -gt 1 ]]; then die "Too many arguments. Use: bash scripts/setup/config_firebase.sh [dev|prod]"; fi
if [[ "$#" -eq 1 ]]; then
  case "$1" in
    -h|--help) print_usage; exit 0 ;;
    dev|prod) TARGETS=("$1") ;;
    *) die "Unknown flavor '$1'. Use dev or prod." ;;
  esac
fi

check_tools
check_login
printf '%sFlavors:%s %s\n' "$DIM" "$RESET" "${TARGETS[*]}"

failed=()
for flavor in "${TARGETS[@]}"; do
  configure_flavor "$flavor" || failed+=("$flavor")
done

if [[ "${#failed[@]}" -gt 0 ]]; then
  die "Failed for: ${failed[*]}"
fi
printf '\n%sDone.%s\n' "$GREEN" "$RESET"

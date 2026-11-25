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

# signing_fingerprints.sh
# Prints the SHA-1 and SHA-256 fingerprints of the Android prod keystore named
# in android/key.properties, and what to do with them. Needs only keytool.
#
# Usage: bash scripts/utils/signing_fingerprints.sh

set -euo pipefail

# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
cd_project_root

PROPS=android/key.properties
[[ -f "$PROPS" ]] || die "Missing $PROPS (see docs/ci-cd.md, One-time setup, step 3)."

prop() { sed -n -E "s/^$1=(.*)$/\1/p" "$PROPS" | head -1; }

STORE_FILE="$(prop storeFile)"
ALIAS="$(prop keyAlias)"
# storeFile is relative to android/app, like Gradle's file().
KEYSTORE="android/app/$STORE_FILE"
[[ -f "$KEYSTORE" ]] || die "Keystore not found: $KEYSTORE"

KEYTOOL="keytool"
if ! command -v keytool > /dev/null 2>&1 && [[ -x /usr/libexec/java_home ]]; then
  KEYTOOL="$(/usr/libexec/java_home)/bin/keytool"
fi

# The password reaches keytool through the environment, not the command line.
STOREPASS="$(prop storePassword)" "$KEYTOOL" -list -v -keystore "$KEYSTORE" -alias "$ALIAS" \
  -storepass:env STOREPASS 2> /dev/null | grep -E '^\s*(SHA1|SHA256):' | sed -E 's/^[[:space:]]*//' \
  || die "keytool could not read the keystore: wrong password or alias in $PROPS?"

cat <<'EOF'

What to do with them:
  1. Firebase console, project evermoon-2cc28, Project settings, the Android prod
     app, Add fingerprint: paste SHA-1 and SHA-256 (needed for Google sign-in).
  2. GitHub, Settings, Environments, prod, Variables (not secrets), add
     ANDROID_SIGNING_SHA256 with the SHA256 value above. The release workflow
     then fails if the APK is signed with any other key.
EOF

#!/usr/bin/env bash
# Prints the SHA-1 and SHA-256 fingerprints of the Android prod keystore named
# in android/key.properties, and what to do with them. Needs only keytool.
#
# Usage: bash scripts/signing_fingerprints.sh
set -euo pipefail

cd "$(dirname "$0")/.."
PROPS=android/key.properties

[ -f "$PROPS" ] || { echo "Missing $PROPS (see docs/ci-cd.md, One-time setup, step 3)." >&2; exit 1; }

prop() { sed -n -E "s/^$1=(.*)$/\1/p" "$PROPS" | head -1; }

STORE_FILE="$(prop storeFile)"
ALIAS="$(prop keyAlias)"
# storeFile is relative to android/app, like Gradle's file().
KEYSTORE="android/app/$STORE_FILE"
[ -f "$KEYSTORE" ] || { echo "Keystore not found: $KEYSTORE" >&2; exit 1; }

KEYTOOL="keytool"
if ! command -v keytool > /dev/null 2>&1 && [ -x /usr/libexec/java_home ]; then
  KEYTOOL="$(/usr/libexec/java_home)/bin/keytool"
fi

# The password reaches keytool through the environment, not the command line.
STOREPASS="$(prop storePassword)" "$KEYTOOL" -list -v -keystore "$KEYSTORE" -alias "$ALIAS" \
  -storepass:env STOREPASS 2> /dev/null | grep -E '^\s*(SHA1|SHA256):' | sed -E 's/^[[:space:]]*//' || {
  echo "keytool could not read the keystore: wrong password or alias in $PROPS?" >&2
  exit 1
}

cat <<'EOF'

What to do with them:
  1. Firebase console, project evermoon-2cc28, Project settings, the Android prod
     app, Add fingerprint: paste SHA-1 and SHA-256 (needed for Google sign-in).
  2. GitHub, Settings, Environments, prod, Variables (not secrets), add
     ANDROID_SIGNING_SHA256 with the SHA256 value above. The release workflow
     then fails if the APK is signed with any other key.
EOF

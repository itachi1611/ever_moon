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

# og_image_data_uri.sh
# Downloads an image and prints it as a small data URI (JPEG) on stdout.
# Used by the release workflow: Microsoft Teams cannot always load the preview
# image of a GitHub release from its URL, but it shows an image embedded in the
# card. A Teams message is limited to about 28 KB, so the image is shrunk until
# it fits the byte budget.
#
# Usage: bash scripts/distribution/notify/og_image_data_uri.sh <image-url> [max-bytes]
# Exit status 1 (nothing printed) when the image cannot be fetched or shrunk;
# the caller then falls back to a plain image URL.

set -euo pipefail

URL="${1:?usage: og_image_data_uri.sh <image-url> [max-bytes]}"
MAX="${2:-11000}"

# ImageMagick 7 is "magick", version 6 is "convert".
if command -v magick >/dev/null 2>&1; then IM=magick
elif command -v convert >/dev/null 2>&1; then IM=convert
else
  printf 'ImageMagick is not installed\n' >&2
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

curl -fsSL --max-time 30 -o "$WORK/in" "$URL"

# From the largest and best to the smallest; the first one under the budget wins.
for width in 640 560 480 400; do
  for quality in 70 55 40; do
    "$IM" "$WORK/in" -background white -alpha remove -alpha off \
      -resize "${width}x" -strip -sampling-factor 4:2:0 -quality "$quality" "$WORK/out.jpg"
    size="$(wc -c < "$WORK/out.jpg" | tr -d ' ')"
    if [[ "$size" -le "$MAX" ]]; then
      printf 'data:image/jpeg;base64,%s' "$(base64 < "$WORK/out.jpg" | tr -d '\n')"
      exit 0
    fi
  done
done

printf 'No size reached %s bytes\n' "$MAX" >&2
exit 1

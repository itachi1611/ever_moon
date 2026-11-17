#!/bin/bash
# Re-exec with bash if invoked via sh/dash
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

# notify.sh
# Tell the team how a release went. Sends to every channel that has its
# variables set, and does nothing when none is set. A failed send is reported
# as a warning and never fails the release: the build is already published.
#
# Input (environment):
#   NOTIFY_STATUS   success | failure | cancelled | skipped
#   NOTIFY_TITLE    one line, for example "Evermoon 1.0.1+2"
#   NOTIFY_BODY     optional, several lines (the changelog)
#   NOTIFY_URL      optional link to the workflow run
#   NOTIFY_FACTS    optional, one "Label: value" per line (version, Flutter, job results)
#   NOTIFY_RELEASE_URL  optional link to the GitHub Release
#   NOTIFY_DRY_RUN  set to 1 to print the messages instead of sending them
# Channels:
#   TEAMS_WEBHOOK_URL                        Microsoft Teams (Workflows webhook)
#   TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID  Telegram bot
#   DISCORD_WEBHOOK_URL                      Discord channel webhook

set -uo pipefail

STATUS="${NOTIFY_STATUS:-unknown}"
TITLE="${NOTIFY_TITLE:-Evermoon release}"
BODY="${NOTIFY_BODY:-}"
URL="${NOTIFY_URL:-}"
FACTS="${NOTIFY_FACTS:-}"
RELEASE_URL="${NOTIFY_RELEASE_URL:-}"
DRY="${NOTIFY_DRY_RUN:-0}"

# Plain text, used by Telegram.
TEXT="[Evermoon] ${TITLE}"$'\n'"Result: ${STATUS}"
if [ -n "$FACTS" ]; then TEXT="${TEXT}"$'\n'"${FACTS}"; fi
if [ -n "$BODY" ]; then TEXT="${TEXT}"$'\n\n'"${BODY}"; fi
if [ -n "$URL" ]; then TEXT="${TEXT}"$'\n\n'"${URL}"; fi

# Each service limits the message length; cut with a visible marker.
limit() {
  local max="$1"
  if [ "${#TEXT}" -le "$max" ]; then printf '%s' "$TEXT"
  else printf '%s' "$TEXT" | head -c "$max"; printf '\n... (truncated)'
  fi
}

# build_payload teams|discord: a rich card (Teams) or embed (Discord) as JSON.
# Python builds it so quotes and Vietnamese text are escaped correctly.
build_payload() {
  KIND="$1" STATUS="$STATUS" TITLE="$TITLE" BODY="$BODY" URL="$URL" FACTS="$FACTS" \
    RELEASE_URL="$RELEASE_URL" python3 - <<'PY'
import json, os, re

e = os.environ
kind, status = e["KIND"], e["STATUS"]
title, body, url = e["TITLE"], e["BODY"], e["URL"]
release_url = e["RELEASE_URL"]

headline, style, color, embed_color = {
    "success": ("Release succeeded", "good", "Good", 0x2ECC71),
    "failure": ("Release failed", "attention", "Attention", 0xE74C3C),
    "cancelled": ("Release cancelled", "warning", "Warning", 0xF1C40F),
}.get(status, ("Release " + status, "emphasis", "Default", 0x95A5A6))

facts = []
for line in e["FACTS"].splitlines():
    if ":" in line:
        key, value = line.split(":", 1)
        facts.append((key.strip(), value.strip() or "-"))


def cut(text, limit):
    return text if len(text) <= limit else text[:limit].rstrip() + "\n... (truncated)"


def teams_text(markdown):
    # Teams cards render a subset of markdown: no headings, and a line break
    # needs a blank line.
    markdown = re.sub(r"^#+\s*(.+)$", r"**\1**", markdown, flags=re.M)
    return markdown.replace("\n", "\n\n")


if kind == "teams":
    card_body = [{
        "type": "Container", "style": style, "bleed": True,
        "items": [
            {"type": "TextBlock", "text": "EVERMOON", "size": "Small", "weight": "Bolder", "isSubtle": True},
            {"type": "TextBlock", "text": title, "size": "Large", "weight": "Bolder", "wrap": True},
            {"type": "TextBlock", "text": headline, "weight": "Bolder", "color": color, "wrap": True, "spacing": "Small"},
        ],
    }]
    if facts:
        card_body.append({"type": "FactSet", "facts": [{"title": k, "value": v} for k, v in facts]})
    if body:
        card_body.append({"type": "TextBlock", "text": "What changed", "weight": "Bolder", "separator": True, "spacing": "Medium"})
        card_body.append({"type": "TextBlock", "text": cut(teams_text(body), 12000), "wrap": True})
    actions = []
    if url:
        actions.append({"type": "Action.OpenUrl", "title": "Open the run", "url": url})
    if release_url:
        actions.append({"type": "Action.OpenUrl", "title": "Open the release", "url": release_url})
    card = {
        "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "type": "AdaptiveCard", "version": "1.3",
        "msteams": {"width": "Full"}, "body": card_body,
    }
    if actions:
        card["actions"] = actions
    payload = {"type": "message", "attachments": [
        {"contentType": "application/vnd.microsoft.card.adaptive", "content": card}]}
else:
    embed = {
        "title": cut(title, 250), "description": cut(body, 3500) or headline,
        "color": embed_color, "footer": {"text": "Evermoon  |  " + headline},
        "fields": [{"name": k[:250], "value": v[:1000], "inline": True} for k, v in facts[:25]],
    }
    if url:
        embed["url"] = url
    payload = {"embeds": [embed]}

print(json.dumps(payload, ensure_ascii=False))
PY
}

# post <name> <curl args...>; the body is read from stdin where a payload is needed.
send() {
  local name="$1"; shift
  if [ "$DRY" = 1 ]; then
    printf -- '--- %s (dry run) ---\n' "$name"
    return 0
  fi
  if curl --silent --show-error --fail-with-body --max-time 20 "$@" > /dev/null; then
    printf 'Notified %s\n' "$name"
  else
    printf '::warning::Notification to %s failed\n' "$name"
  fi
}

SENT=0

if [ -n "${TEAMS_WEBHOOK_URL:-}" ]; then
  SENT=1
  PAYLOAD="$(build_payload teams)"
  if [ "$DRY" = 1 ]; then printf '%s\n' "$PAYLOAD"; fi
  send Teams -X POST -H 'Content-Type: application/json' -d "$PAYLOAD" "$TEAMS_WEBHOOK_URL"
fi

if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
  SENT=1
  MESSAGE="$(limit 3500)"
  if [ "$DRY" = 1 ]; then printf '%s\n' "$MESSAGE"; fi
  send Telegram -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" --data-urlencode "text=${MESSAGE}"
fi

if [ -n "${DISCORD_WEBHOOK_URL:-}" ]; then
  SENT=1
  PAYLOAD="$(build_payload discord)"
  if [ "$DRY" = 1 ]; then printf '%s\n' "$PAYLOAD"; fi
  send Discord -X POST -H 'Content-Type: application/json' -d "$PAYLOAD" "$DISCORD_WEBHOOK_URL"
fi

if [ "$SENT" = 0 ]; then
  echo "No notification channel is configured; nothing sent."
fi
exit 0

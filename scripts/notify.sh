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
#   NOTIFY_STATUS       success | failure | cancelled | skipped
#   NOTIFY_TITLE        one line, for example "Evermoon 1.0.1+2 (prod)"
#   NOTIFY_BODY         optional, several lines (the changelog, Conventional Commit groups)
#   NOTIFY_URL          optional link to the workflow run
#   NOTIFY_RELEASE_URL  optional link to the GitHub Release (a public repo gives a link preview)
#   NOTIFY_BANNER_URL   optional public https image, shown at the top of the Teams card
#   NOTIFY_FACTS        optional, one "Label: value" per line (version, Flutter, job results)
#   NOTIFY_DRY_RUN      set to 1 to print the messages instead of sending them
# Channels:
#   TEAMS_WEBHOOK_URL                        Microsoft Teams (Workflows webhook)
#   TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID  Telegram bot
#   DISCORD_WEBHOOK_URL                      Discord channel webhook

set -uo pipefail

STATUS="${NOTIFY_STATUS:-unknown}"
TITLE="${NOTIFY_TITLE:-Evermoon release}"
BODY="${NOTIFY_BODY:-}"
URL="${NOTIFY_URL:-}"
RELEASE_URL="${NOTIFY_RELEASE_URL:-}"
BANNER_URL="${NOTIFY_BANNER_URL:-}"
FACTS="${NOTIFY_FACTS:-}"
DRY="${NOTIFY_DRY_RUN:-0}"

# build_payload teams|discord|telegram: the JSON body for one channel. Python
# builds it so quotes, HTML and Vietnamese text are escaped correctly.
build_payload() {
  KIND="$1" STATUS="$STATUS" TITLE="$TITLE" BODY="$BODY" URL="$URL" FACTS="$FACTS" \
    RELEASE_URL="$RELEASE_URL" BANNER_URL="$BANNER_URL" CHAT_ID="${TELEGRAM_CHAT_ID:-}" python3 - <<'PY'
import html, json, os, re

e = os.environ
kind, status = e["KIND"], e["STATUS"]
title, body, url = e["TITLE"], e["BODY"], e["URL"]
release_url, banner = e["RELEASE_URL"], e["BANNER_URL"]

headline, style, color, embed_color, mark = {
    "success": ("Release succeeded", "good", "Good", 0x2ECC71, "✅"),
    "failure": ("Release failed", "attention", "Attention", 0xE74C3C, "❌"),
    "cancelled": ("Release cancelled", "warning", "Warning", 0xF1C40F, "⚠️"),
}.get(status, ("Release " + status, "emphasis", "Default", 0x95A5A6, "ℹ️"))

facts = []
for line in e["FACTS"].splitlines():
    if ":" in line:
        key, value = line.split(":", 1)
        facts.append((key.strip(), value.strip() or "-"))


def blocks(limit):
    """Changelog lines as (kind, text, sha); stops with a marker at the limit."""
    out, used = [], 0
    for line in body.splitlines():
        line = line.rstrip()
        if not line:
            continue
        heading = re.match(r"^#+\s*(.+)$", line)
        if heading:
            item = ("h", heading.group(1).strip(), "")
        else:
            text = re.sub(r"^[-*]\s+", "", line)
            sha = re.search(r"\s\(([0-9a-f]{7,40})\)$", text)
            item = ("b", text[:sha.start()] if sha else text, sha.group(1) if sha else "")
        cost = len(item[1]) + len(item[2]) + 6
        if used + cost > limit:
            out.append(("p", "... (truncated)", ""))
            break
        out.append(item)
        used += cost
    return out


def render(items, heading, bullet):
    lines = []
    for kind_, text, sha in items:
        if kind_ == "h":
            lines.append(heading(text))
        elif kind_ == "b":
            lines.append(bullet(text, sha))
        else:
            lines.append(text)
    return "\n".join(lines)


if kind == "teams":
    text = render(blocks(11000),
                  lambda t: "**" + t + "**",
                  lambda t, s: "• " + t + (" (" + s + ")" if s else "")).replace("\n", "\n\n")
    card_body = []
    if banner:
        card_body.append({"type": "Image", "url": banner, "size": "Stretch", "altText": "Evermoon"})
    card_body.append({
        "type": "Container", "style": style, "bleed": True,
        "items": [
            {"type": "TextBlock", "text": title, "size": "Large", "weight": "Bolder", "wrap": True},
            {"type": "TextBlock", "text": headline, "weight": "Bolder", "color": color, "wrap": True, "spacing": "Small"},
        ],
    })
    if facts:
        card_body.append({"type": "FactSet", "facts": [{"title": k, "value": v} for k, v in facts]})
    if text:
        card_body.append({"type": "TextBlock", "text": "What changed", "weight": "Bolder", "separator": True, "spacing": "Medium"})
        card_body.append({"type": "TextBlock", "text": text, "wrap": True})
    actions = []
    if release_url:
        actions.append({"type": "Action.OpenUrl", "title": "Open the release", "url": release_url})
    if url:
        actions.append({"type": "Action.OpenUrl", "title": "Open the run", "url": url})
    card = {
        "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "type": "AdaptiveCard", "version": "1.3",
        "msteams": {"width": "Full"}, "body": card_body,
    }
    if actions:
        card["actions"] = actions
    payload = {"type": "message", "attachments": [
        {"contentType": "application/vnd.microsoft.card.adaptive", "content": card}]}

elif kind == "discord":
    text = render(blocks(3300),
                  lambda t: "**" + t + "**",
                  lambda t, s: "• " + t + (" (`" + s + "`)" if s else ""))
    embed = {
        "author": {"name": "Evermoon · Release"},
        "title": title[:250], "description": text or headline, "color": embed_color,
        "fields": [{"name": k[:250], "value": v[:1000], "inline": True} for k, v in facts[:25]],
        "footer": {"text": mark + "  " + headline},
    }
    if release_url or url:
        embed["url"] = release_url or url
    payload = {"embeds": [embed], "allowed_mentions": {"parse": []}}
    if release_url:
        # A bare link in the message text makes Discord unfold the repository preview.
        payload["content"] = release_url

else:
    esc = html.escape
    lines = [mark + " <b>" + esc(title) + "</b>", esc(headline)]
    lines += ["<b>" + esc(k) + ":</b> " + esc(v) for k, v in facts]
    changelog = render(blocks(2800),
                       lambda t: "\n<b>" + esc(t) + "</b>",
                       lambda t, s: "• " + esc(t) + (" (<code>" + esc(s) + "</code>)" if s else ""))
    if changelog:
        lines.append(changelog)
    buttons = []
    if release_url:
        buttons.append({"text": "Open the release", "url": release_url})
    if url:
        buttons.append({"text": "Open the run", "url": url})
    payload = {
        "chat_id": e["CHAT_ID"], "text": "\n".join(lines), "parse_mode": "HTML",
        "link_preview_options": (
            {"url": release_url, "prefer_large_media": True, "show_above_text": False}
            if release_url else {"is_disabled": True}),
    }
    if buttons:
        payload["reply_markup"] = {"inline_keyboard": [buttons]}

print(json.dumps(payload, ensure_ascii=False))
PY
}

# send <name> <curl args...>
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
  PAYLOAD="$(build_payload telegram)"
  if [ "$DRY" = 1 ]; then printf '%s\n' "$PAYLOAD"; fi
  send Telegram -X POST -H 'Content-Type: application/json' -d "$PAYLOAD" \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
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

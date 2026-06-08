#!/bin/bash
# Claude Code hook notification wrapper.
# Usage: cc-notify.sh <group> <message> <sound> [focus]
#   group   — unique id, currently informational (e.g. "input", "stop")
#   message — banner body
#   sound   — macOS system sound name (Glass, Hero, Ping, Pop, …) or "none"
#   focus   — if "focus", pull the terminal tab to the front when another app
#             is currently frontmost. Skipped if the terminal is already
#             frontmost so it never steals focus mid-typing.
#
# Reads $ITERM_SESSION_ID and $TERM_PROGRAM from the env so the focus helper
# can target the exact iTerm tab that fired the hook.

MSG="${2:-Claude Code}"
SND="${3:-}"
MODE="${4:-}"

# Claude Code pipes the hook event as JSON on stdin. If this Notification event
# is a tool-permission ask (message contains "permission to use"), suppress the
# alert — the user is here, they'll see the inline prompt; no need to chime or
# steal focus.
if [ ! -t 0 ]; then
  PAYLOAD=$(cat)
  if echo "$PAYLOAD" | grep -q '"message"[[:space:]]*:[[:space:]]*"[^"]*permission to use'; then
    exit 0
  fi
fi

COOLDOWN="${CC_NOTIFY_COOLDOWN:-30}"
STATE_FILE="${CC_NOTIFY_STATE:-$HOME/.claude/cc-notify.state}"
NOW=$(date +%s)

if [ "$MODE" = "focus" ]; then
  FRONT=$(osascript -e 'tell application "System Events" to name of first process whose frontmost is true' 2>/dev/null)
  case "$FRONT" in
    iTerm|iTerm2|Terminal|WarpTerminal|Warp|Ghostty|Hyper|WezTerm|Code)
      # User is already on a terminal/IDE — they'll see Claude Code inline,
      # so suppress the banner and chime entirely.
      exit 0
      ;;
  esac

  # Cooldown — Claude Code's Notification hook fires on every turn end
  # ("Claude is waiting for your input"). Without pacing, rapid-fire turns
  # chime repeatedly while the user is in the loop (e.g. reading from Arc).
  # Override with CC_NOTIFY_COOLDOWN env var.
  if [ -f "$STATE_FILE" ]; then
    LAST=$(tr -d '[:space:]' < "$STATE_FILE" 2>/dev/null)
    if [ -n "$LAST" ] && [ "$LAST" -gt 0 ] 2>/dev/null && [ $((NOW - LAST)) -lt "$COOLDOWN" ]; then
      exit 0
    fi
  fi
fi

SOUND_CLAUSE=""
if [ -n "$SND" ] && [ "$SND" != "none" ]; then
  SOUND_CLAUSE=" sound name \"$SND\""
fi
osascript -e "display notification \"${MSG//\"/\\\"}\" with title \"Claude Code\"$SOUND_CLAUSE"

if [ "$MODE" = "focus" ]; then
  echo "$NOW" > "$STATE_FILE"
  DIR="$(cd "$(dirname "$0")" && pwd)"
  if [ -x "$DIR/cc-focus.sh" ]; then
    SID="${ITERM_SESSION_ID##*:}"
    "$DIR/cc-focus.sh" "$SID" "$TERM_PROGRAM"
  fi
fi

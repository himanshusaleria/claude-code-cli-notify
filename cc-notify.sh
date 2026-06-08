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

SOUND_CLAUSE=""
if [ -n "$SND" ] && [ "$SND" != "none" ]; then
  SOUND_CLAUSE=" sound name \"$SND\""
fi
osascript -e "display notification \"${MSG//\"/\\\"}\" with title \"Claude Code\"$SOUND_CLAUSE"

if [ "$MODE" = "focus" ]; then
  FRONT=$(osascript -e 'tell application "System Events" to name of first process whose frontmost is true' 2>/dev/null)
  case "$FRONT" in
    iTerm|iTerm2|Terminal) ;;  # already on a terminal — don't steal focus
    *)
      DIR="$(cd "$(dirname "$0")" && pwd)"
      if [ -x "$DIR/cc-focus.sh" ]; then
        SID="${ITERM_SESSION_ID##*:}"
        "$DIR/cc-focus.sh" "$SID" "$TERM_PROGRAM"
      fi
      ;;
  esac
fi

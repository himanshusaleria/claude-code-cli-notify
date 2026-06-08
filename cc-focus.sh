#!/bin/bash
# Bring the right terminal/tab to the foreground.
# Usage: cc-focus.sh [iterm_session_id] [term_program]
#   iterm_session_id — uuid portion of $ITERM_SESSION_ID (e.g. 1366FE07-...)
#   term_program     — $TERM_PROGRAM at the time the hook fired
#                      ("iTerm.app", "Apple_Terminal", "WarpTerminal", …)

SID="$1"
TERM_PROG="${2:-$TERM_PROGRAM}"

case "$TERM_PROG" in
  iTerm.app|iTerm2)
    if [ -n "$SID" ]; then
      osascript <<EOF
tell application "iTerm"
  activate
  repeat with w in windows
    repeat with t in tabs of w
      repeat with s in sessions of t
        if id of s starts with "$SID" then
          tell w to select t
          tell s to select
          return
        end if
      end repeat
    end repeat
  end repeat
end tell
EOF
    else
      osascript -e 'tell application "iTerm" to activate'
    fi
    ;;
  Apple_Terminal)
    osascript -e 'tell application "Terminal" to activate'
    ;;
  *)
    # Best effort: try to activate whichever app the user said they were in.
    if [ -n "$TERM_PROG" ]; then
      osascript -e "tell application \"$TERM_PROG\" to activate" 2>/dev/null
    fi
    ;;
esac

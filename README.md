# claude-code-cli-notify

> Native macOS notifications for Claude Code — chime when it needs your input, silent banner when it finishes.

Claude Code runs for minutes at a stretch. You switch tabs, lose track, miss the prompt. `claude-code-cli-notify` hooks into Claude Code's lifecycle and:

- **Chimes + brings your iTerm tab to the front** when Claude is waiting on you (permission prompt, idle prompt).
- **Drops a silent banner** when a turn finishes — you can glance, no audible interruption.

No daemons, no background app, just two small shell scripts wired to Claude Code's hook system.

## Install

Requires macOS. Tab-precise focus on iTerm2; app-level focus on Apple Terminal, Warp, Ghostty, Hyper, WezTerm, and the VS Code integrated terminal.

Paste this into any Claude Code session and it'll set everything up globally for every future session:

```
Install claude-code-cli-notify for native macOS notifications across all my Claude Code sessions:

1. Check $TERM_PROGRAM and tell me which terminal you detected — iTerm.app gets tab-precise focus, Apple_Terminal / WarpTerminal / ghostty / Hyper / WezTerm / vscode get app-level focus, anything else is a best-effort fallback. If $TERM_PROGRAM is empty or unfamiliar, ask me to confirm before continuing.
2. If ~/.claude/cc-notify doesn't exist, clone https://github.com/himanshusaleria/claude-code-cli-notify into it.
3. Run: chmod +x ~/.claude/cc-notify/cc-notify.sh ~/.claude/cc-notify/cc-focus.sh
4. Merge (don't overwrite) Notification and Stop hooks into ~/.claude/settings.json:
   - Notification hook command: ~/.claude/cc-notify/cc-notify.sh input "Needs your input" Glass focus
   - Stop hook command: ~/.claude/cc-notify/cc-notify.sh stop "Done" none
5. Test: ~/.claude/cc-notify/cc-notify.sh input "Test" Glass focus
```

### Manual install

```bash
git clone https://github.com/himanshusaleria/claude-code-cli-notify ~/.claude/cc-notify
chmod +x ~/.claude/cc-notify/cc-notify.sh ~/.claude/cc-notify/cc-focus.sh
```

Then merge the hook entries from `settings.example.json` into `~/.claude/settings.json` (a fresh setup is shown below):

```json
{
  "hooks": {
    "Notification": [
      { "hooks": [{ "type": "command", "command": "~/.claude/cc-notify/cc-notify.sh input \"Needs your input\" Glass focus" }] }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": "~/.claude/cc-notify/cc-notify.sh stop \"Done\" none" }] }
    ]
  }
}
```

Restart Claude Code. Verify with `~/.claude/cc-notify/cc-notify.sh input "Test" Glass focus`.

## How it works

Two hooks, two scripts:

- **`cc-notify.sh`** — fires the macOS banner via `osascript` and (optionally) calls the focus helper.
- **`cc-focus.sh`** — reads `$TERM_PROGRAM` and `$ITERM_SESSION_ID` to bring the exact tab to the front. iTerm gets tab-precise targeting via AppleScript; Apple Terminal gets app-level activation.

The focus helper is only invoked when the terminal isn't already frontmost, so it never steals focus while you're typing in iTerm.

## Customize

Each hook command takes positional args: `cc-notify.sh <group> <message> <sound> [focus]`.

| Arg | Meaning |
|-----|---------|
| `group` | Informational id (e.g. `input`, `stop`). Currently unused, reserved for future grouping. |
| `message` | Banner body. |
| `sound` | macOS system sound name from `/System/Library/Sounds`: `Basso`, `Blow`, `Bottle`, `Frog`, `Funk`, `Glass`, `Hero`, `Morse`, `Ping`, `Pop`, `Purr`, `Sosumi`, `Submarine`, `Tink`. Pass `none` for a silent banner. |
| `focus` | Optional. Pass `focus` to bring the iTerm tab forward when iTerm isn't already frontmost. Omit for banner-only. |

Some examples to drop into `~/.claude/settings.json`:

```bash
# Both events chime
cc-notify.sh input "Needs your input" Hero focus
cc-notify.sh stop "Done" Glass

# Quiet defaults — input chimes, stop is silent
cc-notify.sh input "Needs your input" Glass focus
cc-notify.sh stop "Done" none

# Aggressive — focus on every turn end too
cc-notify.sh input "Needs your input" Hero focus
cc-notify.sh stop "Done" Glass focus
```

## Troubleshooting

- **No banner at all?** Check `System Settings → Notifications → Script Editor` — toggle "Allow Notifications" on. macOS banners from `osascript` are attributed to Script Editor.
- **Focus doesn't land on the right iTerm tab?** Confirm `$ITERM_SESSION_ID` is set in your shell (`echo $ITERM_SESSION_ID` should print `wNtNpN:UUID`). If it's empty, your iTerm version may not export it — the helper will fall back to activating iTerm without tab targeting.
- **Using Apple Terminal?** Tab-level focus isn't exposed in Terminal's AppleScript dictionary the same way. The script activates Terminal.app; you'll need to pick the right tab manually.
- **Want zero focus stealing?** Drop `focus` from the Notification hook command.

## License

MIT.

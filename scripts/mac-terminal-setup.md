# Making the terminal look clean for recording (macOS)

Nothing here is automated. You change these yourself.

## Terminal choice
**Option A: Terminal.app**: Settings > Profiles > **Pro** > "Default". Then Text tab: font **SF Mono / Menlo 18-20 pt**,
cursor: block, uncheck "Blink cursor".
**Option B: iTerm2**: Profiles > Colors > Color Presets > **Dark Background** (or "Tango Dark"); Text > Font **JetBrains Mono / Menlo 18-20**;
Window > Style: Compact, hide the tab bar if you only use one tab.

## Window
* Size about **100 x 30** columns/rows (View > Show Window Size), centered, nothing else visible behind it.
* Two panes for the demo: shell on the left, `claude` on the right (iTerm2: Cmd+D). Zoom with Cmd+ + until text is readable from the back row (font 18+ at 1080p).
* Dark theme everywhere (System Settings > Appearance > Dark), same in your editor.

## Short prompt (this session only)
```
export PS1='%F{green}❯%f '          # zsh
export PS1='\[\e[32m\]❯\[\e[0m\] '  # bash
clear
```
Optional: `export KUBECTL_EXTERNAL_DIFF=` is not needed; just avoid long contexts in the prompt (no kube-ps1).

## Hide distractions
* **Dock**: Cmd+Option+D toggles auto-hide.
* **Desktop icons**: System Settings > Desktop & Dock > "Show Items on Desktop" off (or run `defaults write com.apple.finder CreateDesktop false; killall Finder` and undo after).
* **Menu bar**: set to auto-hide while recording (Control Center settings).
* **Do Not Disturb**: Control Center > Focus > Do Not Disturb. Quit Slack, Mail, Messages, calendar pop-ups.
* Close all unrelated browser tabs and windows; switch off the screensaver and display sleep (or run `caffeinate -d` in a spare tab).

## Recording
* **Cmd+Shift+5** > "Record Selected Portion", pick the terminal window, Options > Microphone, "Show Mouse Clicks" off.
* Or `asciinema rec demo.cast` then `agg` to GIF (see `scripts/record.sh`).
* Do one rehearsal with `./scripts/demo-dry-run.sh`, then reset with `./scripts/demo-reset.sh`.

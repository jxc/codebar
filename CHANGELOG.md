# Changelog

## [1.0.0] - 2026-03-22

### Features
- Menu bar status monitoring for active Claude Code sessions
- Two display modes: single circle (highest severity) and all active statuses with counts
- Click-to-focus: click a session row to switch to its iTerm2 tab
- Automatic hook installation/removal via menu
- Preferences window with hook management and debug logging
- Session name display from JSONL transcripts
- Startup backfill from existing session files
- App icon

### Technical
- HTTP hook server on localhost:8089 (Network.framework, zero dependencies)
- Signed and notarized DMG distribution
- Homebrew cask install support (`brew install --cask jxc/tap/codebar`)

## [0.1.0] - 2026-03-22

Initial release.

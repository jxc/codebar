# Changelog

## [1.3.0] - 2026-03-23

### Added
- Color-blind accessibility: distinct shapes (circle, diamond, triangle) per status so states are distinguishable without color
- Three color theme presets: Standard, Color-blind safe, and High contrast
- New Appearance section in Preferences with live preview of current settings
- Automatic integration with macOS accessibility settings (Differentiate without color, Increase contrast)

## [1.2.1] - 2026-03-22

### Fixed
- Preferences window too short, requiring scrolling to see all sections

## [1.2.0] - 2026-03-22

### Improved
- Eliminated "CodeBar wants to control System Events" permission prompt by using NSWorkspace instead of AppleScript for iTerm2 detection

## [1.1.0] - 2026-03-22

### Improved
- Switched hooks from HTTP to command+async for graceful failure handling
- Polished preferences window UI with verbose log path info

### Fixed
- App icon not showing in Finder/Spotlight (added `CFBundleIconName` to Info.plist and complete macOS icon size set)

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

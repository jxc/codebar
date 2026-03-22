# CLAUDE.md

## Overview

CodeBar is a macOS menu bar app that monitors active Claude Code sessions. It shows a colored status circle and a dropdown with per-session details. Clicking a session row switches to that iTerm2 tab.

## Commands

```bash
make project    # Regenerate .xcodeproj from project.yml (xcodegen)
make build      # Build (generates project first)
make test       # Run unit tests
make run        # Build and open the app
make clean      # Remove build artifacts
make archive    # Release archive
```

## Architecture

- **Hook-driven**: Claude Code sends HTTP POST events to `localhost:8089/hook`
- **Startup backfill**: Reads `~/.claude/sessions/*.json` for sessions that started before CodeBar
- **Status inference**: PreToolUse → working, Notification → blocked, Stop → idle
- **iTerm2 integration**: AppleScript maps PID → TTY → iTerm2 session → tab switch

## Key Files

- `CodeBar/CodeBarApp.swift` — Entry point, `MenuBarExtra` scene
- `CodeBar/Models/SessionManager.swift` — Session state machine, aggregate status
- `CodeBar/Services/HookServer.swift` — HTTP server (Network.framework, no dependencies)
- `CodeBar/Services/HookInstaller.swift` — Auto-patches `~/.claude/settings.json`
- `CodeBar/Services/ITermController.swift` — AppleScript bridge to iTerm2
- `project.yml` — XcodeGen project spec (source of truth, not the .xcodeproj)

## Project Config

- **Source of truth**: `project.yml` — run `make project` to regenerate `.xcodeproj`
- **Do not commit** the `.xcodeproj` — it's in `.gitignore`
- **Non-sandboxed** — requires filesystem access to `~/.claude/` and AppleScript to iTerm2
- **macOS 13+** (Ventura) — uses `MenuBarExtra`
- **Hook port**: 8089 (defined in `Constants.swift`)

## Testing

Unit tests in `CodeBarTests/`. Run with `make test`.

Tests cover:
- Hook event JSON parsing (`HookEventTests`)
- Session status state machine (`SessionManagerTests`)

import Foundation

/// Manages hook configuration in ~/.claude/settings.json.
enum HookInstaller {
    private static var settingsURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
    }

    /// Legacy HTTP URL used by older hook configs — kept for migration/cleanup.
    static let legacyHookURL = "http://localhost:\(Constants.hookPort)/hook"

    private static let hookEvents = [
        "PreToolUse", "PostToolUse", "PostToolUseFailure",
        "Notification", "SessionStart", "SessionEnd", "Stop"
    ]

    // MARK: - Hook Status

    enum HookStatus {
        case installed
        case outdated(reasons: [String])
        case missing

        var isFullyInstalled: Bool {
            if case .installed = self { return true }
            return false
        }

        var label: String {
            switch self {
            case .installed: "Installed"
            case .outdated: "Needs Update"
            case .missing: "Not Installed"
            }
        }
    }

    /// Inspect hooks and return detailed status.
    static func inspect() -> HookStatus {
        guard let settings = readSettings(),
              let hooks = settings["hooks"] as? [String: Any]
        else { return .missing }

        var reasons: [String] = []

        for event in hookEvents {
            guard let entries = hooks[event] as? [[String: Any]],
                  let entry = entries.first(where: { isCodeBarEntry($0) }),
                  let innerHooks = entry["hooks"] as? [[String: Any]],
                  let hook = innerHooks.first(where: { isCodeBarHook($0) })
            else {
                reasons.append("\(event): missing")
                continue
            }

            // Check it's the new command+async format
            if hook["type"] as? String == "http" {
                reasons.append("\(event): using legacy http type, needs upgrade to command+async")
            } else if hook["async"] as? Bool != true {
                reasons.append("\(event): missing async flag")
            }
        }

        if reasons.count == hookEvents.count {
            return .missing
        } else if reasons.isEmpty {
            return .installed
        } else {
            return .outdated(reasons: reasons)
        }
    }

    /// Returns true if hooks are fully installed.
    static var isInstalled: Bool {
        inspect().isFullyInstalled
    }

    /// Install CodeBar hooks into ~/.claude/settings.json.
    /// Merges with existing settings — does not overwrite unrelated config.
    static func install() throws {
        var settings = readSettings() ?? [:]
        var hooks = settings["hooks"] as? [String: Any] ?? [:]

        let hookConfig: [String: Any] = [
            "type": "command",
            "command": Constants.hookCommand,
            "async": true
        ]

        let hookEntry: [String: Any] = [
            "matcher": "",
            "hooks": [hookConfig]
        ]

        for event in hookEvents {
            var existing = hooks[event] as? [[String: Any]] ?? []
            // Remove any existing CodeBar hook entries (both legacy HTTP and current command)
            existing.removeAll { isCodeBarEntry($0) }
            // Add our hook
            existing.append(hookEntry)
            hooks[event] = existing
        }

        settings["hooks"] = hooks
        try writeSettings(settings)
    }

    /// Remove CodeBar hooks from ~/.claude/settings.json.
    static func uninstall() throws {
        guard var settings = readSettings(),
              var hooks = settings["hooks"] as? [String: Any]
        else { return }

        for event in hookEvents {
            guard var existing = hooks[event] as? [[String: Any]] else { continue }
            existing.removeAll { isCodeBarEntry($0) }
            if existing.isEmpty {
                hooks.removeValue(forKey: event)
            } else {
                hooks[event] = existing
            }
        }

        if hooks.isEmpty {
            settings.removeValue(forKey: "hooks")
        } else {
            settings["hooks"] = hooks
        }

        try writeSettings(settings)
    }

    // MARK: - Private

    /// Check if a hook entry belongs to CodeBar (matches either legacy HTTP or current command format).
    private static func isCodeBarEntry(_ entry: [String: Any]) -> Bool {
        guard let innerHooks = entry["hooks"] as? [[String: Any]] else { return false }
        return innerHooks.contains { isCodeBarHook($0) }
    }

    /// Check if an individual hook config belongs to CodeBar.
    private static func isCodeBarHook(_ hook: [String: Any]) -> Bool {
        // Legacy HTTP format
        if (hook["url"] as? String) == legacyHookURL { return true }
        // Current command format
        if let command = hook["command"] as? String,
           command.contains("localhost:\(Constants.hookPort)/hook") { return true }
        return false
    }

    private static func readSettings() -> [String: Any]? {
        guard let data = try? Data(contentsOf: settingsURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return json
    }

    private static func writeSettings(_ settings: [String: Any]) throws {
        let data = try JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted, .sortedKeys]
        )
        let dir = settingsURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try data.write(to: settingsURL, options: .atomic)
    }
}

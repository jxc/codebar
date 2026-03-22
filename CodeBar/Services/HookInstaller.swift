import Foundation

/// Manages hook configuration in ~/.claude/settings.json.
enum HookInstaller {
    private static var settingsURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
    }

    static let hookURL = "http://localhost:\(Constants.hookPort)/hook"

    private static let hookEvents = [
        "PreToolUse", "PostToolUse", "PostToolUseFailure",
        "Notification", "SessionStart", "SessionEnd", "Stop"
    ]

    /// Returns true if hooks are already installed.
    static var isInstalled: Bool {
        guard let settings = readSettings(),
              let hooks = settings["hooks"] as? [String: Any]
        else { return false }

        // Check if at least SessionStart is configured with our URL
        guard let entries = hooks["SessionStart"] as? [[String: Any]],
              let first = entries.first,
              let innerHooks = first["hooks"] as? [[String: Any]],
              let url = innerHooks.first?["url"] as? String
        else { return false }

        return url == hookURL
    }

    /// Install CodeBar hooks into ~/.claude/settings.json.
    /// Merges with existing settings — does not overwrite unrelated config.
    static func install() throws {
        var settings = readSettings() ?? [:]
        var hooks = settings["hooks"] as? [String: Any] ?? [:]

        let hookConfig: [String: Any] = [
            "type": "http",
            "url": hookURL,
            "timeout": 5
        ]

        let hookEntry: [String: Any] = [
            "matcher": "",
            "hooks": [hookConfig]
        ]

        for event in hookEvents {
            var existing = hooks[event] as? [[String: Any]] ?? []
            // Remove any existing CodeBar hook entries
            existing.removeAll { entry in
                guard let innerHooks = entry["hooks"] as? [[String: Any]] else { return false }
                return innerHooks.contains { ($0["url"] as? String) == hookURL }
            }
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
            existing.removeAll { entry in
                guard let innerHooks = entry["hooks"] as? [[String: Any]] else { return false }
                return innerHooks.contains { ($0["url"] as? String) == hookURL }
            }
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
        // Ensure directory exists
        let dir = settingsURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try data.write(to: settingsURL, options: .atomic)
    }
}

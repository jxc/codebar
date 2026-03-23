import AppKit

/// Controls iTerm2 via AppleScript for tab switching.
enum ITermController {
    /// Switch iTerm2 focus to the tab containing the given TTY device.
    /// - Parameter tty: The TTY name, e.g. "ttys002"
    static func switchToTab(tty: String) {
        Log.info("Switching to iTerm2 tab for TTY \(tty)")
        let script = switchScript(for: tty)
        if !runAppleScript(script) {
            Log.info("Failed to switch iTerm2 tab for TTY \(tty)")
        }
    }

    /// Generate the AppleScript to focus the tab containing the given TTY.
    /// Extracted for testability.
    static func switchScript(for tty: String) -> String {
        let devicePath = "/dev/\(tty)"
        return """
        tell application "iTerm2"
            repeat with w in windows
                repeat with t in tabs of w
                    repeat with s in sessions of t
                        if tty of s is "\(devicePath)" then
                            tell w
                                select t
                                set index to 1
                            end tell
                            activate
                            return
                        end if
                    end repeat
                end repeat
            end repeat
        end tell
        """
    }

    /// Check if iTerm2 is running (uses NSWorkspace — no TCC prompt needed).
    static var isITermRunning: Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.googlecode.iterm2"
        }
    }

    // MARK: - Private

    @discardableResult
    private static func runAppleScript(_ source: String) -> Bool {
        guard let script = NSAppleScript(source: source) else { return false }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        if let error {
            print("[CodeBar] AppleScript error: \(error)")
            return false
        }
        return true
    }
}

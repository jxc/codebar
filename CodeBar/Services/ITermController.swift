import Foundation

/// Controls iTerm2 via AppleScript for tab switching.
enum ITermController {
    /// Switch iTerm2 focus to the tab containing the given TTY device.
    /// - Parameter tty: The TTY name, e.g. "ttys002"
    static func switchToTab(tty: String) {
        let devicePath = "/dev/\(tty)"
        let script = """
        tell application "iTerm2"
            repeat with w in windows
                repeat with t in tabs of w
                    repeat with s in sessions of t
                        if tty of s is "\(devicePath)" then
                            select t
                            tell w to select t
                            activate
                            return
                        end if
                    end repeat
                end repeat
            end repeat
        end tell
        """
        runAppleScript(script)
    }

    /// Check if iTerm2 is running.
    static var isITermRunning: Bool {
        let script = """
        tell application "System Events"
            return (name of processes) contains "iTerm2"
        end tell
        """
        let result = runAppleScriptWithResult(script)
        return result?.lowercased() == "true"
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

    private static func runAppleScriptWithResult(_ source: String) -> String? {
        guard let script = NSAppleScript(source: source) else { return nil }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if error != nil { return nil }
        return result.stringValue
    }
}

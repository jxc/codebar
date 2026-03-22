import Foundation

/// Process-level utilities (not to be confused with Foundation.ProcessInfo).
enum ProcessInfo {
    /// Check if a process with the given PID is alive.
    static func isProcessAlive(pid: Int) -> Bool {
        kill(Int32(pid), 0) == 0
    }

    /// Get the TTY device name for a PID (e.g. "ttys002").
    static func ttyForPID(_ pid: Int) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-o", "tty=", "-p", "\(pid)"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !output.isEmpty, output != "??"
        else { return nil }

        return output
    }
}

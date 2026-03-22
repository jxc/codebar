import Foundation

enum Log {
    private static let logURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".codebar.log")

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    static func clear() {
        try? "".write(to: logURL, atomically: true, encoding: .utf8)
    }

    static func hook(_ event: HookEvent) {
        let tool = event.toolName.map { " tool=\($0)" } ?? ""
        let desc = event.toolDescription.map { " desc=\"\($0)\"" } ?? ""
        let notif = event.notificationType.map { " notification=\($0)" } ?? ""
        write("HOOK  \(event.hookEventName) session=\(event.sessionId.prefix(8))\(tool)\(desc)\(notif) cwd=\(event.cwd)")
    }

    static func statusChange(sessionId: String, from: SessionStatus, to: SessionStatus) {
        guard from != to else { return }
        write("STATE \(sessionId.prefix(8)) \(from.label) → \(to.label)")
    }

    static func display(aggregate: SessionStatus, count: Int, sessions: [Session]) {
        let rows = sessions.map { s in
            "[\(s.id.prefix(8)) \(s.status.label) \"\(s.displayName)\" \"\(s.lastActivity)\"]"
        }.joined(separator: " ")
        write("DISPLAY icon=\(aggregate.label) count=\(count) sessions=\(rows)")
    }

    static func discovery(found: Int, sessions: [(id: String, pid: Int)]) {
        let list = sessions.map { "\($0.id.prefix(8)):pid\($0.pid)" }.joined(separator: ", ")
        write("DISCO found=\(found) [\(list)]")
    }

    static func dedup(action: String, sessionId: String, pid: Int) {
        write("DEDUP \(action) session=\(sessionId.prefix(8)) pid=\(pid)")
    }

    static func liveness(removed: [String], remaining: Int) {
        if !removed.isEmpty {
            write("ALIVE removed=\(removed.map { String($0.prefix(8)) }) remaining=\(remaining)")
        }
    }

    static func info(_ message: String) {
        write("INFO  \(message)")
    }

    // MARK: - Private

    private static func write(_ message: String) {
        let timestamp = dateFormatter.string(from: Date())
        let line = "\(timestamp) \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: logURL) {
            handle.seekToEndOfFile()
            handle.write(data)
            handle.closeFile()
        } else {
            try? data.write(to: logURL)
        }
    }
}

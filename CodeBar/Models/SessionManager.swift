import Foundation
import Combine

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var sessions: [Session] = []
    @Published private(set) var aggregateStatus: SessionStatus = .none

    init(skipDiscovery: Bool = false) {
        Log.clear()
        Log.info("SessionManager init (hooks-only mode)")
    }

    // MARK: - Hook Event Processing

    func handleHookEvent(_ event: HookEvent) {
        Log.hook(event)

        switch event.hookEventName {
        case "SessionStart":
            ensureSession(event: event)

        case "SessionEnd":
            Log.info("SessionEnd \(event.sessionId.prefix(8))")
            sessions.removeAll { $0.id == event.sessionId }

        case "PreToolUse":
            let session = ensureSession(event: event)
            let oldStatus = session.status
            if let idx = index(for: event.sessionId) {
                sessions[idx].status = .working
                let toolName = event.toolName ?? "Tool"
                let desc = event.toolDescription ?? ""
                sessions[idx].lastActivity = desc.isEmpty ? toolName : "\(toolName): \(desc)"
                sessions[idx].lastUpdated = Date()
            }
            Log.statusChange(sessionId: event.sessionId, from: oldStatus, to: .working)

        case "PostToolUse", "PostToolUseFailure":
            ensureSession(event: event)
            if let idx = index(for: event.sessionId) {
                sessions[idx].lastUpdated = Date()
            }

        case "Notification":
            let session = ensureSession(event: event)
            let oldStatus = session.status
            if let idx = index(for: event.sessionId) {
                sessions[idx].status = .blocked
                sessions[idx].lastActivity = "Waiting for permission…"
                sessions[idx].lastUpdated = Date()
            }
            Log.statusChange(sessionId: event.sessionId, from: oldStatus, to: .blocked)

        case "Stop":
            let session = ensureSession(event: event)
            let oldStatus = session.status
            if let idx = index(for: event.sessionId) {
                sessions[idx].status = .idle
                sessions[idx].lastActivity = "Idle"
                sessions[idx].lastUpdated = Date()
            }
            Log.statusChange(sessionId: event.sessionId, from: oldStatus, to: .idle)

        default:
            Log.info("Unknown hook event: \(event.hookEventName)")
        }

        recomputeAggregate()
        Log.display(aggregate: aggregateStatus, count: sessions.count, sessions: sessions)
    }

    // MARK: - Helpers

    @discardableResult
    private func ensureSession(event: HookEvent) -> Session {
        if let idx = index(for: event.sessionId) {
            // Update CWD if it changed
            if !event.cwd.isEmpty {
                sessions[idx].cwd = event.cwd
            }
            return sessions[idx]
        }
        // New session — look up PID and TTY from session files
        let pid = Self.findPID(for: event.sessionId)
        var session = Session(
            id: event.sessionId,
            pid: pid,
            cwd: event.cwd
        )
        session.tty = pid > 0 ? ProcessInfo.ttyForPID(pid) : nil
        sessions.append(session)
        Log.info("New session \(event.sessionId.prefix(8)) pid=\(pid) cwd=\(event.cwd)")
        return session
    }

    private func index(for sessionId: String) -> Int? {
        sessions.firstIndex(where: { $0.id == sessionId })
    }

    /// Try to find the PID for a hook session by checking which session file
    /// has a JSONL transcript matching this session ID.
    private static func findPID(for hookSessionId: String) -> Int {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let projectsDir = home.appendingPathComponent(".claude/projects")

        guard let projectDirs = try? FileManager.default.contentsOfDirectory(
            at: projectsDir, includingPropertiesForKeys: nil
        ) else { return 0 }

        // Find which project dir contains a JSONL for this session
        for dir in projectDirs {
            let jsonl = dir.appendingPathComponent("\(hookSessionId).jsonl")
            if FileManager.default.fileExists(atPath: jsonl.path) {
                // Decode directory name back to CWD path
                let dirName = dir.lastPathComponent
                let cwd = "/" + dirName.split(separator: "-").joined(separator: "/")

                // Find a session file with matching CWD
                let allSessions = SessionDiscovery.discoverSessions()
                if let match = allSessions.first(where: { $0.cwd == cwd }) {
                    return match.pid
                }
            }
        }
        return 0
    }

    private func recomputeAggregate() {
        if sessions.isEmpty {
            aggregateStatus = .none
        } else {
            aggregateStatus = sessions.map(\.status).max() ?? .none
        }
    }
}

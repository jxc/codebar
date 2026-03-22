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
                sessions[idx].lastActivity = event.message ?? "Waiting for permission…"
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
            // Re-read metadata to catch renames
            if let path = event.transcriptPath {
                let meta = TranscriptReader.readMeta(from: path)
                if let title = meta.customTitle, title != sessions[idx].customTitle {
                    sessions[idx].customTitle = title
                    Log.info("Updated title for \(event.sessionId.prefix(8)): \(title)")
                }
                if let slug = meta.slug, sessions[idx].slug == nil {
                    sessions[idx].slug = slug
                }
            }
            // Retry TTY lookup if still nil
            if sessions[idx].tty == nil, sessions[idx].pid > 0 {
                sessions[idx].tty = ProcessInfo.ttyForPID(sessions[idx].pid)
                if sessions[idx].tty != nil {
                    Log.info("Late TTY resolution for \(event.sessionId.prefix(8)): \(sessions[idx].tty!)")
                }
            }
            return sessions[idx]
        }
        // New session — look up PID, TTY, and metadata
        let pid = Self.findPID(for: event.sessionId)
        var session = Session(
            id: event.sessionId,
            pid: pid,
            cwd: event.cwd
        )
        session.tty = pid > 0 ? ProcessInfo.ttyForPID(pid) : nil

        // Read session name from transcript
        if let path = event.transcriptPath {
            let meta = TranscriptReader.readMeta(from: path)
            session.customTitle = meta.customTitle
            session.slug = meta.slug
            Log.info("New session \(event.sessionId.prefix(8)) pid=\(pid) title=\(meta.customTitle ?? "nil") slug=\(meta.slug ?? "nil") cwd=\(event.cwd)")
        } else {
            Log.info("New session \(event.sessionId.prefix(8)) pid=\(pid) cwd=\(event.cwd) (no transcript path)")
        }

        sessions.append(session)
        return session
    }

    private func index(for sessionId: String) -> Int? {
        sessions.firstIndex(where: { $0.id == sessionId })
    }

    /// Find the PID for a hook session by matching against ~/.claude/sessions/*.json.
    private static func findPID(for hookSessionId: String) -> Int {
        let allSessions = SessionDiscovery.discoverSessions()
        return allSessions.first(where: { $0.sessionId == hookSessionId })?.pid ?? 0
    }

    private func recomputeAggregate() {
        if sessions.isEmpty {
            aggregateStatus = .none
        } else {
            aggregateStatus = sessions.map(\.status).max() ?? .none
        }
    }
}

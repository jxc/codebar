import Foundation
import Combine

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var sessions: [Session] = []
    @Published private(set) var aggregateStatus: SessionStatus = .none

    private var livenessTimer: Timer?

    init(skipDiscovery: Bool = false) {
        if !skipDiscovery {
            discoverExistingSessions()
            startLivenessChecks()
        }
    }

    deinit {
        livenessTimer?.invalidate()
    }

    // MARK: - Hook Event Processing

    func handleHookEvent(_ event: HookEvent) {
        switch event.hookEventName {
        case "SessionStart":
            addSessionIfNeeded(event: event)

        case "SessionEnd":
            removeSession(sessionId: event.sessionId)

        case "PreToolUse":
            updateSession(sessionId: event.sessionId) { session in
                session.status = .working
                let toolName = event.toolName ?? "Tool"
                let description = event.toolDescription ?? ""
                session.lastActivity = description.isEmpty ? toolName : "\(toolName): \(description)"
                session.lastUpdated = Date()
            }

        case "PostToolUse", "PostToolUseFailure":
            updateSession(sessionId: event.sessionId) { session in
                // Stay working — will transition to idle on Stop
                session.lastUpdated = Date()
            }

        case "Notification":
            updateSession(sessionId: event.sessionId) { session in
                session.status = .blocked
                session.lastActivity = "Waiting for permission…"
                session.lastUpdated = Date()
            }

        case "Stop":
            updateSession(sessionId: event.sessionId) { session in
                session.status = .idle
                session.lastActivity = "Idle"
                session.lastUpdated = Date()
            }

        default:
            break
        }

        // Update CWD/branch if provided
        if let idx = sessions.firstIndex(where: { $0.id == event.sessionId }) {
            if let branch = event.gitBranch {
                sessions[idx].gitBranch = branch
            }
        }

        recomputeAggregate()
    }

    // MARK: - Session Discovery (startup backfill)

    func discoverExistingSessions() {
        let discovered = SessionDiscovery.discoverSessions()
        for info in discovered {
            if !sessions.contains(where: { $0.id == info.sessionId }) {
                var session = Session(
                    id: info.sessionId,
                    pid: info.pid,
                    cwd: info.cwd
                )
                session.tty = ProcessInfo.ttyForPID(info.pid)
                sessions.append(session)
            }
        }
        recomputeAggregate()
    }

    // MARK: - Liveness Checks

    private func startLivenessChecks() {
        livenessTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkLiveness()
            }
        }
    }

    private func checkLiveness() {
        sessions.removeAll { session in
            !ProcessInfo.isProcessAlive(pid: session.pid)
        }
        recomputeAggregate()
    }

    // MARK: - Helpers

    private func addSessionIfNeeded(event: HookEvent) {
        guard !sessions.contains(where: { $0.id == event.sessionId }) else { return }
        // Try to find PID from session files
        let pid = SessionDiscovery.pidForSession(event.sessionId) ?? 0
        var session = Session(
            id: event.sessionId,
            pid: pid,
            cwd: event.cwd
        )
        session.tty = pid > 0 ? ProcessInfo.ttyForPID(pid) : nil
        sessions.append(session)
    }

    private func removeSession(sessionId: String) {
        sessions.removeAll { $0.id == sessionId }
    }

    private func updateSession(sessionId: String, update: (inout Session) -> Void) {
        if let idx = sessions.firstIndex(where: { $0.id == sessionId }) {
            update(&sessions[idx])
        } else {
            // Session not yet tracked — auto-discover it
            let pid = SessionDiscovery.pidForSession(sessionId) ?? 0
            var session = Session(id: sessionId, pid: pid, cwd: "")
            session.tty = pid > 0 ? ProcessInfo.ttyForPID(pid) : nil
            update(&session)
            sessions.append(session)
        }
    }

    private func recomputeAggregate() {
        if sessions.isEmpty {
            aggregateStatus = .none
        } else {
            aggregateStatus = sessions.map(\.status).max() ?? .none
        }
    }
}

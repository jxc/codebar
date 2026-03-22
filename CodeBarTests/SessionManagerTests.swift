import XCTest
@testable import CodeBar

@MainActor
final class SessionManagerTests: XCTestCase {
    private func makeManager() -> SessionManager {
        SessionManager(skipDiscovery: true)
    }

    func testPreToolUseSetsWorking() {
        let manager = makeManager()
        let event = makeEvent(name: "PreToolUse", toolName: "Bash", toolDescription: "Run tests")
        manager.handleHookEvent(event)

        XCTAssertEqual(manager.sessions.count, 1)
        XCTAssertEqual(manager.sessions.first?.status, .working)
        XCTAssertEqual(manager.aggregateStatus, .working)
    }

    func testStopSetsIdle() {
        let manager = makeManager()
        manager.handleHookEvent(makeEvent(name: "PreToolUse", toolName: "Bash"))
        manager.handleHookEvent(makeEvent(name: "Stop"))

        XCTAssertEqual(manager.sessions.first?.status, .idle)
        XCTAssertEqual(manager.aggregateStatus, .idle)
    }

    func testNotificationSetsBlocked() {
        let manager = makeManager()
        manager.handleHookEvent(makeEvent(name: "Notification"))

        XCTAssertEqual(manager.sessions.first?.status, .blocked)
        XCTAssertEqual(manager.aggregateStatus, .blocked)
    }

    func testAggregateReflectsHighestPriority() {
        let manager = makeManager()

        // Session A: idle
        manager.handleHookEvent(makeEvent(sessionId: "a", name: "Stop"))
        // Session B: blocked
        manager.handleHookEvent(makeEvent(sessionId: "b", name: "Notification"))

        XCTAssertEqual(manager.sessions.count, 2)
        XCTAssertEqual(manager.aggregateStatus, .blocked)
    }

    func testSessionEndRemovesSession() {
        let manager = makeManager()
        manager.handleHookEvent(makeEvent(name: "PreToolUse", toolName: "Bash"))
        XCTAssertEqual(manager.sessions.count, 1)

        manager.handleHookEvent(makeEvent(name: "SessionEnd"))
        XCTAssertEqual(manager.sessions.count, 0)
        XCTAssertEqual(manager.aggregateStatus, .none)
    }

    func testLastActivityUpdatedFromTool() {
        let manager = makeManager()
        manager.handleHookEvent(makeEvent(name: "PreToolUse", toolName: "Edit", toolDescription: "internal/scheduler/loop.go"))

        XCTAssertEqual(manager.sessions.first?.lastActivity, "Edit: internal/scheduler/loop.go")
    }

    // MARK: - Helpers

    private func makeEvent(
        sessionId: String = "test-session",
        name: String,
        toolName: String? = nil,
        toolDescription: String? = nil
    ) -> HookEvent {
        let toolInput: [String: Any]? = toolDescription.map { ["description": $0] }
        var dict: [String: Any] = [
            "session_id": sessionId,
            "cwd": "/tmp/test",
            "hook_event_name": name
        ]
        if let toolName { dict["tool_name"] = toolName }
        if let toolInput { dict["tool_input"] = toolInput }

        let data = try! JSONSerialization.data(withJSONObject: dict)
        return try! JSONDecoder().decode(HookEvent.self, from: data)
    }
}

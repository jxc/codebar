import XCTest
@testable import CodeBar

final class HookEventTests: XCTestCase {
    func testDecodePreToolUse() throws {
        let json = """
        {
            "session_id": "abc-123",
            "cwd": "/Users/dev/project",
            "hook_event_name": "PreToolUse",
            "tool_name": "Bash",
            "tool_input": {
                "command": "npm test",
                "description": "Run test suite"
            }
        }
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(HookEvent.self, from: json)
        XCTAssertEqual(event.sessionId, "abc-123")
        XCTAssertEqual(event.hookEventName, "PreToolUse")
        XCTAssertEqual(event.toolName, "Bash")
        XCTAssertEqual(event.toolDescription, "Run test suite")
    }

    func testDecodeSessionStart() throws {
        let json = """
        {
            "session_id": "def-456",
            "cwd": "/Users/dev/other",
            "hook_event_name": "SessionStart",
            "source": "startup"
        }
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(HookEvent.self, from: json)
        XCTAssertEqual(event.hookEventName, "SessionStart")
        XCTAssertEqual(event.source, "startup")
        XCTAssertNil(event.toolName)
    }

    func testDecodeNotification() throws {
        let json = """
        {
            "session_id": "ghi-789",
            "cwd": "/Users/dev/project",
            "hook_event_name": "Notification",
            "notification_type": "permission_prompt"
        }
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(HookEvent.self, from: json)
        XCTAssertEqual(event.hookEventName, "Notification")
        XCTAssertEqual(event.notificationType, "permission_prompt")
    }

    func testToolDescriptionFallsBackToCommand() throws {
        let json = """
        {
            "session_id": "abc-123",
            "cwd": "/tmp",
            "hook_event_name": "PreToolUse",
            "tool_name": "Bash",
            "tool_input": {
                "command": "make build"
            }
        }
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(HookEvent.self, from: json)
        XCTAssertEqual(event.toolDescription, "make build")
    }
}

import XCTest
@testable import CodeBar

final class MenuBarIconTests: XCTestCase {

    // MARK: - Single mode

    func testSingleModeNoSessions() {
        let image = MenuBarIcon.image(sessions: [], displayMode: .single)
        XCTAssertTrue(image.isTemplate, "No-session icon should be a template image")
    }

    func testSingleModeWithSessions() {
        let sessions = [makeSession(status: .working), makeSession(status: .idle)]
        let image = MenuBarIcon.image(sessions: sessions, displayMode: .single)
        XCTAssertFalse(image.isTemplate)
        // Single mode produces a narrow image (one circle + count)
        XCTAssertLessThan(image.size.width, 40)
    }

    // MARK: - Active-only mode

    func testActiveOnlyNoSessions() {
        let image = MenuBarIcon.image(sessions: [], displayMode: .activeOnly)
        XCTAssertTrue(image.isTemplate, "No-session icon should be a template image")
    }

    func testActiveOnlyShowsOnlyActiveStatuses() {
        // 2 working, 1 blocked — should produce 2 groups (no idle circle)
        let sessions = [
            makeSession(status: .working),
            makeSession(status: .working),
            makeSession(status: .blocked)
        ]
        let image = MenuBarIcon.image(sessions: sessions, displayMode: .activeOnly)
        XCTAssertFalse(image.isTemplate)
        // Should be wider than single mode (2 groups)
        XCTAssertGreaterThan(image.size.width, 18)
    }

    // MARK: - StatusDisplayMode persistence

    func testDisplayModeRawValueRoundTrip() {
        for mode in StatusDisplayMode.allCases {
            let raw = mode.rawValue
            XCTAssertEqual(StatusDisplayMode(rawValue: raw), mode)
        }
    }

    // MARK: - Legacy API

    func testLegacyAPIStillWorks() {
        let image = MenuBarIcon.image(for: .working, sessionCount: 3)
        XCTAssertFalse(image.isTemplate)
    }

    // MARK: - Helpers

    private func makeSession(status: SessionStatus) -> Session {
        var session = Session(id: UUID().uuidString, pid: 0, cwd: "/tmp")
        session.status = status
        return session
    }
}

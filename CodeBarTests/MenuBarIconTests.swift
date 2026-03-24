import XCTest
@testable import CodeBar

final class MenuBarIconTests: XCTestCase {

    // MARK: - Single mode

    func testSingleModeNoSessions() {
        let image = MenuBarIcon.image(sessions: [], displayMode: .single, shapeMode: .circles, colorTheme: .standard)
        XCTAssertTrue(image.isTemplate, "No-session icon should be a template image")
    }

    func testSingleModeWithSessions() {
        let sessions = [makeSession(status: .working), makeSession(status: .idle)]
        let image = MenuBarIcon.image(sessions: sessions, displayMode: .single, shapeMode: .circles, colorTheme: .standard)
        XCTAssertFalse(image.isTemplate)
        // Single mode produces a narrow image (one circle + count)
        XCTAssertLessThan(image.size.width, 40)
    }

    // MARK: - Active-only mode

    func testActiveOnlyNoSessions() {
        let image = MenuBarIcon.image(sessions: [], displayMode: .activeOnly, shapeMode: .circles, colorTheme: .standard)
        XCTAssertTrue(image.isTemplate, "No-session icon should be a template image")
    }

    func testActiveOnlyShowsOnlyActiveStatuses() {
        // 2 working, 1 blocked — should produce 2 groups (no idle circle)
        let sessions = [
            makeSession(status: .working),
            makeSession(status: .working),
            makeSession(status: .blocked)
        ]
        let image = MenuBarIcon.image(sessions: sessions, displayMode: .activeOnly, shapeMode: .circles, colorTheme: .standard)
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

    // MARK: - Shape mode × Status combinations

    func testAllShapeModeStatusCombinations() {
        let statuses: [SessionStatus] = [.none, .idle, .working, .blocked]

        for shapeMode in StatusShapeMode.allCases {
            for status in statuses {
                let image = MenuBarIcon.image(
                    for: status,
                    sessionCount: status == .none ? 0 : 1,
                    shapeMode: shapeMode,
                    colorTheme: .standard
                )
                if status == .none {
                    XCTAssertTrue(image.isTemplate, "\(shapeMode).\(status) should be template")
                } else {
                    XCTAssertFalse(image.isTemplate, "\(shapeMode).\(status) should not be template")
                }
            }
        }
    }

    // MARK: - Color theme × Status combinations

    func testAllColorThemeStatusCombinations() {
        let statuses: [SessionStatus] = [.none, .idle, .working, .blocked]

        for theme in ColorTheme.allCases {
            for status in statuses {
                let image = MenuBarIcon.image(
                    for: status,
                    sessionCount: status == .none ? 0 : 1,
                    shapeMode: .circles,
                    colorTheme: theme
                )
                XCTAssertGreaterThan(image.size.width, 0, "\(theme).\(status) should produce a valid image")
            }
        }
    }

    // MARK: - Shape + theme with sessions

    func testShapeModeWithMultipleSessions() {
        let sessions = [makeSession(status: .working), makeSession(status: .blocked)]
        for shapeMode in StatusShapeMode.allCases {
            let image = MenuBarIcon.image(
                sessions: sessions,
                displayMode: .activeOnly,
                shapeMode: shapeMode,
                colorTheme: .colorBlindSafe
            )
            XCTAssertFalse(image.isTemplate)
            XCTAssertGreaterThan(image.size.width, 18)
        }
    }

    // MARK: - Enum persistence

    func testShapeModeRawValueRoundTrip() {
        for mode in StatusShapeMode.allCases {
            XCTAssertEqual(StatusShapeMode(rawValue: mode.rawValue), mode)
        }
    }

    func testColorThemeRawValueRoundTrip() {
        for theme in ColorTheme.allCases {
            XCTAssertEqual(ColorTheme(rawValue: theme.rawValue), theme)
        }
    }

    // MARK: - StatusAppearance SF Symbol names

    func testSFSymbolNamesCirclesMode() {
        XCTAssertEqual(StatusAppearance.sfSymbolName(for: .none, shapeMode: .circles), "circle")
        XCTAssertEqual(StatusAppearance.sfSymbolName(for: .idle, shapeMode: .circles), "circle.fill")
        XCTAssertEqual(StatusAppearance.sfSymbolName(for: .working, shapeMode: .circles), "circle.fill")
        XCTAssertEqual(StatusAppearance.sfSymbolName(for: .blocked, shapeMode: .circles), "circle.fill")
    }

    func testSFSymbolNamesShapesMode() {
        XCTAssertEqual(StatusAppearance.sfSymbolName(for: .none, shapeMode: .shapes), "circle")
        XCTAssertEqual(StatusAppearance.sfSymbolName(for: .idle, shapeMode: .shapes), "circle.fill")
        XCTAssertEqual(StatusAppearance.sfSymbolName(for: .working, shapeMode: .shapes), "diamond.fill")
        XCTAssertEqual(StatusAppearance.sfSymbolName(for: .blocked, shapeMode: .shapes), "triangle.fill")
    }

    // MARK: - Helpers

    private func makeSession(status: SessionStatus) -> Session {
        var session = Session(id: UUID().uuidString, pid: 0, cwd: "/tmp")
        session.status = status
        return session
    }
}

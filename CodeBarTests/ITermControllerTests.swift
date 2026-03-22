import XCTest
@testable import CodeBar

final class ITermControllerTests: XCTestCase {
    func testSwitchScriptContainsDevicePath() {
        let script = ITermController.switchScript(for: "ttys003")
        XCTAssertTrue(script.contains("/dev/ttys003"))
    }

    func testSwitchScriptContainsWindowFocus() {
        let script = ITermController.switchScript(for: "ttys001")
        XCTAssertTrue(script.contains("set index to 1"), "Script should raise the target window")
    }

    func testSwitchScriptStructure() {
        let script = ITermController.switchScript(for: "ttys005")
        XCTAssertTrue(script.contains("tell application \"iTerm2\""))
        XCTAssertTrue(script.contains("tell w"))
        XCTAssertTrue(script.contains("activate"))
    }
}

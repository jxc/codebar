import XCTest
@testable import CodeBar

final class ProcessInfoTests: XCTestCase {
    func testTTYForCurrentProcess() {
        let pid = Int(Foundation.ProcessInfo.processInfo.processIdentifier)
        // Test runner may not have a TTY — just verify it doesn't crash
        let tty = CodeBar.ProcessInfo.ttyForPID(pid)
        if let tty {
            XCTAssertTrue(tty.hasPrefix("ttys"), "Expected TTY format ttysNNN, got \(tty)")
        }
    }

    func testTTYForInvalidPID() {
        XCTAssertNil(CodeBar.ProcessInfo.ttyForPID(99_999_999))
    }

    func testTTYForZeroPID() {
        XCTAssertNil(CodeBar.ProcessInfo.ttyForPID(0))
    }

    func testIsProcessAliveForCurrentProcess() {
        let pid = Int(Foundation.ProcessInfo.processInfo.processIdentifier)
        XCTAssertTrue(CodeBar.ProcessInfo.isProcessAlive(pid: pid))
    }

    func testIsProcessAliveForInvalidPID() {
        XCTAssertFalse(CodeBar.ProcessInfo.isProcessAlive(pid: 99_999_999))
    }

    func testIsProcessAliveForZeroPID() {
        XCTAssertFalse(CodeBar.ProcessInfo.isProcessAlive(pid: 0))
    }
}

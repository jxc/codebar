import Foundation

enum Constants {
    static let hookPort: UInt16 = 8089
    static let livenessInterval: TimeInterval = 10

    /// Inline shell command for hook relay. Always exits 0 so Claude Code
    /// never shows errors when CodeBar isn't running.
    static let hookCommand: String =
        "curl -s -o /dev/null --max-time 3 -X POST -H 'Content-Type: application/json' -d @- http://localhost:\(hookPort)/hook 2>/dev/null; exit 0"
}

import Foundation

enum SessionStatus: Int, Comparable {
    case none = 0
    case idle = 1
    case working = 2
    case blocked = 3

    static func < (lhs: SessionStatus, rhs: SessionStatus) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .none: "No sessions"
        case .idle: "Idle"
        case .working: "Working"
        case .blocked: "Blocked"
        }
    }
}

struct Session: Identifiable {
    let id: String          // sessionId from Claude
    let pid: Int
    let cwd: String
    var slug: String?       // human-readable name from JSONL
    var gitBranch: String?
    var status: SessionStatus = .idle
    var lastActivity: String = "Idle"
    var lastUpdated: Date = Date()
    var tty: String?        // e.g. "ttys002"

    var displayName: String {
        if let slug { return slug }
        // Fall back to last path component of cwd
        return (cwd as NSString).lastPathComponent
    }
}

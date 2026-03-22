import Foundation

/// Represents an incoming hook event from Claude Code.
/// Claude Code POSTs JSON to our HTTP server with these fields.
struct HookEvent: Decodable {
    let sessionId: String
    let cwd: String
    let hookEventName: String

    // PreToolUse / PostToolUse
    let toolName: String?
    let toolInput: ToolInput?

    // Notification
    let notificationType: String?

    // SessionStart
    let source: String?

    // Context
    let gitBranch: String?
    let transcriptPath: String?
    let message: String?  // Notification message (e.g. "Claude needs your permission to use Bash")

    var toolDescription: String? {
        toolInput?.description ?? toolInput?.command
    }

    struct ToolInput: Decodable {
        let description: String?
        let command: String?
        let filePath: String?

        enum CodingKeys: String, CodingKey {
            case description
            case command
            case filePath = "file_path"
        }
    }

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case cwd
        case hookEventName = "hook_event_name"
        case toolName = "tool_name"
        case toolInput = "tool_input"
        case notificationType = "notification_type"
        case source
        case gitBranch
        case transcriptPath = "transcript_path"
        case message
    }
}

import Foundation

/// Reads ~/.claude/sessions/*.json to discover active Claude Code sessions.
enum SessionDiscovery {
    struct SessionFile: Decodable {
        let pid: Int
        let sessionId: String
        let cwd: String
        let startedAt: Int?
    }

    /// Discover all currently registered sessions from the filesystem.
    static func discoverSessions() -> [SessionFile] {
        let sessionsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/sessions")

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: sessionsDir, includingPropertiesForKeys: nil
        ) else { return [] }

        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> SessionFile? in
                guard let data = try? Data(contentsOf: url),
                      let session = try? JSONDecoder().decode(SessionFile.self, from: data)
                else { return nil }
                // Verify process is actually alive
                guard ProcessInfo.isProcessAlive(pid: session.pid) else { return nil }
                return session
            }
    }

    /// Look up PID for a given session ID from session files.
    static func pidForSession(_ sessionId: String) -> Int? {
        discoverSessions().first(where: { $0.sessionId == sessionId })?.pid
    }
}

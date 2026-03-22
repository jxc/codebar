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
                guard ProcessInfo.isProcessAlive(pid: session.pid) else { return nil }
                return session
            }
    }

    /// Find all active PIDs (for dedup matching).
    static func allActivePIDs() -> [(pid: Int, cwd: String, fileSessionId: String)] {
        discoverSessions().map { (pid: $0.pid, cwd: $0.cwd, fileSessionId: $0.sessionId) }
    }
}

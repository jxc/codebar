import Foundation

/// Reads session metadata (slug, custom title) from JSONL transcript files.
enum TranscriptReader {
    struct SessionMeta {
        var slug: String?
        var customTitle: String?
    }

    /// Read session metadata from a JSONL transcript file.
    /// Scans for `custom-title` and `progress` entries to extract
    /// the session's display name.
    static func readMeta(from transcriptPath: String) -> SessionMeta {
        guard let data = FileManager.default.contents(atPath: transcriptPath) else {
            return SessionMeta()
        }

        var meta = SessionMeta()

        // Read from the beginning — custom-title entries can appear anywhere
        // but are usually near queue-operation/user messages
        guard let content = String(data: data, encoding: .utf8) else {
            return meta
        }

        // Scan all lines for custom-title (rare, fast check)
        // and grab slug from the first progress entry
        for line in content.components(separatedBy: "\n") {
            guard !line.isEmpty else { continue }

            if line.contains("\"custom-title\"") {
                if let entry = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
                   let title = entry["customTitle"] as? String {
                    meta.customTitle = title
                }
            }

            if meta.slug == nil, line.contains("\"slug\"") {
                if let entry = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
                   let slug = entry["slug"] as? String {
                    meta.slug = slug
                }
            }

            // Once we have both, stop scanning
            if meta.customTitle != nil && meta.slug != nil {
                break
            }
        }

        return meta
    }
}

import Foundation

/// Reads session metadata (slug, custom title) from JSONL transcript files.
enum TranscriptReader {
    struct SessionMeta {
        var slug: String?
        var customTitle: String?
    }

    /// Read session metadata from a JSONL transcript file.
    /// The last `custom-title` entry wins (most recent /rename).
    /// The first `slug` in a progress entry is used.
    static func readMeta(from transcriptPath: String) -> SessionMeta {
        guard let data = FileManager.default.contents(atPath: transcriptPath),
              let content = String(data: data, encoding: .utf8)
        else { return SessionMeta() }

        var meta = SessionMeta()

        for line in content.components(separatedBy: "\n") {
            guard !line.isEmpty else { continue }

            // Always take the LAST custom-title (most recent rename)
            if line.contains("\"custom-title\"") {
                if let entry = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
                   let title = entry["customTitle"] as? String {
                    meta.customTitle = title
                }
            }

            // Take the first slug
            if meta.slug == nil, line.contains("\"slug\"") {
                if let entry = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
                   let slug = entry["slug"] as? String {
                    meta.slug = slug
                }
            }
        }

        return meta
    }
}

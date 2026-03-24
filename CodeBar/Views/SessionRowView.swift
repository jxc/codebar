import SwiftUI

struct SessionRowView: View {
    let session: Session
    @ObservedObject private var preferences = Preferences.shared
    @State private var isHovered = false

    var body: some View {
        Button(action: handleClick) {
            HStack(spacing: 8) {
                Image(systemName: StatusAppearance.sfSymbolName(
                    for: session.status,
                    shapeMode: preferences.effectiveShapeMode
                ))
                .foregroundStyle(StatusAppearance.color(
                    for: session.status,
                    theme: preferences.effectiveColorTheme
                ))
                .font(.system(size: 10))
                .frame(width: 16, height: 16)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(session.displayName)
                            .font(.system(.body, weight: .medium))

                        if let branch = session.gitBranch {
                            Text("(\(branch))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(session.lastActivity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func handleClick() {
        guard let tty = session.tty else {
            Log.info("Click ignored: no TTY for session \(session.id.prefix(8)) pid=\(session.pid)")
            return
        }
        guard ITermController.isITermRunning else {
            Log.info("Click ignored: iTerm2 is not running")
            return
        }
        ITermController.switchToTab(tty: tty)
    }
}

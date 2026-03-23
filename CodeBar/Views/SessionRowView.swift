import SwiftUI

struct SessionRowView: View {
    let session: Session
    @State private var isHovered = false

    var body: some View {
        Button(action: handleClick) {
            HStack(spacing: 8) {
                Group {
                    if session.status == .none {
                        Circle()
                            .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1.5)
                            .frame(width: 16, height: 16)
                    } else {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 16, height: 16)
                    }
                }

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

    private var statusColor: Color {
        switch session.status {
        case .none: .gray.opacity(0.5)
        case .idle: .gray
        case .working: Color(red: 0.0, green: 0.75, blue: 1.0)
        case .blocked: .orange
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

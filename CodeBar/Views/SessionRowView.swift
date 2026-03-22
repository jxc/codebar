import SwiftUI

struct SessionRowView: View {
    let session: Session

    var body: some View {
        Button(action: handleClick) {
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var statusColor: Color {
        switch session.status {
        case .none: .gray.opacity(0.5)
        case .idle: .gray
        case .working: .blue
        case .blocked: .orange
        }
    }

    private func handleClick() {
        guard let tty = session.tty else { return }
        ITermController.switchToTab(tty: tty)
    }
}

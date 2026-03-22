import SwiftUI

struct SessionListView: View {
    @ObservedObject var sessionManager: SessionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if sessionManager.sessions.isEmpty {
                Text("No active sessions")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                ForEach(sessionManager.sessions) { session in
                    SessionRowView(session: session)
                }
            }

            Divider()
                .padding(.vertical, 4)

            HStack {
                if HookInstaller.isInstalled {
                    Button("Remove Hooks") {
                        try? HookInstaller.uninstall()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.caption)
                } else {
                    Button("Install Hooks") {
                        try? HookInstaller.install()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                    .font(.caption)
                }

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)
            }
        }
        .padding(12)
    }
}

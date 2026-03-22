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
                Button("Preferences...") {
                    PreferencesWindowController.shared.showWindow()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)

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

import SwiftUI

struct SessionListView: View {
    @ObservedObject var sessionManager: SessionManager

    var body: some View {
        if sessionManager.sessions.isEmpty {
            Text("No active sessions")
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        } else {
            ForEach(sessionManager.sessions) { session in
                SessionRowView(session: session)
            }
        }

        Divider()

        if HookInstaller.isInstalled {
            Button("Remove Hooks") {
                try? HookInstaller.uninstall()
            }
        } else {
            Button("Install Hooks") {
                try? HookInstaller.install()
            }
        }

        Divider()

        Button("Quit CodeBar") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}

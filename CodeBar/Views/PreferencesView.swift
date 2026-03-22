import SwiftUI

struct PreferencesView: View {
    var body: some View {
        GeneralTab()
            .frame(width: 450, height: 380)
    }
}

// MARK: - General Tab

private struct GeneralTab: View {
    @ObservedObject private var preferences = Preferences.shared
    @State private var hookStatus: HookInstaller.HookStatus = HookInstaller.inspect()
    @State private var hookDetails: [String] = []

    var body: some View {
        Form {
            Section {
                HStack {
                    Circle()
                        .fill(hookStatusColor)
                        .frame(width: 8, height: 8)
                    Text("Hook Status: \(hookStatus.label)")
                    Spacer()
                }

                if !hookDetails.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(hookDetails, id: \.self) { detail in
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button("Inspect") {
                        refreshStatus()
                    }

                    switch hookStatus {
                    case .missing:
                        Button("Install Hooks") {
                            try? HookInstaller.install()
                            refreshStatus()
                        }
                        .buttonStyle(.borderedProminent)

                    case .outdated:
                        Button("Update Hooks") {
                            try? HookInstaller.install()
                            refreshStatus()
                        }
                        .buttonStyle(.borderedProminent)

                    case .installed:
                        Button("Remove Hooks") {
                            try? HookInstaller.uninstall()
                            refreshStatus()
                        }
                    }
                }
            } header: {
                Text("Hooks")
            } footer: {
                Text("CodeBar uses Claude Code hooks to receive real-time session updates. Hooks are stored in ~/.claude/settings.json.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Picker("Status display", selection: $preferences.statusDisplayMode) {
                    ForEach(StatusDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
            } header: {
                Text("Menu Bar")
            } footer: {
                Text(preferences.statusDisplayMode.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Verbose hook logging", isOn: $preferences.debugLoggingEnabled)
            } header: {
                Text("Logging")
            } footer: {
                Text("Logs raw hook payloads to ~/.codebar.log for debugging.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var hookStatusColor: Color {
        switch hookStatus {
        case .installed: .green
        case .outdated: .orange
        case .missing: .red
        }
    }

    private func refreshStatus() {
        hookStatus = HookInstaller.inspect()
        if case .outdated(let reasons) = hookStatus {
            hookDetails = reasons
        } else {
            hookDetails = []
        }
    }
}

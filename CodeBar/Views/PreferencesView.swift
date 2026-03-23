import AppKit
import SwiftUI

struct PreferencesView: View {
    var body: some View {
        GeneralTab()
            .frame(minWidth: 460, idealWidth: 480)
    }
}

// MARK: - General Tab

private struct GeneralTab: View {
    @ObservedObject private var preferences = Preferences.shared
    @State private var hookStatus: HookInstaller.HookStatus = HookInstaller.inspect()
    @State private var hookDetails: [String] = []

    var body: some View {
        Form {
            // MARK: Hooks
            Section {
                LabeledContent("Status") {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(hookStatusColor)
                            .frame(width: 8, height: 8)
                        Text(hookStatus.label)
                            .foregroundStyle(hookStatusColor)
                            .font(.system(.body, weight: .medium))
                    }
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
                Label("Hooks", systemImage: "link")
            } footer: {
                Text("CodeBar uses Claude Code hooks to receive real-time session updates. Hooks are stored in ~/.claude/settings.json.")
            }

            // MARK: Menu Bar
            Section {
                Picker("Status display", selection: $preferences.statusDisplayMode) {
                    ForEach(StatusDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
            } header: {
                Label("Menu Bar", systemImage: "menubar.rectangle")
            } footer: {
                Text(preferences.statusDisplayMode.description)
            }

            // MARK: Logging
            Section {
                Toggle("Verbose hook logging", isOn: $preferences.debugLoggingEnabled)

                if preferences.debugLoggingEnabled {
                    LabeledContent("Log file") {
                        HStack(spacing: 6) {
                            Text("~/.codebar.log")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                            Button {
                                let url = FileManager.default.homeDirectoryForCurrentUser
                                    .appendingPathComponent(".codebar.log")
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            } label: {
                                Image(systemName: "arrow.right.circle")
                            }
                            .buttonStyle(.borderless)
                            .help("Reveal in Finder")
                        }
                    }
                }
            } header: {
                Label("Logging", systemImage: "doc.text")
            } footer: {
                Text(preferences.debugLoggingEnabled
                    ? "Verbose logging is active. Hook payloads are written to ~/.codebar.log."
                    : "Enable to log raw hook payloads to ~/.codebar.log for debugging.")
            }
        }
        .formStyle(.grouped)
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

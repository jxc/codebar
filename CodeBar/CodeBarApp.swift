import SwiftUI

@main
struct CodeBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var sessionManager = AppState.shared.sessionManager
    @ObservedObject private var preferences = Preferences.shared

    var body: some Scene {
        MenuBarExtra {
            SessionListView(sessionManager: sessionManager)
                .frame(width: 320)
        } label: {
            Image(nsImage: MenuBarIcon.image(
                sessions: sessionManager.sessions,
                displayMode: preferences.statusDisplayMode,
                shapeMode: preferences.effectiveShapeMode,
                colorTheme: preferences.effectiveColorTheme
            ))
        }
        .menuBarExtraStyle(.window)
    }
}

/// Shared state accessible from both the App and AppDelegate.
@MainActor
enum AppState {
    static let shared = AppStateContainer()
}

@MainActor
final class AppStateContainer {
    let sessionManager = SessionManager()
    var hookServer: HookServer?

    func startServer() {
        guard hookServer == nil else { return }
        let manager = sessionManager
        let server = HookServer { event in
            Task { @MainActor in
                manager.handleHookEvent(event)
            }
        }
        do {
            try server.start()
            hookServer = server
        } catch {
            print("[CodeBar] Failed to start hook server: \(error)")
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppState.shared.startServer()
    }
}

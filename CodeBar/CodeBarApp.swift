import SwiftUI

@main
struct CodeBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            SessionListView(sessionManager: appDelegate.sessionManager)
        } label: {
            Image(nsImage: MenuBarIcon.image(for: appDelegate.sessionManager.aggregateStatus))
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let sessionManager = SessionManager()
    private var hookServer: HookServer?

    func applicationDidFinishLaunching(_ notification: Notification) {
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

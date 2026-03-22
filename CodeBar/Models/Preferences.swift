import Foundation
import SwiftUI

@MainActor
final class Preferences: ObservableObject {
    static let shared = Preferences()

    @AppStorage("debugLogging") var debugLoggingEnabled: Bool = false
}

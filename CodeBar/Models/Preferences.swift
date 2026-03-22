import Foundation
import SwiftUI

enum StatusDisplayMode: String, CaseIterable {
    case single          // One aggregated circle (current behavior)
    case activeOnly      // One circle per status that has ≥ 1 session

    var label: String {
        switch self {
        case .single:       "Single circle"
        case .activeOnly:   "All active statuses"
        }
    }

    var description: String {
        switch self {
        case .single:       "One circle showing the highest-severity status"
        case .activeOnly:   "One circle per active status with a session count"
        }
    }
}

@MainActor
final class Preferences: ObservableObject {
    static let shared = Preferences()

    @AppStorage("debugLogging") var debugLoggingEnabled: Bool = false
    @AppStorage("statusDisplayMode") var statusDisplayMode: StatusDisplayMode = .single
}

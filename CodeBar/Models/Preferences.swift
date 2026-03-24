import AppKit
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

enum StatusShapeMode: String, CaseIterable {
    case circles         // All filled circles (current behavior)
    case shapes          // Circle=idle, Diamond=working, Triangle=blocked

    var label: String {
        switch self {
        case .circles:  "Circles only"
        case .shapes:   "Distinct shapes"
        }
    }

    var description: String {
        switch self {
        case .circles:  "All statuses shown as colored circles"
        case .shapes:   "Uses circle, diamond, and triangle to distinguish status without relying on color"
        }
    }
}

enum ColorTheme: String, CaseIterable {
    case standard
    case colorBlindSafe
    case highContrast

    var label: String {
        switch self {
        case .standard:       "Standard"
        case .colorBlindSafe: "Color-blind safe"
        case .highContrast:   "High contrast"
        }
    }

    var description: String {
        switch self {
        case .standard:       "Default colors: gray, cyan, orange"
        case .colorBlindSafe: "Optimized for color vision deficiency: gray, blue, vermilion"
        case .highContrast:   "Maximum contrast: white, blue, red"
        }
    }
}

@MainActor
final class Preferences: ObservableObject {
    static let shared = Preferences()

    @AppStorage("debugLogging") var debugLoggingEnabled: Bool = false
    @AppStorage("statusDisplayMode") var statusDisplayMode: StatusDisplayMode = .single
    @AppStorage("statusShapeMode") var statusShapeMode: StatusShapeMode = .circles
    @AppStorage("colorTheme") var colorTheme: ColorTheme = .standard

    /// Returns `.shapes` when macOS "Differentiate without color" is enabled,
    /// otherwise returns the user's stored preference.
    var effectiveShapeMode: StatusShapeMode {
        if NSWorkspace.shared.accessibilityDisplayShouldDifferentiateWithoutColor {
            return .shapes
        }
        return statusShapeMode
    }

    /// Returns `.highContrast` when macOS "Increase contrast" is enabled,
    /// otherwise returns the user's stored preference.
    var effectiveColorTheme: ColorTheme {
        if NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast {
            return .highContrast
        }
        return colorTheme
    }
}

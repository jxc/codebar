import AppKit
import SwiftUI

enum StatusAppearance {

    // MARK: - AppKit Colors (for MenuBarIcon)

    static func nsColor(for status: SessionStatus, theme: ColorTheme) -> NSColor {
        switch (status, theme) {
        // None — always gray stroked, theme doesn't matter
        case (.none, _):
            return NSColor.gray.withAlphaComponent(0.5)

        // Idle
        case (.idle, .standard),
             (.idle, .colorBlindSafe):
            return NSColor.gray
        case (.idle, .highContrast):
            return NSColor.white

        // Working
        case (.working, .standard):
            return NSColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 1.0)  // cyan
        case (.working, .colorBlindSafe),
             (.working, .highContrast):
            return NSColor.systemBlue

        // Blocked
        case (.blocked, .standard):
            return NSColor.systemOrange
        case (.blocked, .colorBlindSafe):
            return NSColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 1.0)  // vermilion #FF4500
        case (.blocked, .highContrast):
            return NSColor.systemRed
        }
    }

    // MARK: - SwiftUI Colors (for SessionRowView / PreferencesView)

    static func color(for status: SessionStatus, theme: ColorTheme) -> Color {
        switch (status, theme) {
        case (.none, _):
            return Color.gray.opacity(0.5)

        case (.idle, .standard),
             (.idle, .colorBlindSafe):
            return .gray
        case (.idle, .highContrast):
            return .white

        case (.working, .standard):
            return Color(red: 0.0, green: 0.75, blue: 1.0)
        case (.working, .colorBlindSafe),
             (.working, .highContrast):
            return .blue

        case (.blocked, .standard):
            return .orange
        case (.blocked, .colorBlindSafe):
            return Color(red: 1.0, green: 0.27, blue: 0.0)
        case (.blocked, .highContrast):
            return .red
        }
    }

    // MARK: - SF Symbol Names (for SwiftUI views)

    static func sfSymbolName(for status: SessionStatus, shapeMode: StatusShapeMode) -> String {
        switch shapeMode {
        case .circles:
            return status == .none ? "circle" : "circle.fill"
        case .shapes:
            switch status {
            case .none:     return "circle"
            case .idle:     return "circle.fill"
            case .working:  return "diamond.fill"
            case .blocked:  return "triangle.fill"
            }
        }
    }

    // MARK: - AppKit Shape Drawing (for MenuBarIcon NSImage)

    static func drawShape(
        for status: SessionStatus,
        shapeMode: StatusShapeMode,
        theme: ColorTheme,
        in rect: NSRect
    ) {
        let color = nsColor(for: status, theme: theme)

        // None is always a stroked circle regardless of shape mode
        if status == .none {
            color.setStroke()
            let path = NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1))
            path.lineWidth = 1.5
            path.stroke()
            return
        }

        color.setFill()

        switch shapeMode {
        case .circles:
            NSBezierPath(ovalIn: rect).fill()

        case .shapes:
            switch status {
            case .none:
                break  // handled above
            case .idle:
                NSBezierPath(ovalIn: rect).fill()
            case .working:
                drawDiamond(in: rect)
            case .blocked:
                drawTriangle(in: rect)
            }
        }
    }

    // MARK: - Shape Primitives

    private static func drawDiamond(in rect: NSRect) {
        let inset = rect.insetBy(dx: 1, dy: 1)
        let midX = inset.midX
        let midY = inset.midY

        let path = NSBezierPath()
        path.move(to: NSPoint(x: midX, y: inset.maxY))       // top
        path.line(to: NSPoint(x: inset.maxX, y: midY))       // right
        path.line(to: NSPoint(x: midX, y: inset.minY))       // bottom
        path.line(to: NSPoint(x: inset.minX, y: midY))       // left
        path.close()
        path.fill()
    }

    private static func drawTriangle(in rect: NSRect) {
        let inset = rect.insetBy(dx: 1, dy: 1)
        let midX = inset.midX

        let path = NSBezierPath()
        path.move(to: NSPoint(x: midX, y: inset.maxY))       // top center
        path.line(to: NSPoint(x: inset.maxX, y: inset.minY)) // bottom right
        path.line(to: NSPoint(x: inset.minX, y: inset.minY)) // bottom left
        path.close()
        path.fill()
    }
}

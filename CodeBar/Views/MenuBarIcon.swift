import AppKit
import SwiftUI

enum MenuBarIcon {
    private static let size = NSSize(width: 18, height: 18)

    static func image(for status: SessionStatus) -> NSImage {
        let image = NSImage(size: size, flipped: false) { rect in
            let inset: CGFloat = 3
            let circleRect = rect.insetBy(dx: inset, dy: inset)

            switch status {
            case .none:
                // Hollow gray circle
                NSColor.gray.withAlphaComponent(0.5).setStroke()
                let path = NSBezierPath(ovalIn: circleRect.insetBy(dx: 0.5, dy: 0.5))
                path.lineWidth = 1.5
                path.stroke()

            case .idle:
                // Hollow gray circle
                NSColor.gray.setStroke()
                let path = NSBezierPath(ovalIn: circleRect.insetBy(dx: 0.5, dy: 0.5))
                path.lineWidth = 1.5
                path.stroke()

            case .working:
                // Filled blue circle
                NSColor.systemBlue.setFill()
                NSBezierPath(ovalIn: circleRect).fill()

            case .blocked:
                // Filled orange circle
                NSColor.systemOrange.setFill()
                NSBezierPath(ovalIn: circleRect).fill()
            }

            return true
        }

        // Template images adapt to light/dark menu bar automatically
        // but we only want that for the hollow states
        image.isTemplate = (status == .none || status == .idle)
        return image
    }
}

import AppKit
import SwiftUI

enum MenuBarIcon {
    static func image(for status: SessionStatus, sessionCount: Int = 0) -> NSImage {
        let circleSize: CGFloat = 16
        let font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .bold)

        // Measure count text
        let countText = sessionCount > 0 ? "\(min(sessionCount, 9))" : nil
        let countAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white
        ]
        let countSize = countText.map { NSAttributedString(string: $0, attributes: countAttrs).size() }
            ?? .zero

        let spacing: CGFloat = 3
        let totalWidth = circleSize + (countText != nil ? spacing + countSize.width + 1 : 0)
        let size = NSSize(width: max(totalWidth, 18), height: 18)

        let image = NSImage(size: size, flipped: false) { rect in
            let circleY = (rect.height - circleSize) / 2
            let circleRect = NSRect(x: 0, y: circleY, width: circleSize, height: circleSize)

            switch status {
            case .none:
                // Hollow circle — no sessions
                NSColor.gray.withAlphaComponent(0.5).setStroke()
                let path = NSBezierPath(ovalIn: circleRect.insetBy(dx: 1, dy: 1))
                path.lineWidth = 1.5
                path.stroke()

            case .idle:
                NSColor.gray.setFill()
                NSBezierPath(ovalIn: circleRect).fill()

            case .working:
                NSColor.systemBlue.setFill()
                NSBezierPath(ovalIn: circleRect).fill()

            case .blocked:
                NSColor.systemOrange.setFill()
                NSBezierPath(ovalIn: circleRect).fill()
            }

            // Draw session count next to circle
            if let text = countText, status != .none {
                let textAttrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: NSColor.headerTextColor
                ]
                let textOrigin = NSPoint(
                    x: circleRect.maxX + spacing,
                    y: (rect.height - countSize.height) / 2
                )
                NSAttributedString(string: text, attributes: textAttrs).draw(at: textOrigin)
            }

            return true
        }

        image.isTemplate = (status == .none)
        return image
    }
}

import AppKit
import SwiftUI

enum MenuBarIcon {

    // MARK: - Public API

    static func image(
        sessions: [Session],
        displayMode: StatusDisplayMode,
        shapeMode: StatusShapeMode,
        colorTheme: ColorTheme
    ) -> NSImage {
        if sessions.isEmpty {
            return singleCircleImage(status: .none, count: 0, shapeMode: shapeMode, colorTheme: colorTheme)
        }

        switch displayMode {
        case .single:
            let aggregate = sessions.map(\.status).max() ?? .none
            return singleCircleImage(status: aggregate, count: sessions.count, shapeMode: shapeMode, colorTheme: colorTheme)

        case .activeOnly:
            let counts = statusCounts(from: sessions)
            let entries = displayStatuses.compactMap { status -> (SessionStatus, Int)? in
                guard let count = counts[status], count > 0 else { return nil }
                return (status, count)
            }
            guard !entries.isEmpty else {
                return singleCircleImage(status: .none, count: 0, shapeMode: shapeMode, colorTheme: colorTheme)
            }
            return multiCircleImage(entries: entries, shapeMode: shapeMode, colorTheme: colorTheme)
        }
    }

    /// Legacy convenience — used by tests and anywhere that still passes aggregate status.
    static func image(
        for status: SessionStatus,
        sessionCount: Int = 0,
        shapeMode: StatusShapeMode = .circles,
        colorTheme: ColorTheme = .standard
    ) -> NSImage {
        singleCircleImage(status: status, count: sessionCount, shapeMode: shapeMode, colorTheme: colorTheme)
    }

    // MARK: - Statuses (in display order: idle → working → blocked)

    private static let displayStatuses: [SessionStatus] = [.idle, .working, .blocked]

    // MARK: - Helpers

    private static func statusCounts(from sessions: [Session]) -> [SessionStatus: Int] {
        sessions.reduce(into: [:]) { result, session in
            result[session.status, default: 0] += 1
        }
    }

    // MARK: - Single Circle (original behavior)

    private static func singleCircleImage(
        status: SessionStatus,
        count: Int,
        shapeMode: StatusShapeMode,
        colorTheme: ColorTheme
    ) -> NSImage {
        let circleSize: CGFloat = 16
        let font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .bold)

        let countText = count > 0 ? "\(min(count, 9))" : nil
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

            StatusAppearance.drawShape(for: status, shapeMode: shapeMode, theme: colorTheme, in: circleRect)

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

    // MARK: - Multi Circle

    private static func multiCircleImage(
        entries: [(SessionStatus, Int)],
        shapeMode: StatusShapeMode,
        colorTheme: ColorTheme
    ) -> NSImage {
        let circleSize: CGFloat = 16
        let font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .bold)
        let innerSpacing: CGFloat = 3   // circle → count digit
        let groupSpacing: CGFloat = 6   // between groups

        // Pre-measure each group
        struct Group {
            let status: SessionStatus
            let count: Int
            let countText: String
            let textSize: CGSize
            let width: CGFloat
        }

        let countAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white
        ]

        let groups: [Group] = entries.map { status, count in
            let text = "\(min(count, 9))"
            let textSize = NSAttributedString(string: text, attributes: countAttrs).size()
            let width = circleSize + innerSpacing + textSize.width
            return Group(status: status, count: count, countText: text, textSize: textSize, width: width)
        }

        let totalWidth = groups.map(\.width).reduce(0, +) + CGFloat(max(groups.count - 1, 0)) * groupSpacing
        let size = NSSize(width: max(totalWidth, 18), height: 18)

        let image = NSImage(size: size, flipped: false) { rect in
            var x: CGFloat = 0

            for group in groups {
                let circleY = (rect.height - circleSize) / 2
                let circleRect = NSRect(x: x, y: circleY, width: circleSize, height: circleSize)

                StatusAppearance.drawShape(for: group.status, shapeMode: shapeMode, theme: colorTheme, in: circleRect)

                let textAttrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: NSColor.headerTextColor
                ]
                let textOrigin = NSPoint(
                    x: circleRect.maxX + innerSpacing,
                    y: (rect.height - group.textSize.height) / 2
                )
                NSAttributedString(string: group.countText, attributes: textAttrs).draw(at: textOrigin)

                x += group.width + groupSpacing
            }

            return true
        }

        image.isTemplate = false
        return image
    }
}

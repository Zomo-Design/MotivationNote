import AppKit

enum WindowBehavior {
    static func level(
        alwaysOnTop: Bool
    ) -> NSWindow.Level {
        alwaysOnTop ? .floating : .normal
    }

    static func clampedOrigin(
        _ origin: NSPoint,
        windowSize: NSSize,
        visibleFrame: NSRect
    ) -> NSPoint {
        let maximumX = max(
            visibleFrame.minX,
            visibleFrame.maxX - windowSize.width
        )
        let maximumY = max(
            visibleFrame.minY,
            visibleFrame.maxY - windowSize.height
        )

        return NSPoint(
            x: min(
                max(origin.x, visibleFrame.minX),
                maximumX
            ),
            y: min(
                max(origin.y, visibleFrame.minY),
                maximumY
            )
        )
    }
}

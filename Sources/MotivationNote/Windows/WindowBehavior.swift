import AppKit

enum WindowBehavior {
    static let paperContentWidth: CGFloat = 350
    static let windowHorizontalInset: CGFloat = 12
    static let noteWindowWidth =
        paperContentWidth + windowHorizontalInset * 2
    static let desktopNoteLevel = NSWindow.Level.normal
    static let hidesOnDeactivate = false

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

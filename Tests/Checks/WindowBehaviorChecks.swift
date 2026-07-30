import AppKit

@main
enum WindowBehaviorChecks {
    static func main() {
        runCheckSuite("WindowBehavior", checks: [
            regularModeUsesNormalWindowLevel,
            alwaysOnTopUsesFloatingLevel,
            draggingIsClampedToVisibleScreen
        ])
    }

    private static func regularModeUsesNormalWindowLevel() throws {
        try expect(
            WindowBehavior.level(alwaysOnTop: false) == .normal,
            "Regular note must stay above the desktop window layer"
        )
    }

    private static func alwaysOnTopUsesFloatingLevel() throws {
        try expect(
            WindowBehavior.level(alwaysOnTop: true) == .floating,
            "Pinned note must use floating window level"
        )
    }

    private static func draggingIsClampedToVisibleScreen() throws {
        let visible = NSRect(
            x: 0,
            y: 74,
            width: 1728,
            height: 1010
        )
        let size = NSSize(width: 304, height: 360)

        let tooFarLeft = WindowBehavior.clampedOrigin(
            NSPoint(x: -900, y: 500),
            windowSize: size,
            visibleFrame: visible
        )
        let tooFarRight = WindowBehavior.clampedOrigin(
            NSPoint(x: 3000, y: 500),
            windowSize: size,
            visibleFrame: visible
        )
        let tooHigh = WindowBehavior.clampedOrigin(
            NSPoint(x: 500, y: 2000),
            windowSize: size,
            visibleFrame: visible
        )
        let tooLow = WindowBehavior.clampedOrigin(
            NSPoint(x: 500, y: -500),
            windowSize: size,
            visibleFrame: visible
        )

        try expect(tooFarLeft.x == 0, "Left edge should be clamped")
        try expect(tooFarRight.x == 1424, "Right edge should be clamped")
        try expect(tooHigh.y == 724, "Top edge should be clamped")
        try expect(tooLow.y == 74, "Bottom edge should be clamped")
    }
}

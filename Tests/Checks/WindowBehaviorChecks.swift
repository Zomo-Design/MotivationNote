import AppKit

@main
enum WindowBehaviorChecks {
    static func main() {
        runCheckSuite("WindowBehavior", checks: [
            desktopNoteUsesNormalWindowLevel,
            noteDoesNotHideWhenAnotherAppBecomesActive,
            noteUsesApprovedWidth,
            draggingIsClampedToVisibleScreen
        ])
    }

    private static func desktopNoteUsesNormalWindowLevel() throws {
        try expect(
            WindowBehavior.desktopNoteLevel == .normal,
            "Normal application windows must cover the desktop note"
        )
    }

    private static func noteDoesNotHideWhenAnotherAppBecomesActive() throws {
        try expect(
            !WindowBehavior.hidesOnDeactivate,
            "Desktop note must remain visible when another app becomes active"
        )
    }

    private static func noteUsesApprovedWidth() throws {
        try expect(
            WindowBehavior.paperContentWidth == 350,
            "Paper content width should be 350pt"
        )
        try expect(
            WindowBehavior.noteWindowWidth == 374,
            "Window width should include 12pt on each side"
        )
    }

    private static func draggingIsClampedToVisibleScreen() throws {
        let visible = NSRect(
            x: 0,
            y: 74,
            width: 1728,
            height: 1010
        )
        let size = NSSize(
            width: WindowBehavior.noteWindowWidth,
            height: 360
        )

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
        try expect(tooFarRight.x == 1354, "Right edge should be clamped")
        try expect(tooHigh.y == 724, "Top edge should be clamped")
        try expect(tooLow.y == 74, "Bottom edge should be clamped")
    }
}

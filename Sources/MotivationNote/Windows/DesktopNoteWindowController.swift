import AppKit
import Combine
import SwiftUI

@MainActor
final class DesktopNoteWindowController:
    NSWindowController,
    NSWindowDelegate
{
    private let model: AppModel
    private let noteWidth: CGFloat = 304
    private var cancellables = Set<AnyCancellable>()

    init(
        model: AppModel,
        openManager: @escaping () -> Void
    ) {
        self.model = model

        let panel = NSPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: 304,
                height: 360
            ),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        super.init(window: panel)

        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate =
            WindowBehavior.hidesOnDeactivate
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary
        ]
        panel.delegate = self
        panel.contentView = NSHostingView(
            rootView: DesktopNoteView(
                model: model,
                openManager: openManager,
                onHeightChange: {
                    [weak self] height in
                    self?.resize(to: height)
                }
            )
        )

        updateLevel(alwaysOnTop: model.data.alwaysOnTop)
        restorePosition()

        model.$data
            .map { $0.alwaysOnTop }
            .removeDuplicates()
            .sink { [weak self] alwaysOnTop in
                self?.updateLevel(
                    alwaysOnTop: alwaysOnTop
                )
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError(
            "DesktopNoteWindowController only supports programmatic creation"
        )
    }

    private func updateLevel(alwaysOnTop: Bool) {
        window?.level = WindowBehavior.level(
            alwaysOnTop: alwaysOnTop
        )
    }

    private func restorePosition() {
        guard let window else {
            return
        }

        let visible = NSScreen.main?.visibleFrame
            ?? NSRect(
                x: 0,
                y: 0,
                width: 1440,
                height: 900
            )
        let proposed = model.data.windowPosition.map {
            NSPoint(x: $0.x, y: $0.y)
        } ?? NSPoint(
            x: visible.maxX - noteWidth - 36,
            y: visible.maxY - window.frame.height - 36
        )
        let safeOrigin = WindowBehavior.clampedOrigin(
            proposed,
            windowSize: window.frame.size,
            visibleFrame: visible
        )
        window.setFrameOrigin(safeOrigin)
    }

    private func visibleFrame(
        for origin: NSPoint
    ) -> NSRect {
        let screen = NSScreen.screens.first {
            $0.visibleFrame.contains(origin)
        } ?? NSScreen.main

        return screen?.visibleFrame
            ?? NSRect(
                x: 0,
                y: 0,
                width: 1440,
                height: 900
            )
    }

    private func resize(to requestedHeight: CGFloat) {
        guard let window else {
            return
        }

        let visibleHeight = (
            window.screen ?? NSScreen.main
        )?.visibleFrame.height ?? 900
        let height = min(
            max(requestedHeight, 180),
            visibleHeight - 40
        )
        var frame = window.frame
        let top = frame.maxY
        frame.size = NSSize(
            width: noteWidth,
            height: height
        )
        frame.origin.y = top - height
        frame.origin = WindowBehavior.clampedOrigin(
            frame.origin,
            windowSize: frame.size,
            visibleFrame: visibleFrame(for: frame.origin)
        )

        guard
            abs(frame.height - window.frame.height) > 0.5
                || abs(frame.origin.y - window.frame.origin.y) > 0.5
        else {
            return
        }

        let shouldAnimate = !NSWorkspace.shared
            .accessibilityDisplayShouldReduceMotion
        window.setFrame(
            frame,
            display: true,
            animate: shouldAnimate
        )
    }

    func windowDidMove(_ notification: Notification) {
        guard let window else {
            return
        }

        let origin = window.frame.origin
        let safeOrigin = WindowBehavior.clampedOrigin(
            origin,
            windowSize: window.frame.size,
            visibleFrame: visibleFrame(for: origin)
        )
        if safeOrigin != origin {
            window.setFrameOrigin(safeOrigin)
            return
        }

        let position = WindowPosition(
            x: safeOrigin.x,
            y: safeOrigin.y
        )
        guard model.data.windowPosition != position else {
            return
        }
        model.setWindowPosition(position)
    }

    func bringBackToVisibleScreen() {
        guard let window else {
            return
        }

        let visible = NSScreen.main?.visibleFrame
            ?? NSRect(
                x: 0,
                y: 0,
                width: 1440,
                height: 900
            )
        var frame = window.frame
        frame.origin = NSPoint(
            x: visible.maxX - frame.width - 36,
            y: visible.maxY - frame.height - 36
        )
        frame.origin = WindowBehavior.clampedOrigin(
            frame.origin,
            windowSize: frame.size,
            visibleFrame: visible
        )
        window.setFrame(
            frame,
            display: true,
            animate: false
        )
        window.orderFrontRegardless()
    }
}

import AppKit
import SwiftUI

@MainActor
final class ManagerWindowController: NSWindowController {
    init(model: AppModel) {
        let window = NSWindow(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: 760,
                height: 640
            ),
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
                .resizable
            ],
            backing: .buffered,
            defer: false
        )
        window.title = "我的激励语录"
        window.minSize = NSSize(width: 680, height: 560)
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: ManagerView(model: model)
        )

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError(
            "ManagerWindowController only supports programmatic creation"
        )
    }

    func show() {
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}

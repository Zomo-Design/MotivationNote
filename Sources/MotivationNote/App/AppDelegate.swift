import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel(store: JSONLocalStore())
    private var desktopController: DesktopNoteWindowController!
    private var managerController: ManagerWindowController!

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {
        managerController = ManagerWindowController(model: model)
        desktopController = DesktopNoteWindowController(
            model: model,
            openManager: { [weak self] in
                self?.managerController.show()
            }
        )

        installMainMenu()
        desktopController.showWindow(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        false
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        managerController.show()
        return true
    }

    @objc
    private func showManager() {
        managerController.show()
    }

    @objc
    private func bringBackNote() {
        desktopController.bringBackToVisibleScreen()
    }

    @objc
    private func quit() {
        NSApp.terminate(nil)
    }

    private func installMainMenu() {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        menu.addItem(appItem)

        let appMenu = NSMenu()
        appMenu.addItem(
            withTitle: "打开语录管理",
            action: #selector(showManager),
            keyEquivalent: ","
        )
        appMenu.addItem(
            withTitle: "找回桌面便签",
            action: #selector(bringBackNote),
            keyEquivalent: "r"
        )
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: "退出激励便签",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        appItem.submenu = appMenu
        NSApp.mainMenu = menu
    }
}

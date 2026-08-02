# MotivationNote · 激励便签

A private, offline-first motivational note for the macOS desktop. Save quotes,
choose what you want to see today, reorder them, and customize the paper — with
no account, analytics, or network access.

一款完全离线的 macOS 桌面激励便签：收藏语录、选择今日展示内容、拖动排序并自定义纸张外观。无需账号，不收集数据，也不会联网。

## Why this project

Most note apps live inside a window. MotivationNote stays quietly on the desktop
and is naturally covered by normal app windows, so it is visible when useful
without becoming distracting. User data is stored locally as readable JSON and
written atomically.

## Features

- Native SwiftUI/AppKit app for macOS 14+
- Multiple quotes on the desktop with drag-to-reorder
- Quote creation, editing, selection, and confirmed deletion
- Custom paper colors and textures
- Desktop-aware window behavior and a “Find Desktop Note” command
- Offline-only storage; no telemetry or external services
- Dependency-free Swift package with executable behavior checks

## Build and run

Requirements: macOS 14 or later, Xcode 16 or a Swift 6 toolchain.

```bash
git clone https://github.com/nuonuostyjo-design/MotivationNote.git
cd MotivationNote
./scripts/run-checks.sh
./scripts/build-app.sh
open "dist/激励便签.app"
```

The build script creates an ad-hoc signed app bundle at `dist/激励便签.app`.
Because the app is not notarized, macOS may ask you to allow it in
**System Settings → Privacy & Security**.

## 使用方法

- 首次启动会显示三条示例语录，桌面便签默认展示第一条。
- 点击便签右上角的“•••”打开“我的激励语录”。
- 点击“新增语录”收藏一句话。
- 在“今日展示”中勾选任意数量的语录，并拖动调整顺序。
- 在“全部语录”中编辑内容，或通过垃圾桶/右键菜单删除语录。
- 在“纸张外观”中组合不同的颜色和纹理。
- 如果便签位置不方便，可从应用菜单选择“找回桌面便签”，或按 Command+R。

Data is stored locally at:

```text
~/Library/Application Support/MotivationNote/data.json
```

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for
the development workflow and [SECURITY.md](SECURITY.md) for reporting security
problems.

## License

MIT © 2026 MotivationNote contributors.

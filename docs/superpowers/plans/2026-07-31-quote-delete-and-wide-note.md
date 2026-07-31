# 语录删除与加宽便签 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将桌面纸张宽度增加到 `350pt`，并在“今日展示”和“全部语录”中提供清晰、安全、统一的删除入口。

**Architecture:** 桌面便签固定使用 AppKit 的普通窗口层级，让当前应用窗口自然覆盖它，同时保留失焦可见行为。`WindowBehavior` 作为 SwiftUI 与 AppKit 共享的唯一尺寸来源，避免纸张和窗口宽度不一致。新增可复用的 SwiftUI 删除确认修饰器，两个管理页面只负责选择删除候选，最终仍调用现有的 `AppModel.deleteQuote(id:)`。

**Tech Stack:** Swift 6.0、SwiftUI、AppKit、自包含 Swift checks、macOS 14+

## Global Constraints

- 纸张内容宽度必须为 `350pt`，窗口总宽度必须为 `374pt`。
- 字号、内边距、纸张纹理、圆角与始终置顶行为保持不变。
- 今日展示的已选和未选语录都必须支持按钮删除与右键删除。
- 全部语录必须支持明显的危险操作按钮、右键编辑与右键删除。
- 所有删除操作必须先显示原生确认弹窗。
- 取消删除不能改变数据；确认删除继续使用 `AppModel.deleteQuote(id:)`。
- 桌面便签不得浮在普通应用窗口上方。
- 切换应用后，如果没有窗口遮挡，桌面便签仍须保持可见。
- 应用保持完全离线，不添加第三方依赖。

---

### Task 0: 修复桌面便签错误置顶

**Root cause:**

- 当前持久化数据中的 `alwaysOnTop` 为 `true`。
- `WindowBehavior.level(alwaysOnTop: true)` 返回 `.floating`。
- `DesktopNoteWindowController` 将该层级应用到面板，因此普通应用窗口无法覆盖便签。

**Files:**
- Modify: `Tests/Checks/WindowBehaviorChecks.swift`
- Modify: `Tests/Checks/AppDataChecks.swift`
- Modify: `Sources/MotivationNote/Windows/WindowBehavior.swift`
- Modify: `Sources/MotivationNote/Windows/DesktopNoteWindowController.swift`
- Modify: `Sources/MotivationNote/Views/Manager/AppearanceSettingsView.swift`
- Modify: `Sources/MotivationNote/Models/AppData.swift`

**Interfaces:**
- Produces: `WindowBehavior.desktopNoteLevel: NSWindow.Level`
- Preserves: `WindowBehavior.hidesOnDeactivate == false`
- Retains: `AppData.alwaysOnTop` 仅用于兼容读取已有数据

- [ ] **Step 1: 写窗口层级失败检查**

将 `WindowBehaviorChecks` 中的两项动态层级检查替换为：

```swift
private static func desktopNoteUsesNormalWindowLevel() throws {
    try expect(
        WindowBehavior.desktopNoteLevel == .normal,
        "Normal application windows must cover the desktop note"
    )
}
```

将 `AppDataChecks` 中的默认值期望改为：

```swift
try expect(
    !data.alwaysOnTop,
    "Legacy pin state should default to disabled"
)
```

- [ ] **Step 2: 运行检查并确认新接口尚不存在**

Run: `./scripts/run-checks.sh`

Expected: FAIL，错误包含 `type 'WindowBehavior' has no member 'desktopNoteLevel'`。

- [ ] **Step 3: 固定普通窗口层级并移除置顶入口**

在 `WindowBehavior` 中用以下常量替换 `level(alwaysOnTop:)`：

```swift
static let desktopNoteLevel = NSWindow.Level.normal
```

在 `DesktopNoteWindowController` 中：

- 移除 `Combine`、`cancellables` 和 `alwaysOnTop` 订阅。
- 初始化面板时直接设置：

```swift
panel.level = WindowBehavior.desktopNoteLevel
```

在 `AppearanceSettingsView` 中移除“始终置顶”开关及其视图属性。将 `AppData` 的 `alwaysOnTop` 默认值改回 `false`；字段本身保留，保证当前用户数据仍可解码，但不再影响窗口层级。

- [ ] **Step 4: 验证窗口行为**

Run:

```bash
./scripts/run-checks.sh
swift build
```

Expected: checks 全部 PASS；Swift build 成功。

- [ ] **Step 5: 提交窗口层级修复**

```bash
git add Tests/Checks/WindowBehaviorChecks.swift \
  Tests/Checks/AppDataChecks.swift \
  Sources/MotivationNote/Windows/WindowBehavior.swift \
  Sources/MotivationNote/Windows/DesktopNoteWindowController.swift \
  Sources/MotivationNote/Views/Manager/AppearanceSettingsView.swift \
  Sources/MotivationNote/Models/AppData.swift \
  docs/superpowers/plans/2026-07-31-quote-delete-and-wide-note.md
git commit -m "fix: let normal windows cover desktop note"
```

---

### Task 1: 共享便签尺寸并加宽桌面窗口

**Files:**
- Modify: `Tests/Checks/WindowBehaviorChecks.swift`
- Modify: `Sources/MotivationNote/Windows/WindowBehavior.swift`
- Modify: `Sources/MotivationNote/Views/Desktop/DesktopNoteView.swift`
- Modify: `Sources/MotivationNote/Windows/DesktopNoteWindowController.swift`

**Interfaces:**
- Produces: `WindowBehavior.paperContentWidth: CGFloat`
- Produces: `WindowBehavior.windowHorizontalInset: CGFloat`
- Produces: `WindowBehavior.noteWindowWidth: CGFloat`
- Consumes: 现有的窗口边界、位置恢复和高度调整逻辑

- [ ] **Step 1: 写加宽失败检查**

在 `WindowBehaviorChecks` 的检查数组加入 `noteUsesApprovedWidth`，并加入：

```swift
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
```

将 `draggingIsClampedToVisibleScreen()` 中的尺寸与右边界期望改为：

```swift
let size = NSSize(
    width: WindowBehavior.noteWindowWidth,
    height: 360
)
// 1728 - 374
try expect(tooFarRight.x == 1354, "Right edge should be clamped")
```

- [ ] **Step 2: 运行检查并确认尺寸成员不存在**

Run: `./scripts/run-checks.sh`

Expected: FAIL，错误包含 `type 'WindowBehavior' has no member 'paperContentWidth'`。

- [ ] **Step 3: 实现共享尺寸**

在 `WindowBehavior` 顶部加入：

```swift
static let paperContentWidth: CGFloat = 350
static let windowHorizontalInset: CGFloat = 12
static let noteWindowWidth =
    paperContentWidth + windowHorizontalInset * 2
```

在 `DesktopNoteView` 中替换两个硬编码宽度：

```swift
.frame(width: WindowBehavior.paperContentWidth)
// 保留 rotationEffect 与 padding
.frame(width: WindowBehavior.noteWindowWidth)
```

在 `DesktopNoteWindowController` 中替换 `noteWidth` 与初始窗口宽度：

```swift
private let noteWidth = WindowBehavior.noteWindowWidth

let panel = NSPanel(
    contentRect: NSRect(
        x: 0,
        y: 0,
        width: WindowBehavior.noteWindowWidth,
        height: 360
    ),
    styleMask: [.borderless],
    backing: .buffered,
    defer: false
)
```

- [ ] **Step 4: 验证加宽与窗口边界**

Run:

```bash
./scripts/run-checks.sh
swift build
```

Expected: `WindowBehavior (4 checks)` PASS；Swift build 成功。

- [ ] **Step 5: 提交加宽改动**

```bash
git add Tests/Checks/WindowBehaviorChecks.swift \
  Sources/MotivationNote/Windows/WindowBehavior.swift \
  Sources/MotivationNote/Views/Desktop/DesktopNoteView.swift \
  Sources/MotivationNote/Windows/DesktopNoteWindowController.swift
git commit -m "feat: widen desktop motivation note"
```

---

### Task 2: 两个管理页面统一删除交互

**Files:**
- Create: `Sources/MotivationNote/Views/Manager/QuoteDeleteConfirmation.swift`
- Modify: `Sources/MotivationNote/Views/Manager/TodaySelectionView.swift`
- Modify: `Sources/MotivationNote/Views/Manager/QuoteLibraryView.swift`
- Modify: `Tests/Checks/AppModelChecks.swift`

**Interfaces:**
- Produces: `View.quoteDeleteConfirmation(candidate:onDelete:)`
- Consumes: `Binding<Quote?>`、`AppModel.deleteQuote(id:)`

- [ ] **Step 1: 补充删除最后一条语录的状态检查**

在 `AppModelChecks` 的检查数组加入 `deletingAllQuotesLeavesSafeEmptyState`，并加入：

```swift
private static func deletingAllQuotesLeavesSafeEmptyState() throws {
    let store = MemoryStore(stored: .seeded)
    let model = AppModel(store: store)

    for quote in model.data.quotes {
        model.deleteQuote(id: quote.id)
    }

    try expect(model.data.quotes.isEmpty, "Library should become empty")
    try expect(
        model.selectedQuotes.isEmpty,
        "Selected quotes should become empty"
    )
    try expect(
        store.stored?.quotes.isEmpty == true,
        "Empty library should persist"
    )
}
```

- [ ] **Step 2: 运行状态检查**

Run: `./scripts/run-checks.sh`

Expected: PASS；该检查锁定删除最后一条语录后的安全数据状态。

- [ ] **Step 3: 创建共享删除确认修饰器**

`QuoteDeleteConfirmation.swift`：

```swift
import SwiftUI

private struct QuoteDeleteConfirmationModifier: ViewModifier {
    @Binding var candidate: Quote?
    let onDelete: (Quote) -> Void

    func body(content: Content) -> some View {
        content.alert(
            "确定删除这句语录吗？",
            isPresented: isPresented,
            presenting: candidate
        ) { quote in
            Button("删除", role: .destructive) {
                onDelete(quote)
                candidate = nil
            }
            Button("取消", role: .cancel) {
                candidate = nil
            }
        } message: { quote in
            Text(quote.text)
        }
    }

    private var isPresented: Binding<Bool> {
        Binding(
            get: { candidate != nil },
            set: {
                if !$0 {
                    candidate = nil
                }
            }
        )
    }
}

extension View {
    func quoteDeleteConfirmation(
        candidate: Binding<Quote?>,
        onDelete: @escaping (Quote) -> Void
    ) -> some View {
        modifier(
            QuoteDeleteConfirmationModifier(
                candidate: candidate,
                onDelete: onDelete
            )
        )
    }
}
```

- [ ] **Step 4: 在今日展示增加删除按钮与右键菜单**

在 `TodaySelectionView` 加入：

```swift
@State private var deleteCandidate: Quote?
```

在根视图末尾应用：

```swift
.quoteDeleteConfirmation(
    candidate: $deleteCandidate,
    onDelete: { model.deleteQuote(id: $0.id) }
)
```

将 `selectionRow` 的根 `Button` 改成以下结构，避免按钮嵌套：

```swift
HStack(alignment: .top, spacing: 10) {
    Button {
        model.setSelected(!selected, quoteID: quote.id)
    } label: {
        HStack(alignment: .top, spacing: 10) {
            Image(
                systemName: selected
                    ? "checkmark.circle.fill"
                    : "circle"
            )
            .foregroundStyle(
                selected ? Color.accentColor : Color.secondary
            )

            Text(quote.text)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if selected {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(
        "\(selected ? "移出今日展示" : "加入今日展示")：\(quote.text)"
    )

    Button(role: .destructive) {
        deleteCandidate = quote
    } label: {
        Image(systemName: "trash")
            .foregroundStyle(.red)
    }
    .buttonStyle(.borderless)
    .accessibilityLabel("删除语录：\(quote.text)")
}
.contextMenu {
    Button(role: .destructive) {
        deleteCandidate = quote
    } label: {
        Label("删除语录", systemImage: "trash")
    }
}
```

- [ ] **Step 5: 在全部语录复用删除确认并增加右键菜单**

删除 `QuoteLibraryView` 内原有的 `.alert(...)` 和 `deleteAlertBinding`，改用：

```swift
.quoteDeleteConfirmation(
    candidate: $deleteCandidate,
    onDelete: { model.deleteQuote(id: $0.id) }
)
```

将现有垃圾桶按钮的图标改为：

```swift
Image(systemName: "trash")
    .foregroundStyle(.red)
```

在每一行 `HStack` 后加入：

```swift
.contextMenu {
    Button {
        editingQuote = quote
    } label: {
        Label("编辑语录", systemImage: "pencil")
    }
    Button(role: .destructive) {
        deleteCandidate = quote
    } label: {
        Label("删除语录", systemImage: "trash")
    }
}
```

- [ ] **Step 6: 编译并手工验证取消删除**

Run:

```bash
./scripts/run-checks.sh
swift build
```

Expected: 所有 checks PASS；Swift build 成功。

手工验证：

1. 在“今日展示”点击任意垃圾桶，确认弹窗出现。
2. 点击“取消”，语录和今日选择均不改变。
3. 在“全部语录”右键，能看到“编辑语录”和“删除语录”。
4. 不在验收过程中确认删除用户现有语录。

- [ ] **Step 7: 提交删除交互**

```bash
git add Sources/MotivationNote/Views/Manager \
  Tests/Checks/AppModelChecks.swift
git commit -m "feat: delete quotes from both manager views"
```

---

### Task 3: 正式打包与回归验收

**Files:**
- Modify: `README.md`
- Generated: `dist/激励便签.app`

**Interfaces:**
- Consumes: Tasks 1–2 的最终源码
- Produces: 可双击启动的修订版 `.app`

- [ ] **Step 1: 更新使用说明**

在 `README.md` 的使用列表加入：

```markdown
- 在“今日展示”或“全部语录”中点击垃圾桶，确认后可永久删除已有语录。
- 右键任意语录也可以选择“删除语录”。
```

- [ ] **Step 2: 运行完整自动化验收**

Run:

```bash
./scripts/run-checks.sh
./scripts/build-app.sh
test -x "dist/激励便签.app/Contents/MacOS/MotivationNote"
plutil -lint "dist/激励便签.app/Contents/Info.plist"
codesign --verify --deep --strict "dist/激励便签.app"
```

Expected:

- AppData、AppModel、JSONLocalStore、PaperAppearance、WindowBehavior 全部 PASS。
- `.app` 存在并包含 arm64 可执行文件。
- `Info.plist` 输出 `OK`。
- 签名验证退出码为 0。

- [ ] **Step 3: 运行可视验收**

启动应用后检查：

1. 桌面便签宽度与用户截图中的上方组件接近。
2. 两条长语录的换行明显减少。
3. 切换到其他应用后便签仍可见。
4. 两个管理页面都能看到红色垃圾桶与右键删除菜单。
5. 取消确认弹窗后数据不变。

- [ ] **Step 4: 提交文档并检查状态**

```bash
git add README.md
git commit -m "docs: document quote deletion"
git status --short
```

Expected: 工作树干净。

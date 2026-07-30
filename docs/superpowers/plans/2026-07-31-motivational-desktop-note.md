# 激励便签 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个原生 macOS 激励便签应用，让用户永久保存语录、每天多选并排序展示内容，以及自由组合纸张颜色和纹理。

**Architecture:** 使用 Swift Package Manager 管理无第三方依赖的 Swift 6 应用。SwiftUI 负责便签与管理界面，AppKit 负责应用生命周期、桌面层级窗口、位置恢复和标准 macOS 窗口行为；`AppModel` 是唯一可变状态入口，`JSONLocalStore` 负责原子本地持久化。

**Tech Stack:** Swift 6.0、SwiftUI、AppKit、Observation、XCTest、Swift Package Manager、macOS 14+

## Global Constraints

- 目标平台为 macOS 14 及以上。
- 应用名称为“激励便签”，管理窗口标题为“我的激励语录”。
- 应用完全离线，不添加第三方依赖、账号、网络请求或云同步。
- 支持零句、一句或多句今日语录；选择不会在零点自动清空。
- 管理窗口使用 Apple 原生系统字体、动态颜色、系统蓝、分段选择器和分组列表。
- 桌面便签默认不遮挡普通应用窗口，并提供“始终置顶”设置。
- 数据保存在 Application Support，以临时文件替换方式原子写入。
- 所有交互控件必须提供 VoiceOver 标签，并支持键盘操作。

---

## Planned File Structure

```text
Package.swift
Sources/MotivationNote/
  App/
    AppDelegate.swift                 # AppKit 生命周期、菜单与窗口装配
    MotivationNoteMain.swift          # 可执行程序入口
  Models/
    AppData.swift                     # 持久化根模型与安全默认值
    PaperAppearance.swift             # 颜色、纹理与窗口位置模型
    Quote.swift                       # 语录实体
  Persistence/
    AppDataStore.swift                # 存储接口
    JSONLocalStore.swift              # JSON 原子保存、损坏文件备份
  State/
    AppModel.swift                    # 唯一业务状态与用户操作
  Views/
    Components/
      PaperBackground.swift           # 颜色和四种纸张纹理
    Desktop/
      DesktopNoteView.swift           # 桌面便签内容与空状态
    Manager/
      AppearanceSettingsView.swift    # 纸张外观与置顶设置
      ManagerView.swift               # 标题栏内容、分段页面与新增浮层
      QuoteEditorSheet.swift          # 新增/编辑语录
      QuoteLibraryView.swift          # 全部语录与删除确认
      TodaySelectionView.swift        # 每日多选与排序
  Windows/
    DesktopNoteWindowController.swift # 无边框便签窗口和桌面层级
    ManagerWindowController.swift     # 标准管理窗口
Tests/MotivationNoteTests/
  AppDataTests.swift
  AppModelTests.swift
  JSONLocalStoreTests.swift
  PaperAppearanceTests.swift
scripts/build-app.sh                  # 生成可双击的 .app
```

---

### Task 1: Swift Package 与领域模型

**Files:**
- Create: `Package.swift`
- Create: `Sources/MotivationNote/Models/Quote.swift`
- Create: `Sources/MotivationNote/Models/PaperAppearance.swift`
- Create: `Sources/MotivationNote/Models/AppData.swift`
- Create: `Sources/MotivationNote/App/MotivationNoteMain.swift`
- Create: `Tests/MotivationNoteTests/AppDataTests.swift`

**Interfaces:**
- Produces: `Quote`, `PaperColor`, `PaperTexture`, `WindowPosition`, `AppData.seeded`, `AppData.repairReferences()`
- Consumes: Swift 标准库、Foundation

- [ ] **Step 1: 写模型失败测试**

```swift
import XCTest
@testable import MotivationNote

final class AppDataTests: XCTestCase {
    func testSeededDataContainsThreeQuotesAndOneSelection() {
        let data = AppData.seeded
        XCTAssertEqual(data.quotes.count, 3)
        XCTAssertEqual(data.selectedQuoteIDs.count, 1)
        XCTAssertTrue(data.quotes.contains { $0.id == data.selectedQuoteIDs[0] })
        XCTAssertEqual(data.paperColor, .warmYellow)
        XCTAssertEqual(data.paperTexture, .lined)
    }

    func testRepairReferencesRemovesMissingAndDuplicateIDs() {
        let first = Quote(text: "第一句")
        let second = Quote(text: "第二句")
        let missing = UUID()
        var data = AppData(
            quotes: [first, second],
            selectedQuoteIDs: [second.id, missing, second.id, first.id]
        )
        data.repairReferences()
        XCTAssertEqual(data.selectedQuoteIDs, [second.id, first.id])
    }

    func testRoundTripCodablePreservesAppearanceAndPosition() throws {
        var data = AppData.seeded
        data.paperColor = .softPink
        data.paperTexture = .dotted
        data.windowPosition = WindowPosition(x: 120, y: 240)
        data.alwaysOnTop = true
        let decoded = try JSONDecoder().decode(
            AppData.self,
            from: JSONEncoder().encode(data)
        )
        XCTAssertEqual(decoded, data)
    }
}
```

- [ ] **Step 2: 运行测试并确认因模块与类型不存在而失败**

Run: `swift test --filter AppDataTests`

Expected: FAIL，错误包含 `no such module 'MotivationNote'` 或 `cannot find 'AppData' in scope`。

- [ ] **Step 3: 创建 Swift Package 与模型**

`Package.swift`：

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MotivationNote",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MotivationNote", targets: ["MotivationNote"])
    ],
    targets: [
        .executableTarget(
            name: "MotivationNote",
            path: "Sources/MotivationNote"
        ),
        .testTarget(
            name: "MotivationNoteTests",
            dependencies: ["MotivationNote"],
            path: "Tests/MotivationNoteTests"
        )
    ]
)
```

`Quote.swift`：

```swift
import Foundation

struct Quote: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var text: String
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        text: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

`PaperAppearance.swift`：

```swift
import Foundation

enum PaperColor: String, CaseIterable, Codable, Sendable, Hashable {
    case warmYellow, softPink, paleGreen, paleBlue, cream
}

enum PaperTexture: String, CaseIterable, Codable, Sendable, Hashable {
    case lined, dotted, grid, plain
}

struct WindowPosition: Codable, Equatable, Sendable {
    var x: Double
    var y: Double
}
```

`AppData.swift`：

```swift
import Foundation

struct AppData: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1

    var quotes: [Quote]
    var selectedQuoteIDs: [UUID]
    var paperColor: PaperColor
    var paperTexture: PaperTexture
    var windowPosition: WindowPosition?
    var alwaysOnTop: Bool
    var schemaVersion: Int

    init(
        quotes: [Quote] = [],
        selectedQuoteIDs: [UUID] = [],
        paperColor: PaperColor = .warmYellow,
        paperTexture: PaperTexture = .lined,
        windowPosition: WindowPosition? = nil,
        alwaysOnTop: Bool = false,
        schemaVersion: Int = currentSchemaVersion
    ) {
        self.quotes = quotes
        self.selectedQuoteIDs = selectedQuoteIDs
        self.paperColor = paperColor
        self.paperTexture = paperTexture
        self.windowPosition = windowPosition
        self.alwaysOnTop = alwaysOnTop
        self.schemaVersion = schemaVersion
    }

    static var seeded: AppData {
        let quotes = [
            Quote(text: "慢一点也没关系，重要的是我没有停下来。"),
            Quote(text: "先完成，再完美。"),
            Quote(text: "我已经走了很远，今天也继续向前一点。")
        ]
        return AppData(quotes: quotes, selectedQuoteIDs: [quotes[0].id])
    }

    mutating func repairReferences() {
        let validIDs = Set(quotes.map(\.id))
        var seen = Set<UUID>()
        selectedQuoteIDs = selectedQuoteIDs.filter {
            validIDs.contains($0) && seen.insert($0).inserted
        }
    }
}
```

在 `MotivationNoteMain.swift` 放入可供早期测试链接的最小入口，Task 6 再替换成正式生命周期：

```swift
@main
enum MotivationNoteMain {
    static func main() {}
}
```

- [ ] **Step 4: 运行模型测试**

Run: `swift test --filter AppDataTests`

Expected: PASS，3 tests executed。

- [ ] **Step 5: 提交领域模型**

```bash
git add Package.swift Sources/MotivationNote/Models Sources/MotivationNote/App/MotivationNoteMain.swift Tests/MotivationNoteTests/AppDataTests.swift
git commit -m "feat: add motivational note data models"
```

---

### Task 2: 原子 JSON 持久化与损坏恢复

**Files:**
- Create: `Sources/MotivationNote/Persistence/AppDataStore.swift`
- Create: `Sources/MotivationNote/Persistence/JSONLocalStore.swift`
- Create: `Tests/MotivationNoteTests/JSONLocalStoreTests.swift`

**Interfaces:**
- Consumes: `AppData`
- Produces: `protocol AppDataStore`, `JSONLocalStore.init(fileURL:fileManager:)`, `load()`, `save(_:)`, `StoreLoadError.corruptData(backupURL:)`

- [ ] **Step 1: 写持久化失败测试**

```swift
import Foundation
import XCTest
@testable import MotivationNote

final class JSONLocalStoreTests: XCTestCase {
    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    func testMissingFileLoadsNil() throws {
        let file = try temporaryDirectory().appendingPathComponent("data.json")
        XCTAssertNil(try JSONLocalStore(fileURL: file).load())
    }

    func testSaveThenLoadRoundTripsData() throws {
        let file = try temporaryDirectory().appendingPathComponent("data.json")
        let store = JSONLocalStore(fileURL: file)
        let expected = AppData.seeded
        try store.save(expected)
        XCTAssertEqual(try store.load(), expected)
    }

    func testCorruptFileIsBackedUpAndReported() throws {
        let file = try temporaryDirectory().appendingPathComponent("data.json")
        try Data("not-json".utf8).write(to: file)
        let store = JSONLocalStore(fileURL: file)

        XCTAssertThrowsError(try store.load()) { error in
            guard case let StoreLoadError.corruptData(backupURL) = error else {
                return XCTFail("Expected corruptData, got \(error)")
            }
            XCTAssertTrue(FileManager.default.fileExists(atPath: backupURL.path))
        }
    }
}
```

- [ ] **Step 2: 运行测试并确认存储类型不存在**

Run: `swift test --filter JSONLocalStoreTests`

Expected: FAIL，错误包含 `cannot find 'JSONLocalStore' in scope`。

- [ ] **Step 3: 实现存储接口与 JSON 文件存储**

`AppDataStore.swift`：

```swift
import Foundation

protocol AppDataStore: Sendable {
    func load() throws -> AppData?
    func save(_ data: AppData) throws
}

enum StoreLoadError: Error, Equatable {
    case corruptData(backupURL: URL)
}
```

`JSONLocalStore.swift` 的实现要求：

```swift
import Foundation

struct JSONLocalStore: AppDataStore {
    let fileURL: URL
    let fileManager: FileManager

    init(fileURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let base = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]
            self.fileURL = base
                .appendingPathComponent("MotivationNote", isDirectory: true)
                .appendingPathComponent("data.json")
        }
    }

    func load() throws -> AppData? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let bytes = try Data(contentsOf: fileURL)
            var decoded = try JSONDecoder().decode(AppData.self, from: bytes)
            decoded.repairReferences()
            return decoded
        } catch {
            let backupURL = fileURL
                .deletingPathExtension()
                .appendingPathExtension("corrupt-\(Int(Date.now.timeIntervalSince1970)).json")
            try? fileManager.copyItem(at: fileURL, to: backupURL)
            throw StoreLoadError.corruptData(backupURL: backupURL)
        }
    }

    func save(_ data: AppData) throws {
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let encoded = try JSONEncoder().encode(data)
        let temporary = directory.appendingPathComponent(
            ".\(UUID().uuidString).tmp"
        )
        try encoded.write(to: temporary, options: .atomic)
        if fileManager.fileExists(atPath: fileURL.path) {
            _ = try fileManager.replaceItemAt(fileURL, withItemAt: temporary)
        } else {
            try fileManager.moveItem(at: temporary, to: fileURL)
        }
    }
}
```

- [ ] **Step 4: 运行持久化测试与完整测试**

Run: `swift test`

Expected: PASS，6 tests executed。

- [ ] **Step 5: 提交持久化实现**

```bash
git add Sources/MotivationNote/Persistence Tests/MotivationNoteTests/JSONLocalStoreTests.swift
git commit -m "feat: persist note data atomically"
```

---

### Task 3: AppModel 语录库、每日多选与排序

**Files:**
- Create: `Sources/MotivationNote/State/AppModel.swift`
- Create: `Tests/MotivationNoteTests/AppModelTests.swift`

**Interfaces:**
- Consumes: `AppData`, `Quote`, `AppDataStore`
- Produces: `@MainActor final class AppModel: ObservableObject`
- Produces methods: `addQuote(text:) -> Bool`, `updateQuote(id:text:) -> Bool`, `deleteQuote(id:)`, `setSelected(_:quoteID:)`, `moveSelected(fromOffsets:toOffset:)`, `setPaperColor(_:)`, `setPaperTexture(_:)`, `setAlwaysOnTop(_:)`, `setWindowPosition(_:)`
- Produces values: `data`, `selectedQuotes`, `unselectedQuotes`, `recoveryMessage`

- [ ] **Step 1: 写业务行为失败测试**

```swift
import XCTest
@testable import MotivationNote

private final class MemoryStore: AppDataStore, @unchecked Sendable {
    var stored: AppData?
    var saveCount = 0
    var loadError: Error?

    init(stored: AppData? = nil) { self.stored = stored }

    func load() throws -> AppData? {
        if let loadError { throw loadError }
        return stored
    }

    func save(_ data: AppData) throws {
        stored = data
        saveCount += 1
    }
}

@MainActor
final class AppModelTests: XCTestCase {
    func testEmptyTextCannotBeAdded() {
        let model = AppModel(store: MemoryStore(stored: .seeded))
        XCTAssertFalse(model.addQuote(text: "   \n"))
    }

    func testAddUpdateAndDeleteQuotePersistEveryMutation() {
        let store = MemoryStore(stored: .seeded)
        let model = AppModel(store: store)
        XCTAssertTrue(model.addQuote(text: "  行动会带来状态。  "))
        let added = model.data.quotes.last!
        XCTAssertEqual(added.text, "行动会带来状态。")
        XCTAssertTrue(model.updateQuote(id: added.id, text: "先行动。"))
        model.setSelected(true, quoteID: added.id)
        model.deleteQuote(id: added.id)
        XCTAssertFalse(model.data.selectedQuoteIDs.contains(added.id))
        XCTAssertEqual(store.saveCount, 4)
    }

    func testSelectedQuotesKeepExplicitOrderAndCanBeEmpty() {
        let store = MemoryStore(stored: .seeded)
        let model = AppModel(store: store)
        let firstID = model.data.selectedQuoteIDs[0]
        let secondID = model.data.quotes[1].id
        model.setSelected(true, quoteID: secondID)
        XCTAssertEqual(model.selectedQuotes.map(\.id), [firstID, secondID])
        model.moveSelected(fromOffsets: IndexSet(integer: 1), toOffset: 0)
        XCTAssertEqual(model.selectedQuotes.map(\.id), [secondID, firstID])
        model.setSelected(false, quoteID: secondID)
        model.setSelected(false, quoteID: firstID)
        XCTAssertTrue(model.selectedQuotes.isEmpty)
    }

    func testAppearanceAndWindowSettingsPersist() {
        let store = MemoryStore(stored: .seeded)
        let model = AppModel(store: store)
        model.setPaperColor(.paleBlue)
        model.setPaperTexture(.grid)
        model.setAlwaysOnTop(true)
        model.setWindowPosition(WindowPosition(x: 44, y: 88))
        XCTAssertEqual(store.stored?.paperColor, .paleBlue)
        XCTAssertEqual(store.stored?.paperTexture, .grid)
        XCTAssertEqual(store.stored?.windowPosition, WindowPosition(x: 44, y: 88))
        XCTAssertEqual(store.stored?.alwaysOnTop, true)
    }
}
```

- [ ] **Step 2: 运行测试并确认 AppModel 不存在**

Run: `swift test --filter AppModelTests`

Expected: FAIL，错误包含 `cannot find 'AppModel' in scope`。

- [ ] **Step 3: 实现主状态模型**

`AppModel.swift` 必须使用以下公开结构，并在每次成功修改后调用 `persist()`：

```swift
import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var data: AppData
    @Published private(set) var recoveryMessage: String? = nil
    private let store: any AppDataStore

    init(store: any AppDataStore) {
        self.store = store
        var needsInitialSave = false
        do {
            if let loaded = try store.load() {
                self.data = loaded
            } else {
                self.data = .seeded
                needsInitialSave = true
            }
        } catch let StoreLoadError.corruptData(backupURL) {
            self.data = .seeded
            self.recoveryMessage = "原数据无法读取，已备份到 \(backupURL.lastPathComponent)，并恢复了安全默认内容。"
            needsInitialSave = true
        } catch {
            self.data = .seeded
            self.recoveryMessage = "数据暂时无法读取，已恢复安全默认内容。"
            needsInitialSave = true
        }
        if needsInitialSave { persist() }
    }

    var selectedQuotes: [Quote] {
        let byID = Dictionary(uniqueKeysWithValues: data.quotes.map { ($0.id, $0) })
        return data.selectedQuoteIDs.compactMap { byID[$0] }
    }

    var unselectedQuotes: [Quote] {
        let selected = Set(data.selectedQuoteIDs)
        return data.quotes.filter { !selected.contains($0.id) }
    }

    @discardableResult
    func addQuote(text: String) -> Bool {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return false }
        data.quotes.append(Quote(text: clean))
        persist()
        return true
    }

    @discardableResult
    func updateQuote(id: UUID, text: String) -> Bool {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty,
              let index = data.quotes.firstIndex(where: { $0.id == id })
        else { return false }
        data.quotes[index].text = clean
        data.quotes[index].updatedAt = .now
        persist()
        return true
    }

    func deleteQuote(id: UUID) {
        data.quotes.removeAll { $0.id == id }
        data.selectedQuoteIDs.removeAll { $0 == id }
        persist()
    }

    func setSelected(_ selected: Bool, quoteID: UUID) {
        guard data.quotes.contains(where: { $0.id == quoteID }) else { return }
        data.selectedQuoteIDs.removeAll { $0 == quoteID }
        if selected { data.selectedQuoteIDs.append(quoteID) }
        persist()
    }

    func moveSelected(fromOffsets: IndexSet, toOffset: Int) {
        data.selectedQuoteIDs.move(fromOffsets: fromOffsets, toOffset: toOffset)
        persist()
    }

    func setPaperColor(_ value: PaperColor) {
        data.paperColor = value
        persist()
    }

    func setPaperTexture(_ value: PaperTexture) {
        data.paperTexture = value
        persist()
    }

    func setAlwaysOnTop(_ value: Bool) {
        data.alwaysOnTop = value
        persist()
    }

    func setWindowPosition(_ value: WindowPosition) {
        data.windowPosition = value
        persist()
    }

    func dismissRecoveryMessage() {
        recoveryMessage = nil
    }

    private func persist() {
        do {
            try store.save(data)
        } catch {
            recoveryMessage = "保存失败，请检查磁盘空间后重试。"
        }
    }
}
```

- [ ] **Step 4: 运行业务测试**

Run: `swift test --filter AppModelTests`

Expected: PASS，4 tests executed。

- [ ] **Step 5: 提交状态层**

```bash
git add Sources/MotivationNote/State Tests/MotivationNoteTests/AppModelTests.swift
git commit -m "feat: manage quote library and daily selection"
```

---

### Task 4: 纸张外观组件与桌面便签

**Files:**
- Create: `Sources/MotivationNote/Views/Components/PaperBackground.swift`
- Create: `Sources/MotivationNote/Views/Desktop/DesktopNoteView.swift`
- Create: `Tests/MotivationNoteTests/PaperAppearanceTests.swift`

**Interfaces:**
- Consumes: `PaperColor`, `PaperTexture`, `AppModel.selectedQuotes`
- Produces: `PaperColor.backgroundColor`, `PaperColor.textColor`, `PaperBackground`, `DesktopNoteView(model:openManager:onHeightChange:)`

- [ ] **Step 1: 写纸张配置失败测试**

```swift
import XCTest
@testable import MotivationNote

final class PaperAppearanceTests: XCTestCase {
    func testAllColorAndTextureChoicesArePresent() {
        XCTAssertEqual(PaperColor.allCases.count, 5)
        XCTAssertEqual(PaperTexture.allCases.count, 4)
    }

    func testEveryPaperColorHasChineseDisplayName() {
        XCTAssertEqual(Set(PaperColor.allCases.map(\.displayName)).count, 5)
        XCTAssertFalse(PaperColor.allCases.contains { $0.displayName.isEmpty })
    }
}
```

- [ ] **Step 2: 运行测试并确认 `displayName` 不存在**

Run: `swift test --filter PaperAppearanceTests`

Expected: FAIL，错误包含 `value of type 'PaperColor' has no member 'displayName'`。

- [ ] **Step 3: 添加外观映射与可复用纸张背景**

在 `PaperAppearance.swift` 增加：

```swift
import SwiftUI

extension PaperColor {
    var displayName: String {
        switch self {
        case .warmYellow: "暖黄"
        case .softPink: "柔粉"
        case .paleGreen: "浅绿"
        case .paleBlue: "浅蓝"
        case .cream: "米白"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .warmYellow: Color(red: 1.00, green: 0.94, blue: 0.72)
        case .softPink: Color(red: 1.00, green: 0.83, blue: 0.84)
        case .paleGreen: Color(red: 0.82, green: 0.92, blue: 0.84)
        case .paleBlue: Color(red: 0.84, green: 0.89, blue: 0.98)
        case .cream: Color(red: 0.95, green: 0.94, blue: 0.91)
        }
    }

    var textColor: Color { Color(red: 0.25, green: 0.22, blue: 0.15) }
}

extension PaperTexture {
    var displayName: String {
        switch self {
        case .lined: "横线"
        case .dotted: "圆点"
        case .grid: "方格"
        case .plain: "纯色"
        }
    }
}
```

`PaperBackground.swift`：

```swift
import SwiftUI

struct PaperBackground: View {
    let color: PaperColor
    let texture: PaperTexture
    var cornerRadius: CGFloat = 18

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(color.backgroundColor)
            .overlay {
                Canvas { context, size in
                    let ink = color.textColor.opacity(0.10)
                    switch texture {
                    case .lined:
                        for y in stride(from: 27.0, through: size.height, by: 27.0) {
                            var path = Path()
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                            context.stroke(path, with: .color(ink), lineWidth: 1)
                        }
                    case .dotted:
                        for x in stride(from: 7.0, through: size.width, by: 14.0) {
                            for y in stride(from: 7.0, through: size.height, by: 14.0) {
                                context.fill(
                                    Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                                    with: .color(ink)
                                )
                            }
                        }
                    case .grid:
                        for x in stride(from: 18.0, through: size.width, by: 18.0) {
                            var path = Path()
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: size.height))
                            context.stroke(path, with: .color(ink), lineWidth: 1)
                        }
                        for y in stride(from: 18.0, through: size.height, by: 18.0) {
                            var path = Path()
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                            context.stroke(path, with: .color(ink), lineWidth: 1)
                        }
                    case .plain:
                        break
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .shadow(color: .black.opacity(0.22), radius: 24, y: 14)
    }
}
```

- [ ] **Step 4: 实现桌面便签视图**

`DesktopNoteView` 使用 280 点固定宽度和动态高度：

```swift
struct DesktopNoteView: View {
    @ObservedObject var model: AppModel
    let openManager: () -> Void
    let onHeightChange: (CGFloat) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    Text(context.date, format: .dateTime.month().day())
                        .font(.caption2.weight(.semibold))
                        .textCase(.uppercase)
                        .accessibilityLabel("今天")
                }
                Spacer()
                Button(action: openManager) {
                    Image(systemName: "ellipsis")
                        .frame(width: 28, height: 28)
                        .background(.black.opacity(0.07), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("打开语录管理")
            }
            .foregroundStyle(model.data.paperColor.textColor.opacity(0.62))

            if model.selectedQuotes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("今天想用哪句话陪你？")
                        .font(.headline)
                    Button("选择今日语录", action: openManager)
                        .buttonStyle(.link)
                }
                .padding(.vertical, 26)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(model.selectedQuotes.enumerated()), id: \.element.id) { index, quote in
                            HStack(alignment: .top, spacing: 9) {
                                Image(systemName: "checkmark")
                                    .font(.caption2.bold())
                                    .padding(.top, 5)
                                Text(quote.text)
                                    .font(.system(size: 16, weight: .semibold))
                                    .lineSpacing(7)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 14)
                            if index < model.selectedQuotes.count - 1 {
                                Divider().opacity(0.25)
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(22)
        .frame(width: 280)
        .frame(maxHeight: 720)
        .foregroundStyle(model.data.paperColor.textColor)
        .background {
            PaperBackground(
                color: model.data.paperColor,
                texture: model.data.paperTexture
            )
        }
        .fixedSize(horizontal: false, vertical: true)
        .rotationEffect(.degrees(-0.7))
        .padding(12)
        .frame(width: 304)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { onHeightChange(proxy.size.height) }
                    .onChange(of: proxy.size.height) { _, value in
                        onHeightChange(value)
                    }
            }
        )
        .accessibilityElement(children: .contain)
    }
}
```

- [ ] **Step 5: 运行测试与编译检查**

Run: `swift test`

Expected: PASS，所有测试通过，SwiftUI 视图成功编译。

- [ ] **Step 6: 提交便签外观**

```bash
git add Sources/MotivationNote/Models/PaperAppearance.swift Sources/MotivationNote/Views Tests/MotivationNoteTests/PaperAppearanceTests.swift
git commit -m "feat: render customizable desktop note"
```

---

### Task 5: Apple 原生管理窗口内容

**Files:**
- Create: `Sources/MotivationNote/Views/Manager/ManagerView.swift`
- Create: `Sources/MotivationNote/Views/Manager/TodaySelectionView.swift`
- Create: `Sources/MotivationNote/Views/Manager/QuoteLibraryView.swift`
- Create: `Sources/MotivationNote/Views/Manager/AppearanceSettingsView.swift`
- Create: `Sources/MotivationNote/Views/Manager/QuoteEditorSheet.swift`

**Interfaces:**
- Consumes: Task 3 的全部 `AppModel` 操作和 Task 4 的 `PaperBackground`
- Produces: `ManagerView(model:)`，其余视图仅在 Manager 模块内部使用

- [ ] **Step 1: 实现管理窗口骨架和新增浮层**

`ManagerView`：

```swift
import SwiftUI

struct ManagerView: View {
    enum Section: String, CaseIterable, Identifiable, Hashable {
        case today = "今日展示"
        case library = "全部语录"
        case appearance = "纸张外观"
        var id: Self { self }
    }

    @ObservedObject var model: AppModel
    @State private var section: Section = .today
    @State private var showingAddSheet = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("我的激励语录")
                    .font(.largeTitle.bold())
                Spacer()
                Button {
                    showingAddSheet = true
                } label: {
                    Label("新增语录", systemImage: "plus.circle.fill")
                }
                .keyboardShortcut("n", modifiers: .command)
                .accessibilityLabel("新增语录")
            }

            Picker("页面", selection: $section) {
                ForEach(Section.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            Group {
                switch section {
                case .today: TodaySelectionView(model: model)
                case .library: QuoteLibraryView(model: model)
                case .appearance: AppearanceSettingsView(model: model)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(20)
        .frame(minWidth: 680, minHeight: 560)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showingAddSheet) {
            QuoteEditorSheet(title: "新增语录", initialText: "") {
                model.addQuote(text: $0)
            }
        }
        .alert("数据恢复提示", isPresented: Binding(
            get: { model.recoveryMessage != nil },
            set: { if !$0 { model.dismissRecoveryMessage() } }
        )) {
            Button("知道了") { model.dismissRecoveryMessage() }
        } message: {
            Text(model.recoveryMessage ?? "")
        }
    }
}
```

`QuoteEditorSheet.swift`：

```swift
import SwiftUI

struct QuoteEditorSheet: View {
    let title: String
    let initialText: String
    let onSave: (String) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var text: String

    init(title: String, initialText: String, onSave: @escaping (String) -> Bool) {
        self.title = title
        self.initialText = initialText
        self.onSave = onSave
        _text = State(initialValue: initialText)
    }

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.title2.bold())
            TextEditor(text: $text)
                .font(.body)
                .frame(minWidth: 440, minHeight: 160)
                .accessibilityLabel("语录内容")
            if text.count > 240 {
                Text("这句话比较长，桌面便签会相应变高。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("保存") {
                    if onSave(trimmed) { dismiss() }
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(trimmed.isEmpty)
            }
        }
        .padding(20)
    }
}
```

- [ ] **Step 2: 实现“今日展示”多选与排序**

`TodaySelectionView.swift`：

```swift
import SwiftUI

struct TodaySelectionView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        if model.data.quotes.isEmpty {
            ContentUnavailableView(
                "还没有语录",
                systemImage: "quote.bubble",
                description: Text("先新增一句激励自己的话。")
            )
        } else {
            List {
                Section("已选 \(model.selectedQuotes.count) 句") {
                    if model.selectedQuotes.isEmpty {
                        Text("今天暂时没有选择语录")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(model.selectedQuotes) { quote in
                        selectionRow(quote, selected: true)
                    }
                    .onMove(perform: model.moveSelected)
                }

                Section("语录库") {
                    ForEach(model.unselectedQuotes) { quote in
                        selectionRow(quote, selected: false)
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    private func selectionRow(_ quote: Quote, selected: Bool) -> some View {
        Button {
            model.setSelected(!selected, quoteID: quote.id)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Color.accentColor : .secondary)
                Text(quote.text)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if selected {
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(selected ? "移出今日展示" : "加入今日展示")：\(quote.text)"
        )
    }
}
```

- [ ] **Step 3: 实现“全部语录”编辑与删除**

`QuoteLibraryView.swift`：

```swift
import SwiftUI

struct QuoteLibraryView: View {
    @ObservedObject var model: AppModel
    @State private var editingQuote: Quote?
    @State private var deleteCandidate: Quote?

    var body: some View {
        Group {
            if model.data.quotes.isEmpty {
                ContentUnavailableView(
                    "还没有收藏的语录",
                    systemImage: "quote.bubble",
                    description: Text("点击右上角新增第一句。")
                )
            } else {
                List(model.data.quotes) { quote in
                    HStack(alignment: .top, spacing: 12) {
                        Text(quote.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onTapGesture(count: 2) { editingQuote = quote }
                        Button {
                            editingQuote = quote
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("编辑语录：\(quote.text)")
                        Button(role: .destructive) {
                            deleteCandidate = quote
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("删除语录：\(quote.text)")
                    }
                    .padding(.vertical, 7)
                }
                .listStyle(.inset)
            }
        }
        .sheet(item: $editingQuote) { quote in
            QuoteEditorSheet(
                title: "编辑语录",
                initialText: quote.text,
                onSave: { model.updateQuote(id: quote.id, text: $0) }
            )
        }
        .alert(
            "确定删除这句语录吗？",
            isPresented: Binding(
                get: { deleteCandidate != nil },
                set: { if !$0 { deleteCandidate = nil } }
            ),
            presenting: deleteCandidate
        ) { quote in
            Button("删除", role: .destructive) {
                model.deleteQuote(id: quote.id)
                deleteCandidate = nil
            }
            Button("取消", role: .cancel) { deleteCandidate = nil }
        } message: { quote in
            Text(quote.text)
        }
    }
}
```

- [ ] **Step 4: 实现纸张外观与实时预览**

`AppearanceSettingsView.swift`：

```swift
import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                preview
                GroupBox("纸张颜色") {
                    HStack(spacing: 16) {
                        ForEach(PaperColor.allCases, id: \.self) { choice in
                            Button {
                                model.setPaperColor(choice)
                            } label: {
                                ZStack {
                                    Circle().fill(choice.backgroundColor)
                                    if choice == model.data.paperColor {
                                        Circle()
                                            .stroke(Color.accentColor, lineWidth: 3)
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                    }
                                }
                                .frame(width: 42, height: 42)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("纸张颜色：\(choice.displayName)")
                            .accessibilityValue(
                                choice == model.data.paperColor ? "已选择" : "未选择"
                            )
                        }
                    }
                    .padding(8)
                }

                GroupBox("纸张纹理") {
                    HStack(spacing: 14) {
                        ForEach(PaperTexture.allCases, id: \.self) { choice in
                            Button {
                                model.setPaperTexture(choice)
                            } label: {
                                PaperBackground(
                                    color: model.data.paperColor,
                                    texture: choice,
                                    cornerRadius: 8
                                )
                                .frame(width: 64, height: 48)
                                .overlay {
                                    if choice == model.data.paperTexture {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.accentColor, lineWidth: 3)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("纸张纹理：\(choice.displayName)")
                            .accessibilityValue(
                                choice == model.data.paperTexture ? "已选择" : "未选择"
                            )
                        }
                    }
                    .padding(8)
                }

                Toggle(
                    "始终置顶",
                    isOn: Binding(
                        get: { model.data.alwaysOnTop },
                        set: model.setAlwaysOnTop
                    )
                )
                .toggleStyle(.switch)
                .accessibilityHint("开启后便签会显示在普通应用窗口上方")
            }
            .padding()
        }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 10) {
            let quotes = Array(model.selectedQuotes.prefix(2))
            if quotes.isEmpty {
                Text("今天想用哪句话陪你？")
                    .font(.headline)
            } else {
                ForEach(quotes) { quote in
                    Text(quote.text)
                        .font(.headline)
                }
            }
        }
        .padding(20)
        .frame(width: 220, height: 260, alignment: .topLeading)
        .foregroundStyle(model.data.paperColor.textColor)
        .background {
            PaperBackground(
                color: model.data.paperColor,
                texture: model.data.paperTexture
            )
        }
        .accessibilityLabel("纸张外观预览")
    }
}
```

- [ ] **Step 5: 运行全量测试与应用编译**

Run: `swift test && swift build`

Expected: 两个命令均成功；所有测试 PASS。

- [ ] **Step 6: 提交管理界面**

```bash
git add Sources/MotivationNote/Views/Manager
git commit -m "feat: add native quote manager"
```

---

### Task 6: AppKit 桌面窗口、管理窗口与应用生命周期

**Files:**
- Create: `Sources/MotivationNote/Windows/DesktopNoteWindowController.swift`
- Create: `Sources/MotivationNote/Windows/ManagerWindowController.swift`
- Create: `Sources/MotivationNote/App/AppDelegate.swift`
- Modify: `Sources/MotivationNote/App/MotivationNoteMain.swift`

**Interfaces:**
- Consumes: `AppModel`, `DesktopNoteView`, `ManagerView`, `WindowPosition`
- Produces: 可运行的 `MotivationNote` executable

- [ ] **Step 1: 实现标准管理窗口**

`ManagerWindowController.swift`：

```swift
import AppKit
import SwiftUI

@MainActor
final class ManagerWindowController: NSWindowController {
    init(model: AppModel) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "我的激励语录"
        window.minSize = NSSize(width: 680, height: 560)
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: ManagerView(model: model))
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("ManagerWindowController only supports programmatic creation")
    }

    func show() {
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
```

- [ ] **Step 2: 实现无边框桌面便签窗口**

`DesktopNoteWindowController.swift`：

```swift
import AppKit
import Combine
import CoreGraphics
import SwiftUI

@MainActor
final class DesktopNoteWindowController: NSWindowController, NSWindowDelegate {
    private let model: AppModel
    private var cancellables = Set<AnyCancellable>()
    private let noteWidth: CGFloat = 304

    init(model: AppModel, openManager: @escaping () -> Void) {
        self.model = model
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 304, height: 360),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        super.init(window: panel)

        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [
            .canJoinAllSpaces, .stationary, .fullScreenAuxiliary
        ]
        panel.delegate = self
        panel.contentView = NSHostingView(
            rootView: DesktopNoteView(
                model: model,
                openManager: openManager,
                onHeightChange: { [weak self] height in self?.resize(to: height) }
            )
        )

        updateLevel(alwaysOnTop: model.data.alwaysOnTop)
        restorePosition()

        model.$data
            .map(\.alwaysOnTop)
            .removeDuplicates()
            .sink { [weak self] in self?.updateLevel(alwaysOnTop: $0) }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("DesktopNoteWindowController only supports programmatic creation")
    }

    private func updateLevel(alwaysOnTop: Bool) {
        window?.level = alwaysOnTop
            ? .floating
            : NSWindow.Level(
                rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) - 1
            )
    }

    private func restorePosition() {
        guard let window else { return }
        let visible = NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let proposed = model.data.windowPosition.map {
            NSPoint(x: $0.x, y: $0.y)
        } ?? NSPoint(
            x: visible.maxX - noteWidth - 36,
            y: visible.maxY - window.frame.height - 36
        )
        window.setFrameOrigin(clamped(proposed, windowSize: window.frame.size))
    }

    private func clamped(_ origin: NSPoint, windowSize: NSSize) -> NSPoint {
        let screen = NSScreen.screens.first {
            $0.visibleFrame.contains(origin)
        } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return origin }
        return NSPoint(
            x: min(max(origin.x, visible.minX), visible.maxX - windowSize.width),
            y: min(max(origin.y, visible.minY), visible.maxY - windowSize.height)
        )
    }

    private func resize(to requestedHeight: CGFloat) {
        guard let window else { return }
        let visibleHeight = (window.screen ?? NSScreen.main)?.visibleFrame.height ?? 900
        let height = min(max(requestedHeight, 180), visibleHeight - 40)
        var frame = window.frame
        let top = frame.maxY
        frame.size = NSSize(width: noteWidth, height: height)
        frame.origin.y = top - height
        frame.origin = clamped(frame.origin, windowSize: frame.size)
        let shouldAnimate = !NSWorkspace.shared
            .accessibilityDisplayShouldReduceMotion
        window.setFrame(frame, display: true, animate: shouldAnimate)
    }

    func windowDidMove(_ notification: Notification) {
        guard let origin = window?.frame.origin else { return }
        model.setWindowPosition(WindowPosition(x: origin.x, y: origin.y))
    }
}
```

- [ ] **Step 3: 实现 AppKit 生命周期与菜单**

`AppDelegate`：

```swift
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel(store: JSONLocalStore())
    private var desktopController: DesktopNoteWindowController!
    private var managerController: ManagerWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        managerController = ManagerWindowController(model: model)
        desktopController = DesktopNoteWindowController(
            model: model,
            openManager: { [weak self] in self?.managerController.show() }
        )
        installMainMenu()
        desktopController.showWindow(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        false
    }

    @objc private func showManager() {
        managerController.show()
    }

    @objc private func quit() {
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
```

`MotivationNoteMain.swift`：

```swift
import AppKit

@main
enum MotivationNoteMain {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
        _ = delegate
    }
}
```

- [ ] **Step 4: 编译并手工检查窗口行为**

Run: `swift build && swift run MotivationNote`

Expected:

- 桌面出现暖黄色便签，管理窗口不会自动遮挡桌面。
- 拖动便签后退出并重启，位置得到恢复。
- 点击“•••”打开标准 macOS 管理窗口。
- 选择多句后便签自动增高。
- 开启“始终置顶”后便签出现在普通窗口上方，关闭后回到桌面层。
- Command+Q 正常退出。

- [ ] **Step 5: 提交应用窗口与生命周期**

```bash
git add Sources/MotivationNote/App Sources/MotivationNote/Windows
git commit -m "feat: run note as native macOS desktop app"
```

---

### Task 7: 打包、可访问性与最终验收

**Files:**
- Create: `scripts/build-app.sh`
- Modify: `.gitignore`
- Create: `README.md`

**Interfaces:**
- Consumes: `swift build -c release` 生成的可执行文件
- Produces: `dist/激励便签.app`

- [ ] **Step 1: 创建 `.app` 打包脚本**

`scripts/build-app.sh`：

```bash
#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$PROJECT_DIR/dist/激励便签.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

cd "$PROJECT_DIR"
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
cp "$PROJECT_DIR/.build/release/MotivationNote" "$MACOS_DIR/MotivationNote"

plutil -create xml1 "$CONTENTS_DIR/Info.plist"
plutil -insert CFBundleName -string "激励便签" "$CONTENTS_DIR/Info.plist"
plutil -insert CFBundleDisplayName -string "激励便签" "$CONTENTS_DIR/Info.plist"
plutil -insert CFBundleIdentifier -string "local.codex.MotivationNote" "$CONTENTS_DIR/Info.plist"
plutil -insert CFBundleExecutable -string "MotivationNote" "$CONTENTS_DIR/Info.plist"
plutil -insert CFBundlePackageType -string "APPL" "$CONTENTS_DIR/Info.plist"
plutil -insert CFBundleShortVersionString -string "1.0.0" "$CONTENTS_DIR/Info.plist"
plutil -insert LSMinimumSystemVersion -string "14.0" "$CONTENTS_DIR/Info.plist"
plutil -insert NSHighResolutionCapable -bool true "$CONTENTS_DIR/Info.plist"

codesign --force --deep --sign - "$APP_DIR"
echo "$APP_DIR"
```

执行 `chmod +x scripts/build-app.sh`，并将 `dist/` 加入 `.gitignore`。

- [ ] **Step 2: 编写使用说明**

`README.md`：

````markdown
# 激励便签

一个完全离线的 macOS 桌面便签，用来收藏激励语录，并挑选今天想看到的一句或多句。

## 构建与启动

需要 macOS 14 或更高版本，以及 Apple Swift 6 工具链。

```bash
./scripts/build-app.sh
```

构建完成后，双击 `dist/激励便签.app`。

如果 macOS 提示无法验证开发者，请打开“系统设置 → 隐私与安全性”，找到对应提示并选择“仍要打开”。

## 使用

- 首次启动会显示三条示例语录，桌面便签默认展示第一条。
- 点击便签右上角的“•••”打开“我的激励语录”。
- 点击“新增语录”收藏一句话。
- 在“今日展示”中勾选任意数量的语录；拖动已选语录可以调整桌面顺序。
- 在“全部语录”中编辑或删除已经收藏的内容。
- 在“纸张外观”中组合颜色和纹理，并选择是否“始终置顶”。

数据保存在：

`~/Library/Application Support/MotivationNote/data.json`
````

- [ ] **Step 3: 运行自动化验收**

Run:

```bash
swift test
./scripts/build-app.sh
test -x "dist/激励便签.app/Contents/MacOS/MotivationNote"
plutil -lint "dist/激励便签.app/Contents/Info.plist"
codesign --verify --deep --strict "dist/激励便签.app"
```

Expected:

- 全部单元测试 PASS。
- `dist/激励便签.app` 存在并包含可执行文件。
- `Info.plist` 输出 `OK`。
- `codesign --verify` 退出码为 0。

- [ ] **Step 4: 手工完成验收清单**

依次验证：

1. 首次启动出现三条示例语录，桌面默认展示第一条。
2. 新增空内容时无法保存；新增、编辑、删除有效语录后重启数据不丢失。
3. 今日展示可以是零句、一句或多句；多句排序即时同步到便签。
4. 选择五种颜色和四种纹理的每种组合时，实时预览与桌面一致。
5. 拖动位置、纸张样式与“始终置顶”在重启后保持。
6. 浅色与深色模式下管理窗口文字和控件均可读。
7. 使用 Tab、Shift+Tab、Return、Escape、Command+N、Command+Q 完成主要操作。
8. VoiceOver 能读出新增、编辑、删除、勾选、颜色、纹理和设置按钮。
9. 将 `data.json` 替换为无效 JSON 后启动，应用创建损坏备份并展示恢复提示。

- [ ] **Step 5: 提交打包和文档**

```bash
git add scripts/build-app.sh .gitignore README.md
git commit -m "build: package motivational note app"
```

- [ ] **Step 6: 最终状态检查**

Run: `git status --short && git log --oneline -8`

Expected: 工作树干净；日志包含模型、持久化、状态、便签、管理窗口、应用窗口和打包提交。

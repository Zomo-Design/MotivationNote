import Foundation

private final class MemoryStore: AppDataStore {
    var stored: AppData?
    var saveCount = 0
    var loadError: Error?

    init(stored: AppData? = nil) {
        self.stored = stored
    }

    func load() throws -> AppData? {
        if let loadError {
            throw loadError
        }
        return stored
    }

    func save(_ data: AppData) throws {
        stored = data
        saveCount += 1
    }
}

@main
@MainActor
enum AppModelChecks {
    static func main() {
        runCheckSuite("AppModel", checks: [
            emptyTextCannotBeAdded,
            addUpdateAndDeletePersistEveryMutation,
            deletingAllQuotesLeavesSafeEmptyState,
            selectedQuotesKeepExplicitOrderAndCanBeEmpty,
            appearanceAndWindowSettingsPersist,
            corruptLoadUsesSeedAndReportsRecovery
        ])
    }

    private static func emptyTextCannotBeAdded() throws {
        let model = AppModel(store: MemoryStore(stored: .seeded))
        try expect(
            !model.addQuote(text: "   \n"),
            "Whitespace-only quote should not be added"
        )
    }

    private static func addUpdateAndDeletePersistEveryMutation() throws {
        let store = MemoryStore(stored: .seeded)
        let model = AppModel(store: store)

        try expect(
            model.addQuote(text: "  行动会带来状态。  "),
            "Valid quote should be added"
        )
        let added = try unwrap(model.data.quotes.last, "Added quote should exist")
        try expect(added.text == "行动会带来状态。", "Text should be trimmed")
        try expect(
            model.updateQuote(id: added.id, text: "先行动。"),
            "Valid update should succeed"
        )
        model.setSelected(true, quoteID: added.id)
        model.deleteQuote(id: added.id)

        try expect(
            !model.data.selectedQuoteIDs.contains(added.id),
            "Deleting a quote should remove its selection"
        )
        try expect(store.saveCount == 4, "Every successful mutation should persist")
    }

    private static func selectedQuotesKeepExplicitOrderAndCanBeEmpty() throws {
        let store = MemoryStore(stored: .seeded)
        let model = AppModel(store: store)
        let firstID = model.data.selectedQuoteIDs[0]
        let secondID = model.data.quotes[1].id

        model.setSelected(true, quoteID: secondID)
        try expect(
            model.selectedQuotes.map(\.id) == [firstID, secondID],
            "New selection should append"
        )
        model.moveSelected(
            fromOffsets: IndexSet(integer: 1),
            toOffset: 0
        )
        try expect(
            model.selectedQuotes.map(\.id) == [secondID, firstID],
            "Selection should move in explicit order"
        )
        model.setSelected(false, quoteID: secondID)
        model.setSelected(false, quoteID: firstID)
        try expect(model.selectedQuotes.isEmpty, "Selection may be empty")
    }

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

    private static func appearanceAndWindowSettingsPersist() throws {
        let store = MemoryStore(stored: .seeded)
        let model = AppModel(store: store)

        model.setPaperColor(.paleBlue)
        model.setPaperTexture(.grid)
        model.setAlwaysOnTop(true)
        model.setWindowPosition(WindowPosition(x: 44, y: 88))

        try expect(store.stored?.paperColor == .paleBlue, "Color should persist")
        try expect(store.stored?.paperTexture == .grid, "Texture should persist")
        try expect(
            store.stored?.windowPosition == WindowPosition(x: 44, y: 88),
            "Position should persist"
        )
        try expect(store.stored?.alwaysOnTop == true, "Pin state should persist")
    }

    private static func corruptLoadUsesSeedAndReportsRecovery() throws {
        let store = MemoryStore()
        store.loadError = StoreLoadError.corruptData(
            backupURL: URL(fileURLWithPath: "/tmp/data.corrupt.json")
        )

        let model = AppModel(store: store)

        try expect(model.data.quotes.count == 3, "Recovery should use seeded data")
        try expect(model.recoveryMessage != nil, "Recovery should be explained")
        try expect(store.saveCount == 1, "Recovered seed should be saved")
    }
}

private func unwrap<T>(_ value: T?, _ message: String) throws -> T {
    guard let value else {
        throw CheckFailure(description: message)
    }
    return value
}

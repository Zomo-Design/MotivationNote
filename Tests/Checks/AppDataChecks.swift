import Foundation

@main
enum AppDataChecks {
    static func main() {
        runCheckSuite("AppData", checks: [
            seededDataContainsThreeQuotesAndOneSelection,
            repairReferencesRemovesMissingAndDuplicateIDs,
            roundTripCodablePreservesAppearanceAndPosition
        ])
    }

    private static func seededDataContainsThreeQuotesAndOneSelection() throws {
        let data = AppData.seeded
        try expect(data.quotes.count == 3, "Seed should contain three quotes")
        try expect(
            data.selectedQuoteIDs.count == 1,
            "Seed should contain one selected quote"
        )
        try expect(
            data.quotes.contains { $0.id == data.selectedQuoteIDs[0] },
            "Selected quote must exist in library"
        )
        try expect(data.paperColor == .warmYellow, "Default color should be warm yellow")
        try expect(data.paperTexture == .lined, "Default texture should be lined")
        try expect(data.alwaysOnTop, "Desktop note should be pinned by default")
    }

    private static func repairReferencesRemovesMissingAndDuplicateIDs() throws {
        let first = Quote(text: "第一句")
        let second = Quote(text: "第二句")
        let missing = UUID()
        var data = AppData(
            quotes: [first, second],
            selectedQuoteIDs: [second.id, missing, second.id, first.id]
        )

        data.repairReferences()

        try expect(
            data.selectedQuoteIDs == [second.id, first.id],
            "Repair should preserve order while removing invalid IDs"
        )
    }

    private static func roundTripCodablePreservesAppearanceAndPosition() throws {
        var data = AppData.seeded
        data.paperColor = .softPink
        data.paperTexture = .dotted
        data.windowPosition = WindowPosition(x: 120, y: 240)
        data.alwaysOnTop = true

        let decoded = try JSONDecoder().decode(
            AppData.self,
            from: JSONEncoder().encode(data)
        )

        try expect(decoded == data, "Codable round trip should preserve all data")
    }
}

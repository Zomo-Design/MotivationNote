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
        alwaysOnTop: Bool = true,
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
        return AppData(
            quotes: quotes,
            selectedQuoteIDs: [quotes[0].id]
        )
    }

    mutating func repairReferences() {
        let validIDs = Set(quotes.map(\.id))
        var seen = Set<UUID>()
        selectedQuoteIDs = selectedQuoteIDs.filter {
            validIDs.contains($0) && seen.insert($0).inserted
        }
    }
}

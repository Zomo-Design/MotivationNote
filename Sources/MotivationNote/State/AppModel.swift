import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var data: AppData
    @Published private(set) var recoveryMessage: String?

    private let store: any AppDataStore

    init(store: any AppDataStore) {
        self.store = store
        var needsInitialSave = false

        do {
            if let loaded = try store.load() {
                data = loaded
                recoveryMessage = nil
            } else {
                data = .seeded
                recoveryMessage = nil
                needsInitialSave = true
            }
        } catch let StoreLoadError.corruptData(backupURL) {
            data = .seeded
            recoveryMessage = """
            原数据无法读取，已备份到 \(backupURL.lastPathComponent)，并恢复了安全默认内容。
            """
            needsInitialSave = true
        } catch {
            data = .seeded
            recoveryMessage = "数据暂时无法读取，已恢复安全默认内容。"
            needsInitialSave = true
        }

        if needsInitialSave {
            persist()
        }
    }

    var selectedQuotes: [Quote] {
        let byID = Dictionary(
            uniqueKeysWithValues: data.quotes.map { ($0.id, $0) }
        )
        return data.selectedQuoteIDs.compactMap { byID[$0] }
    }

    var unselectedQuotes: [Quote] {
        let selected = Set(data.selectedQuoteIDs)
        return data.quotes.filter { !selected.contains($0.id) }
    }

    @discardableResult
    func addQuote(text: String) -> Bool {
        let clean = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !clean.isEmpty else {
            return false
        }

        data.quotes.append(Quote(text: clean))
        persist()
        return true
    }

    @discardableResult
    func updateQuote(id: UUID, text: String) -> Bool {
        let clean = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard
            !clean.isEmpty,
            let index = data.quotes.firstIndex(
                where: { $0.id == id }
            )
        else {
            return false
        }

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
        guard data.quotes.contains(where: { $0.id == quoteID }) else {
            return
        }

        data.selectedQuoteIDs.removeAll { $0 == quoteID }
        if selected {
            data.selectedQuoteIDs.append(quoteID)
        }
        persist()
    }

    func moveSelected(
        fromOffsets: IndexSet,
        toOffset: Int
    ) {
        data.selectedQuoteIDs.move(
            fromOffsets: fromOffsets,
            toOffset: toOffset
        )
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

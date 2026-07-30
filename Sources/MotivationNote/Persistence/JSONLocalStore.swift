import Foundation

struct JSONLocalStore: AppDataStore {
    let fileURL: URL
    let fileManager: FileManager

    init(
        fileURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let base = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]
            self.fileURL = base
                .appendingPathComponent(
                    "MotivationNote",
                    isDirectory: true
                )
                .appendingPathComponent("data.json")
        }
    }

    func load() throws -> AppData? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let bytes = try Data(contentsOf: fileURL)
            var decoded = try JSONDecoder().decode(
                AppData.self,
                from: bytes
            )
            decoded.repairReferences()
            return decoded
        } catch {
            let backupURL = fileURL
                .deletingPathExtension()
                .appendingPathExtension(
                    "corrupt-\(Int(Date.now.timeIntervalSince1970)).json"
                )
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

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let encoded = try encoder.encode(data)
        let temporary = directory.appendingPathComponent(
            ".\(UUID().uuidString).tmp"
        )
        try encoded.write(to: temporary, options: .atomic)

        if fileManager.fileExists(atPath: fileURL.path) {
            _ = try fileManager.replaceItemAt(
                fileURL,
                withItemAt: temporary
            )
        } else {
            try fileManager.moveItem(at: temporary, to: fileURL)
        }
    }
}

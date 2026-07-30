import Foundation

@main
enum JSONLocalStoreChecks {
    static func main() {
        runCheckSuite("JSONLocalStore", checks: [
            missingFileLoadsNil,
            saveThenLoadRoundTripsData,
            corruptFileIsBackedUpAndReported
        ])
    }

    private static func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }

    private static func missingFileLoadsNil() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("data.json")

        let loaded = try JSONLocalStore(fileURL: file).load()
        try expect(
            loaded == nil,
            "Missing file should load as nil"
        )
    }

    private static func saveThenLoadRoundTripsData() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("data.json")
        let store = JSONLocalStore(fileURL: file)
        let expected = AppData.seeded

        try store.save(expected)

        let loaded = try store.load()
        try expect(
            loaded == expected,
            "Saved data should round trip"
        )
    }

    private static func corruptFileIsBackedUpAndReported() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("data.json")
        try Data("not-json".utf8).write(to: file)
        let store = JSONLocalStore(fileURL: file)

        do {
            _ = try store.load()
            throw CheckFailure(
                description: "Corrupt data should throw StoreLoadError"
            )
        } catch let StoreLoadError.corruptData(backupURL) {
            try expect(
                FileManager.default.fileExists(atPath: backupURL.path),
                "Corrupt data should be backed up"
            )
        }
    }
}

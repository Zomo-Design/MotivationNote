import Foundation

protocol AppDataStore {
    func load() throws -> AppData?
    func save(_ data: AppData) throws
}

enum StoreLoadError: Error, Equatable {
    case corruptData(backupURL: URL)
}

import Foundation

struct CheckFailure: Error, CustomStringConvertible {
    let description: String
}

func expect(
    _ condition: @autoclosure () -> Bool,
    _ message: String
) throws {
    guard condition() else {
        throw CheckFailure(description: message)
    }
}

func runCheckSuite(
    _ name: String,
    checks: [() throws -> Void]
) {
    do {
        for check in checks {
            try check()
        }
        print("PASS \(name) (\(checks.count) checks)")
    } catch {
        FileHandle.standardError.write(
            Data("FAIL \(name): \(error)\n".utf8)
        )
        Foundation.exit(1)
    }
}

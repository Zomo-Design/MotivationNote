import Foundation

enum PaperColor: String, CaseIterable, Codable, Sendable, Hashable {
    case warmYellow
    case softPink
    case paleGreen
    case paleBlue
    case cream
}

enum PaperTexture: String, CaseIterable, Codable, Sendable, Hashable {
    case lined
    case dotted
    case grid
    case plain
}

struct WindowPosition: Codable, Equatable, Sendable {
    var x: Double
    var y: Double
}

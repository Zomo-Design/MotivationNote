import Foundation
import SwiftUI

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
        case .warmYellow:
            Color(red: 1.00, green: 0.94, blue: 0.72)
        case .softPink:
            Color(red: 1.00, green: 0.83, blue: 0.84)
        case .paleGreen:
            Color(red: 0.82, green: 0.92, blue: 0.84)
        case .paleBlue:
            Color(red: 0.84, green: 0.89, blue: 0.98)
        case .cream:
            Color(red: 0.95, green: 0.94, blue: 0.91)
        }
    }

    var textColor: Color {
        Color(red: 0.25, green: 0.22, blue: 0.15)
    }
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

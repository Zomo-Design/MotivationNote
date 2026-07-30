import Foundation

@main
enum PaperAppearanceChecks {
    static func main() {
        runCheckSuite("PaperAppearance", checks: [
            allColorAndTextureChoicesArePresent,
            everyChoiceHasAUniqueChineseDisplayName
        ])
    }

    private static func allColorAndTextureChoicesArePresent() throws {
        try expect(
            PaperColor.allCases.count == 5,
            "There should be five paper colors"
        )
        try expect(
            PaperTexture.allCases.count == 4,
            "There should be four paper textures"
        )
    }

    private static func everyChoiceHasAUniqueChineseDisplayName() throws {
        let colorNames = PaperColor.allCases.map(\.displayName)
        let textureNames = PaperTexture.allCases.map(\.displayName)
        try expect(
            Set(colorNames).count == 5 && !colorNames.contains(""),
            "Every color needs a unique display name"
        )
        try expect(
            Set(textureNames).count == 4 && !textureNames.contains(""),
            "Every texture needs a unique display name"
        )
    }
}

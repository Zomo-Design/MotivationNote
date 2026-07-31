import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                preview
                colorPicker
                texturePicker
            }
            .padding()
        }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 10) {
            if previewQuotes.isEmpty {
                Text("今天想用哪句话陪你？")
                    .font(.headline)
            } else {
                ForEach(previewQuotes) { quote in
                    Text(quote.text)
                        .font(.headline)
                }
            }
        }
        .padding(20)
        .frame(
            width: 220,
            height: 260,
            alignment: .topLeading
        )
        .foregroundStyle(model.data.paperColor.textColor)
        .background {
            PaperBackground(
                color: model.data.paperColor,
                texture: model.data.paperTexture
            )
        }
        .accessibilityLabel("纸张外观预览")
    }

    private var colorPicker: some View {
        GroupBox("纸张颜色") {
            HStack(spacing: 16) {
                ForEach(
                    PaperColor.allCases,
                    id: \.self
                ) { choice in
                    Button {
                        model.setPaperColor(choice)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(choice.backgroundColor)

                            if choice == model.data.paperColor {
                                Circle()
                                    .stroke(
                                        Color.accentColor,
                                        lineWidth: 3
                                    )
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                            }
                        }
                        .frame(width: 42, height: 42)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        "纸张颜色：\(choice.displayName)"
                    )
                    .accessibilityValue(
                        choice == model.data.paperColor
                            ? "已选择"
                            : "未选择"
                    )
                }
            }
            .padding(8)
        }
    }

    private var texturePicker: some View {
        GroupBox("纸张纹理") {
            HStack(spacing: 14) {
                ForEach(
                    PaperTexture.allCases,
                    id: \.self
                ) { choice in
                    Button {
                        model.setPaperTexture(choice)
                    } label: {
                        PaperBackground(
                            color: model.data.paperColor,
                            texture: choice,
                            cornerRadius: 8,
                            showsShadow: false
                        )
                        .frame(width: 64, height: 48)
                        .overlay {
                            if choice == model.data.paperTexture {
                                RoundedRectangle(
                                    cornerRadius: 8
                                )
                                .stroke(
                                    Color.accentColor,
                                    lineWidth: 3
                                )
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        "纸张纹理：\(choice.displayName)"
                    )
                    .accessibilityValue(
                        choice == model.data.paperTexture
                            ? "已选择"
                            : "未选择"
                    )
                }
            }
            .padding(8)
        }
    }

    private var previewQuotes: [Quote] {
        Array(model.selectedQuotes.prefix(2))
    }
}

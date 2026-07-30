import SwiftUI

struct QuoteEditorSheet: View {
    let title: String
    let initialText: String
    let onSave: (String) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var text: String

    init(
        title: String,
        initialText: String,
        onSave: @escaping (String) -> Bool
    ) {
        self.title = title
        self.initialText = initialText
        self.onSave = onSave
        _text = State(initialValue: initialText)
    }

    private var trimmed: String {
        text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2.bold())

            TextEditor(text: $text)
                .font(.body)
                .frame(minWidth: 440, minHeight: 160)
                .accessibilityLabel("语录内容")

            if text.count > 240 {
                Text("这句话比较长，桌面便签会相应变高。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()

                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("保存") {
                    if onSave(trimmed) {
                        dismiss()
                    }
                }
                .keyboardShortcut(
                    .return,
                    modifiers: [.command]
                )
                .disabled(trimmed.isEmpty)
            }
        }
        .padding(20)
    }
}

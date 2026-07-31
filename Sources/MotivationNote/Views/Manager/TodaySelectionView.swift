import SwiftUI

struct TodaySelectionView: View {
    @ObservedObject var model: AppModel
    @State private var deleteCandidate: Quote?

    var body: some View {
        Group {
            if model.data.quotes.isEmpty {
                ContentUnavailableView(
                    "还没有语录",
                    systemImage: "quote.bubble",
                    description: Text("先新增一句激励自己的话。")
                )
            } else {
                List {
                    Section("已选 \(model.selectedQuotes.count) 句") {
                        if model.selectedQuotes.isEmpty {
                            Text("今天暂时没有选择语录")
                                .foregroundStyle(.secondary)
                        }

                        ForEach(model.selectedQuotes) { quote in
                            selectionRow(quote, selected: true)
                        }
                        .onMove(perform: model.moveSelected)
                    }

                    Section("语录库") {
                        ForEach(model.unselectedQuotes) { quote in
                            selectionRow(quote, selected: false)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .quoteDeleteConfirmation(
            candidate: $deleteCandidate,
            onDelete: { model.deleteQuote(id: $0.id) }
        )
    }

    private func selectionRow(
        _ quote: Quote,
        selected: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                model.setSelected(
                    !selected,
                    quoteID: quote.id
                )
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(
                        systemName: selected
                            ? "checkmark.circle.fill"
                            : "circle"
                    )
                    .foregroundStyle(
                        selected
                            ? Color.accentColor
                            : Color.secondary
                    )

                    Text(quote.text)
                        .foregroundStyle(.primary)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )

                    if selected {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                "\(selected ? "移出今日展示" : "加入今日展示")：\(quote.text)"
            )

            Button(role: .destructive) {
                deleteCandidate = quote
            } label: {
                Image(
                    systemName: "trash"
                )
                .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("删除语录：\(quote.text)")
        }
        .contextMenu {
            Button(role: .destructive) {
                deleteCandidate = quote
            } label: {
                Label("删除语录", systemImage: "trash")
            }
        }
    }
}

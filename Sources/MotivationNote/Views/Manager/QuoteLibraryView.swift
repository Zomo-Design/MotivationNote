import SwiftUI

struct QuoteLibraryView: View {
    @ObservedObject var model: AppModel
    @State private var editingQuote: Quote?
    @State private var deleteCandidate: Quote?

    var body: some View {
        Group {
            if model.data.quotes.isEmpty {
                ContentUnavailableView(
                    "还没有收藏的语录",
                    systemImage: "quote.bubble",
                    description: Text("点击右上角新增第一句。")
                )
            } else {
                quoteList
            }
        }
        .sheet(item: $editingQuote) { quote in
            QuoteEditorSheet(
                title: "编辑语录",
                initialText: quote.text,
                onSave: {
                    model.updateQuote(
                        id: quote.id,
                        text: $0
                    )
                }
            )
        }
        .quoteDeleteConfirmation(
            candidate: $deleteCandidate,
            onDelete: { model.deleteQuote(id: $0.id) }
        )
    }

    private var quoteList: some View {
        List(model.data.quotes) { quote in
            HStack(alignment: .top, spacing: 12) {
                Text(quote.text)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        editingQuote = quote
                    }

                Button {
                    editingQuote = quote
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(
                    "编辑语录：\(quote.text)"
                )

                Button(role: .destructive) {
                    deleteCandidate = quote
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(
                    "删除语录：\(quote.text)"
                )
            }
            .padding(.vertical, 7)
            .contextMenu {
                Button {
                    editingQuote = quote
                } label: {
                    Label("编辑语录", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    deleteCandidate = quote
                } label: {
                    Label("删除语录", systemImage: "trash")
                }
            }
        }
        .listStyle(.inset)
    }
}

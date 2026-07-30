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
        .alert(
            "确定删除这句语录吗？",
            isPresented: deleteAlertBinding,
            presenting: deleteCandidate
        ) { quote in
            Button("删除", role: .destructive) {
                model.deleteQuote(id: quote.id)
                deleteCandidate = nil
            }
            Button("取消", role: .cancel) {
                deleteCandidate = nil
            }
        } message: { quote in
            Text(quote.text)
        }
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
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(
                    "删除语录：\(quote.text)"
                )
            }
            .padding(.vertical, 7)
        }
        .listStyle(.inset)
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { deleteCandidate != nil },
            set: {
                if !$0 {
                    deleteCandidate = nil
                }
            }
        )
    }
}

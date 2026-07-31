import SwiftUI

private struct QuoteDeleteConfirmationModifier: ViewModifier {
    @Binding var candidate: Quote?
    let onDelete: (Quote) -> Void

    func body(content: Content) -> some View {
        content.alert(
            "确定删除这句语录吗？",
            isPresented: isPresented,
            presenting: candidate
        ) { quote in
            Button("删除", role: .destructive) {
                onDelete(quote)
                candidate = nil
            }
            Button("取消", role: .cancel) {
                candidate = nil
            }
        } message: { quote in
            Text(quote.text)
        }
    }

    private var isPresented: Binding<Bool> {
        Binding(
            get: { candidate != nil },
            set: {
                if !$0 {
                    candidate = nil
                }
            }
        )
    }
}

extension View {
    func quoteDeleteConfirmation(
        candidate: Binding<Quote?>,
        onDelete: @escaping (Quote) -> Void
    ) -> some View {
        modifier(
            QuoteDeleteConfirmationModifier(
                candidate: candidate,
                onDelete: onDelete
            )
        )
    }
}

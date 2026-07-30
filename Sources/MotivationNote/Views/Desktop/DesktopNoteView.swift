import SwiftUI

struct DesktopNoteView: View {
    @ObservedObject var model: AppModel
    let openManager: () -> Void
    let onHeightChange: (CGFloat) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if model.selectedQuotes.isEmpty {
                emptyState
            } else {
                quotes
            }
        }
        .padding(22)
        .frame(width: 280)
        .frame(maxHeight: 720)
        .foregroundStyle(model.data.paperColor.textColor)
        .background {
            PaperBackground(
                color: model.data.paperColor,
                texture: model.data.paperTexture
            )
        }
        .fixedSize(horizontal: false, vertical: true)
        .rotationEffect(.degrees(-0.7))
        .padding(12)
        .frame(width: 304)
        .background(sizeReader)
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                Text(
                    context.date,
                    format: .dateTime.month().day()
                )
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .accessibilityLabel("今天")
            }

            Spacer()

            Button(action: openManager) {
                Image(systemName: "ellipsis")
                    .frame(width: 28, height: 28)
                    .background(
                        .black.opacity(0.07),
                        in: Circle()
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("打开语录管理")
        }
        .foregroundStyle(
            model.data.paperColor.textColor.opacity(0.62)
        )
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今天想用哪句话陪你？")
                .font(.headline)
            Button("选择今日语录", action: openManager)
                .buttonStyle(.link)
        }
        .padding(.vertical, 26)
    }

    private var quotes: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(
                    Array(model.selectedQuotes.enumerated()),
                    id: \.element.id
                ) { index, quote in
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: "checkmark")
                            .font(.caption2.bold())
                            .padding(.top, 5)
                        Text(quote.text)
                            .font(
                                .system(
                                    size: 16,
                                    weight: .semibold
                                )
                            )
                            .lineSpacing(7)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                    }
                    .padding(.vertical, 14)

                    if index < model.selectedQuotes.count - 1 {
                        Divider().opacity(0.25)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var sizeReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    onHeightChange(proxy.size.height)
                }
                .onChange(of: proxy.size.height) { _, value in
                    onHeightChange(value)
                }
        }
    }
}

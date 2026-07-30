import SwiftUI

struct ManagerView: View {
    enum Section: String, CaseIterable, Identifiable, Hashable {
        case today = "今日展示"
        case library = "全部语录"
        case appearance = "纸张外观"

        var id: Self { self }
    }

    @ObservedObject var model: AppModel
    @State private var section: Section = .today
    @State private var showingAddSheet = false

    var body: some View {
        VStack(spacing: 16) {
            header

            Picker("页面", selection: $section) {
                ForEach(Section.allCases) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("语录管理页面")

            Group {
                switch section {
                case .today:
                    TodaySelectionView(model: model)
                case .library:
                    QuoteLibraryView(model: model)
                case .appearance:
                    AppearanceSettingsView(model: model)
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
        .padding(20)
        .frame(minWidth: 680, minHeight: 560)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showingAddSheet) {
            QuoteEditorSheet(
                title: "新增语录",
                initialText: ""
            ) {
                model.addQuote(text: $0)
            }
        }
        .alert(
            "数据恢复提示",
            isPresented: recoveryAlertBinding
        ) {
            Button("知道了") {
                model.dismissRecoveryMessage()
            }
        } message: {
            Text(model.recoveryMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            Text("我的激励语录")
                .font(.largeTitle.bold())

            Spacer()

            Button {
                showingAddSheet = true
            } label: {
                Label(
                    "新增语录",
                    systemImage: "plus.circle.fill"
                )
            }
            .keyboardShortcut("n", modifiers: .command)
            .accessibilityLabel("新增语录")
        }
    }

    private var recoveryAlertBinding: Binding<Bool> {
        Binding(
            get: { model.recoveryMessage != nil },
            set: {
                if !$0 {
                    model.dismissRecoveryMessage()
                }
            }
        )
    }
}

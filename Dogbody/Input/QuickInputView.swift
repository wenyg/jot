import SwiftUI

struct QuickInputView: View {
    @State private var text: String = ""
    @FocusState private var focused: Bool

    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: previewIcon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(previewTint)
                .frame(width: 24)

            TextField("记点什么...  前缀: - 待办  / 日志  (点回车提交)", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .focused($focused)
                .onSubmit(submit)
                .submitLabel(.done)

            Text(previewLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(previewTint.opacity(0.85), in: Capsule())
                .opacity(text.isEmpty ? 0 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .padding(6)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                focused = true
            }
        }
        .onExitCommand { onCancel() }
    }

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onCancel()
            return
        }
        onSubmit(trimmed)
        text = ""
    }

    // MARK: - Preview (reflects parse result before submit)

    private var parsed: ParsedInput { InputParser.parse(text) }

    private var previewIcon: String {
        switch parsed.kind {
        case .todo: return "checklist"
        case .entry: return "square.and.pencil"
        }
    }

    private var previewLabel: String {
        switch parsed.kind {
        case .todo: return "TODO"
        case .entry: return "日志"
        }
    }

    private var previewTint: Color {
        switch parsed.kind {
        case .todo: return .orange
        case .entry: return .blue
        }
    }
}

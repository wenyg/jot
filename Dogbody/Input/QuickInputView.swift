import SwiftUI

struct QuickInputView: View {
    @State private var text: String = ""
    @State private var manualOverride: ParsedInput.Kind?
    @FocusState private var focused: Bool

    let onSubmit: (String, ParsedInput.Kind?) -> Void
    let onCancel: () -> Void

    /// Derived classification of the current text, respecting a manual override.
    private var effectiveKind: ParsedInput.Kind {
        if let o = manualOverride { return o }
        return InputParser.classify(text: text, hasDueDate: text.contains("@"))
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pencil.line")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary.opacity(0.6))
                .frame(width: 18)

            TextField("你在想什么?", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .focused($focused)
                .onSubmit(submit)
                .onChange(of: text) { _ in
                    // Any text change clears the manual override so live
                    // classification keeps tracking intent.
                    manualOverride = nil
                }

            // Classification pill, Tab to flip.
            Button(action: toggleKind) {
                Text(kindLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(kindTint, in: Capsule())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.tab, modifiers: [])
            .opacity(text.isEmpty ? 0 : 1)
            .help("按 Tab 切换 TODO / 日志")
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
        onSubmit(trimmed, manualOverride)
        text = ""
        manualOverride = nil
    }

    private func toggleKind() {
        manualOverride = (effectiveKind == .todo) ? .entry : .todo
    }

    private var kindLabel: String {
        switch effectiveKind {
        case .todo: return "TODO"
        case .entry: return "日志"
        }
    }

    private var kindTint: Color {
        switch effectiveKind {
        case .todo: return .orange
        case .entry: return .blue
        }
    }
}

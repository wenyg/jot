import SwiftUI

/// Pet-anchored "speech bubble" used to record a thought.
/// The bubble is rendered as a single Shape (rounded body + tail) so the
/// `.regularMaterial` fill flows seamlessly from the tail tip into the body.
struct QuickInputView: View {
    @State private var text: String = ""
    @State private var manualOverride: ParsedInput.Kind?
    @FocusState private var focused: Bool

    let onSubmit: (String, ParsedInput.Kind?) -> Void
    let onCancel: () -> Void

    /// Horizontal position (in view coords) where the tail meets the bubble.
    /// Set by the panel controller so the tail always points at the pet, even
    /// when the bubble itself is clamped to the screen edge.
    let tailCenterX: CGFloat
    /// `true` when the bubble sits *below* the pet (tail at top, pointing up).
    /// `false` when the bubble sits *above* the pet (tail at bottom, pointing down).
    let tailOnTop: Bool

    /// Derived classification of the current text, respecting a manual override.
    private var effectiveKind: ParsedInput.Kind {
        if let o = manualOverride { return o }
        return InputParser.classify(text: text, hasDueDate: text.contains("@"))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // The bubble itself — material + hairline outline, drawn once
            // through a custom Shape so the tail is part of the same blob.
            BubbleShape(tailCenterX: tailCenterX, tailOnTop: tailOnTop)
                .fill(.regularMaterial)
                .overlay(
                    BubbleShape(tailCenterX: tailCenterX, tailOnTop: tailOnTop)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.18), radius: 12, y: 4)

            TextField("记点什么", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .focused($focused)
                .onSubmit(submit)
                .onChange(of: text) { _ in
                    manualOverride = nil
                }
                .padding(.horizontal, 18)
                .padding(.top, tailOnTop ? BubbleShape.tailHeight + 14 : 14)
                .padding(.bottom, tailOnTop ? 14 : BubbleShape.tailHeight + 14)

            // Tiny pill in the corner — a quiet whisper, not a banner.
            // Only appears once the user has typed something to classify.
            if !text.isEmpty {
                Button(action: toggleKind) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(kindTint)
                            .frame(width: 5, height: 5)
                        Text(kindLabel)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.tab, modifiers: [])
                .padding(.trailing, 12)
                .padding(.bottom, tailOnTop ? 6 : BubbleShape.tailHeight + 6)
                .help("Tab 切换 TODO / 日志")
                .transition(.opacity)
            }
        }
        .padding(2)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                focused = true
            }
        }
        .onExitCommand { onCancel() }
        .animation(.easeOut(duration: 0.12), value: text.isEmpty)
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

/// Speech-bubble shape: rounded body + a triangular tail stitched onto either
/// the top or the bottom edge. Drawn as one continuous path so a single
/// material fill covers both pieces with no seam.
struct BubbleShape: Shape {
    static let tailHeight: CGFloat = 10
    static let tailWidth: CGFloat = 18
    static let cornerRadius: CGFloat = 14

    let tailCenterX: CGFloat
    let tailOnTop: Bool

    func path(in rect: CGRect) -> Path {
        let bodyRect: CGRect
        if tailOnTop {
            bodyRect = CGRect(x: 0, y: Self.tailHeight, width: rect.width, height: rect.height - Self.tailHeight)
        } else {
            bodyRect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height - Self.tailHeight)
        }

        var path = Path()
        path.addRoundedRect(in: bodyRect, cornerSize: CGSize(width: Self.cornerRadius, height: Self.cornerRadius))

        // Clamp the tail so it never escapes the rounded body.
        let minX = Self.cornerRadius + Self.tailWidth / 2 + 2
        let maxX = rect.width - Self.cornerRadius - Self.tailWidth / 2 - 2
        let cx = max(minX, min(tailCenterX, maxX))

        var tail = Path()
        if tailOnTop {
            tail.move(to: CGPoint(x: cx - Self.tailWidth / 2, y: Self.tailHeight))
            tail.addLine(to: CGPoint(x: cx, y: 0))
            tail.addLine(to: CGPoint(x: cx + Self.tailWidth / 2, y: Self.tailHeight))
            tail.closeSubpath()
        } else {
            let baseY = bodyRect.maxY
            tail.move(to: CGPoint(x: cx - Self.tailWidth / 2, y: baseY))
            tail.addLine(to: CGPoint(x: cx, y: baseY + Self.tailHeight))
            tail.addLine(to: CGPoint(x: cx + Self.tailWidth / 2, y: baseY))
            tail.closeSubpath()
        }
        path.addPath(tail)
        return path
    }
}

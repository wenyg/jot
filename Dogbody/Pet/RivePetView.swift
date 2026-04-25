import SwiftUI
import AppKit
import RiveRuntime

/// Renders a Rive (.riv) file as the pet body. This is the new default
/// renderer that replaces the SwiftUI vector "Yuumi" build at runtime
/// when `PetRenderMode.preferred == .rive`.
///
/// Why Rive (vs hand-drawn SwiftUI):
///   • The artwork comes from a real animator using a proper editor.
///   • Rive's state-machine model maps 1:1 to our `PetAnimator.state`,
///     so swapping in a richer cat in the future is one drag-and-drop away.
///
/// Behavior:
///   • The .riv file is loaded by name (no extension) from the bundle.
///   • On first appear we introspect the loaded model and log what's
///     available — artboard name, state machine name, input names. This
///     makes plugging a new .riv file into our state machine a one-edit job.
///   • When `animator.state` changes we attempt to drive the .riv via
///     best-effort name matching against common idioms (trigger names,
///     boolean flags, or a numeric `state` selector). If a particular .riv
///     happens to have no matching inputs the animation just keeps playing
///     its default loop — that's still a strict visual upgrade over our
///     previous SwiftUI vector.
struct RivePetView: View {
    @ObservedObject var animator: PetAnimator
    let fileName: String

    @StateObject private var box: RiveBox

    init(animator: PetAnimator, fileName: String = RivePetCatalog.defaultFileName) {
        self.animator = animator
        self.fileName = fileName
        _box = StateObject(wrappedValue: RiveBox(fileName: fileName))
    }

    var body: some View {
        ZStack {
            box.viewModel.view()
                .background(Color.clear)
                .allowsHitTesting(false)   // PetView's gesture stack handles input
        }
        .onAppear {
            box.introspect()
            box.apply(state: animator.state)
        }
        .onChange(of: animator.state) { newState in
            box.apply(state: newState)
        }
        .onChange(of: animator.isBeingDragged) { dragging in
            box.apply(boolNamed: ["isDragging", "dragging", "Dragging"], value: dragging)
        }
        .onChange(of: animator.isHovering) { hovering in
            box.apply(boolNamed: ["isHovering", "hovering", "Hover", "Hovered"], value: hovering)
        }
    }
}

// MARK: - Catalog of bundled .riv files

/// Central registry of bundled .riv files. Switching the default character
/// is a one-line change here. To try another file, set
/// `UserDefaults.standard.set("mascot", forKey: "pet.riveFileName")` and
/// restart the app.
enum RivePetCatalog {
    /// File names we know about (matches `Dogbody/Pet/RiveAssets/*.riv`).
    /// All licensed under MIT via the rive-app/rive-ios sample assets.
    static let bundled: [String] = ["Bear", "mascot", "marty", "hero_editor"]

    /// Default if the user hasn't pinned anything.
    static let defaultFileName: String = "Bear"

    /// Picks the active file name, honoring the user-overridable default.
    static var active: String {
        let pinned = UserDefaults.standard.string(forKey: "pet.riveFileName")
        if let pinned, bundled.contains(pinned) { return pinned }
        return defaultFileName
    }
}

// MARK: - RiveBox

/// Owns the `RiveViewModel` so it survives SwiftUI re-renders, and centralises
/// the (best-effort) mapping from `PetState` to Rive inputs.
@MainActor
final class RiveBox: ObservableObject {
    let fileName: String
    let viewModel: RiveViewModel
    private var didIntrospect = false

    init(fileName: String) {
        self.fileName = fileName
        // stateMachineName: nil  → use the file's first state machine if one
        // exists, otherwise fall back to its default animation. Either way the
        // file will play; only `setInput`/`triggerInput` calls will no-op.
        self.viewModel = RiveViewModel(
            fileName: fileName,
            stateMachineName: nil,
            fit: .contain,
            alignment: .center,
            autoPlay: true,
            artboardName: nil
        )
    }

    /// One-time log of what the loaded .riv file exposes. Run on first
    /// `onAppear`. Useful to know which input names we should be driving.
    func introspect() {
        guard !didIntrospect else { return }
        didIntrospect = true

        let model = viewModel.riveModel
        let artboardName = model?.artboard?.name() ?? "<nil>"
        let smName = model?.stateMachine?.name() ?? "<no state machine>"
        let animName = model?.animation?.name() ?? "<no animation>"

        var lines: [String] = []
        lines.append("[Rive] file=\(fileName).riv  artboard=\(artboardName)")
        lines.append("[Rive] active=\(smName.isEmpty ? animName : smName)")

        if let sm = model?.stateMachine {
            let inputs = sm.inputs
            lines.append("[Rive] state machine inputs (\(inputs.count)):")
            for input in inputs {
                let kind: String
                switch input.type {
                case .trigger: kind = "trigger"
                case .boolean: kind = "bool"
                case .number:  kind = "number"
                }
                lines.append("[Rive]   • \(input.name) : \(kind)")
            }
        }
        print(lines.joined(separator: "\n"))
    }

    /// Drive the Rive state machine to roughly reflect `state`. Tries multiple
    /// common naming conventions so a third-party .riv has a fighting chance
    /// of reacting without us editing it.
    func apply(state: PetState) {
        // 1. Trigger the state's name (handles `idle`, `Idle`, `IsHappy`, …).
        for name in triggerCandidates(for: state) {
            viewModel.triggerInput(name)
        }
        // 2. Boolean idiom: `is<State>` true on the active state, false on others.
        for s in PetState.allCases {
            let on = (s == state)
            viewModel.setInput("is\(s.rawValue.capitalized)", value: on)
        }
        // 3. Numeric selector idiom (some files expose a single `state` number).
        if let idx = PetState.allCases.firstIndex(of: state) {
            viewModel.setInput("state", value: Double(idx))
            viewModel.setInput("mood", value: Double(idx))
        }
    }

    /// Try setting the given boolean under any of `names`.
    func apply(boolNamed names: [String], value: Bool) {
        for name in names {
            viewModel.setInput(name, value: value)
        }
    }

    private func triggerCandidates(for state: PetState) -> [String] {
        switch state {
        case .idle:      return ["idle", "Idle"]
        case .happy:     return ["happy", "Happy", "smile", "Smile"]
        case .thinking:  return ["thinking", "Thinking", "think", "Think"]
        case .sleep:     return ["sleep", "Sleep", "sleeping", "Sleeping"]
        case .celebrate: return ["celebrate", "Celebrate", "cheer", "happy"]
        case .remind:    return ["remind", "Remind", "alert", "wave", "Wave"]
        }
    }
}

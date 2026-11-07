import SwiftUI
import UIKit

/// Raises the keyboard together with a sheet, in one motion (screens.md, Add
/// sheet: "the keyboard rises with the sheet").
///
/// SwiftUI applies `@FocusState` (and `.defaultFocus`) to a field in a `Form`
/// only after the sheet has settled, so the keyboard followed it ~0.5 s late
/// (on device, and in the simulator on iOS 26.5). This hidden UIKit field
/// becomes first responder as the sheet's view enters the window (the moment
/// `viewWillAppear` runs), so UIKit animates the keyboard alongside the
/// presentation. When SwiftUI then focuses the real field, first responder
/// moves across and the keyboard stays up.
///
/// Its keyboard matches the real field's (capitalization, return key), so
/// nothing changes when focus moves. Anything typed in between is handed on
/// through `onType` ("" for a delete), never lost.
///
/// `Handle.prime` takes the keyboard again on demand: switching the add
/// sheet's tabs, where the old tab's field leaves the hierarchy before the
/// new one appears.
struct KeyboardPrimer: UIViewRepresentable {
    /// Lets the sheet take the keyboard back to the primer.
    @MainActor final class Handle {
        fileprivate weak var field: PrimerField?

        /// The primer takes the keyboard, with the next field's traits.
        func prime(autocapitalization: UITextAutocapitalizationType, returnKey: UIReturnKeyType) {
            guard let field else { return }
            field.autocapitalizationType = autocapitalization
            field.returnKeyType = returnKey
            field.becomeFirstResponder()
        }
    }

    var handle: Handle
    var autocapitalization: UITextAutocapitalizationType
    var returnKey: UIReturnKeyType
    var onType: (String) -> Void

    func makeUIView(context: Context) -> PrimerField {
        let field = PrimerField()
        field.autocapitalizationType = autocapitalization
        field.returnKeyType = returnKey
        field.delegate = context.coordinator
        field.isAccessibilityElement = false
        field.tintColor = .clear
        field.textColor = .clear
        handle.field = field
        return field
    }

    func updateUIView(_ field: PrimerField, context: Context) {
        context.coordinator.onType = onType
    }

    func makeCoordinator() -> Coordinator { Coordinator(onType: onType) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var onType: (String) -> Void

        init(onType: @escaping (String) -> Void) { self.onType = onType }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            onType(string)
            return false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool { false }
    }

    /// Takes the keyboard once, when it first enters a window.
    final class PrimerField: UITextField {
        private var primed = false

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil, !primed else { return }
            primed = true
            becomeFirstResponder()
        }
    }
}

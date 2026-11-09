import SwiftUI

// The add sheet's field rules and footer, shared with onboarding's guided
// add (auth-onboarding.md screen 4: "the add sheet's own fields").

extension View {
    /// A field's rules: the cap stops input; the contact-info check runs once
    /// typing pauses (`duration.validationPause`) and clears at once when
    /// fixed; `onEdit` runs on every change (to clear a failed save's line).
    func textFieldRules(text: Binding<String>, cap: Int, hasContactIssue: @escaping () -> Bool,
                        showContactIssue: @escaping (Bool) -> Void, onEdit: @escaping () -> Void = {}) -> some View {
        self
            .onChange(of: text.wrappedValue) { _, new in
                if new.count > cap { text.wrappedValue = String(new.prefix(cap)) }
                onEdit()
            }
            .task(id: text.wrappedValue) {
                guard hasContactIssue() else {
                    showContactIssue(false)
                    return
                }
                try? await Task.sleep(for: .seconds(PP.duration.validationPause))
                if !Task.isCancelled { showContactIssue(true) }
            }
    }
}

/// The section footer under a field: its contact-info message (ink) in place
/// of its caption, and the "34/40" counter in the last 10 characters.
struct FieldFooter: View {
    let text: String
    let cap: Int
    let contactIssue: Bool
    var caption: String?

    var body: some View {
        let count = text.count
        if contactIssue || caption != nil || count >= cap - 10 {
            HStack(alignment: .firstTextBaseline) {
                if contactIssue {
                    Text(L10n.Add.contactError).foregroundStyle(PP.color.ink)
                } else if let caption {
                    Text(caption)
                }
                Spacer(minLength: 0)
                if count >= cap - 10 {
                    Text(L10n.Add.counter(count, cap)).monospacedDigit()
                }
            }
        }
    }
}

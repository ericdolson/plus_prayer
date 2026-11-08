import PlusPrayerDomain
import SwiftUI

/// "Prints with" (detail-page.md "Carry card" 2, Q32): a native check list
/// pushed from a person's carry card: Name only, then their open intentions
/// (Answered and Released aren't listed). At the cap (1) a tap moves the
/// check; a higher cap allows that many checks, unchecked rows disabled at
/// the cap. A swap is never pool-checked. Never silent: the check moves at
/// once and the rows wait while saving; a failure puts it back with a line
/// under the list; offline the rows are disabled with "Needs a connection.".
struct PrintsWithList: View {
    let personId: String

    @Environment(HomeModel.self) private var home
    /// The checked ids while setCarriedItems is on its way ("" = Name only).
    @State private var pending: Set<String>?
    @State private var error: String?

    var body: some View {
        let values = home.printsWithOptions(personId)
        let checked = pending ?? Set(values.options.filter(\.checked).map(\.id))
        List {
            Section {
                row(L10n.Page.nameOnly, checked: checked.isEmpty, enabled: true) { choose(nil, values) }
                ForEach(values.options) { option in
                    row(option.text, checked: checked.contains(option.id), enabled: option.enabled) {
                        choose(option.id, values)
                    }
                }
            } footer: {
                if let line = home.isOnline ? error : L10n.Page.carryOffline {
                    Text(line).foregroundStyle(PP.color.ink)
                }
            }
            .disabled(!home.isOnline || pending != nil)
        }
        .navigationTitle(L10n.Page.printsWith)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: values) { pending = nil }
        .onDisappear { error = nil }
    }

    private func row(_ text: String, checked: Bool, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(verbatim: text)
                    .foregroundStyle(PP.color.ink)
                Spacer(minLength: PP.space.sm)
                if checked {
                    PPIcon.check
                        .foregroundStyle(PP.color.ink)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .disabled(!enabled)
        .accessibilityAddTraits(checked ? .isSelected : [])
    }

    private func choose(_ intentionId: String?, _ values: PrintsWithValues) {
        let current = Set(values.options.filter(\.checked).map(\.id))
        var next: Set<String>
        if let intentionId {
            if values.cap <= 1 {
                next = [intentionId]
            } else {
                next = current.symmetricDifference([intentionId])
            }
        } else {
            next = []
        }
        guard next != current else { return }
        pending = next
        error = nil
        Task {
            do {
                try await home.setPrintsWith(personId, intentionId)
            } catch {
                pending = nil
                self.error = switch error {
                case SetCarriedError.offline: L10n.Page.carryOffline
                default: L10n.Page.carryFailed
                }
            }
        }
    }
}

#Preview("Prints with") {
    @Previewable @State var home = HomeModel(environment: .mock(MockBackend(latency: .zero, liveDrift: false)))
    NavigationStack { PrintsWithList(personId: "dad") }
        .environment(home)
        .task { await home.run() }
}

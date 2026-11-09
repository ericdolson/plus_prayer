import PlusPrayerDomain
import SwiftUI

/// "What's your name?" (auth-onboarding.md, first run step 3; app-brief §3):
/// shown over Home whenever the signed-in account has no self name yet
/// (onboarding resumes from data). The answer becomes the self ("Me") through
/// setSelfName; the header re-read then brings Home. Only this step is built;
/// the splash, the mechanic line and "Who else do you hold?" come with the
/// rest of onboarding. A native `Form` (Tier B), like the add sheet.
struct NameStep: View {
    @Environment(HomeModel.self) private var home
    @State private var name = ""
    @State private var saving = false
    @State private var problem: Problem?
    @FocusState private var focused: Bool

    enum Problem: Equatable {
        case contact, offline, failed
    }

    private let cap = TextCap.printed(.soul)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L10n.Add.nameLabel, text: $name)
                        .focused($focused)
                        .accessibilityLabel(L10n.Add.nameLabel)
                        .textInputAutocapitalization(.words)
                        .textContentType(.name)
                        .submitLabel(.done)
                        .onSubmit(submit)
                        .onChange(of: name) { _, new in
                            if new.count > cap { name = String(new.prefix(cap)) }
                            problem = nil
                        }
                        .listRowBackground(PP.color.raised)
                } header: {
                    Text(L10n.Add.nameLabel)
                } footer: {
                    footer
                }
            }
            .scrollContentBackground(.hidden)
            .background(PP.color.ground)
            .navigationTitle(L10n.Onboarding.nameTitle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if saving {
                        ProgressView()
                    } else {
                        Button(L10n.Onboarding.nameContinue, action: submit)
                            .disabled(!canSubmit)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .onAppear { focused = true }
    }

    private var canSubmit: Bool { !saving && validatePrinted(name, kind: .soul) == nil }

    /// The helper (their name will be carried by the world) and the privacy
    /// sentence; an error in their place, in ink.
    @ViewBuilder private var footer: some View {
        VStack(alignment: .leading, spacing: PP.space.xs) {
            switch problem {
            case .contact: Text(L10n.Add.contactError).foregroundStyle(PP.color.ink)
            case .offline: Text(L10n.Onboarding.nameOffline).foregroundStyle(PP.color.ink)
            case .failed: Text(L10n.Onboarding.nameFailed).foregroundStyle(PP.color.ink)
            case nil:
                Text(L10n.Onboarding.nameHelper)
                Text(L10n.Onboarding.namePrivacy)
            }
            if name.count >= cap - 10 {
                Text(L10n.Add.counter(name.count, cap)).monospacedDigit()
            }
        }
    }

    private func submit() {
        guard canSubmit else {
            if validatePrinted(name, kind: .soul) == .contactInfo { problem = .contact }
            return
        }
        saving = true
        Task {
            defer { saving = false }
            do {
                try await home.setSelfName(name)
            } catch SelfNameError.input {
                problem = .contact
            } catch SelfNameError.offline {
                problem = .offline
            } catch {
                problem = .failed
            }
        }
    }
}

#Preview("Name step") {
    let backend = MockBackend(latency: .zero, liveDrift: false)
    return NameStep()
        .environment(HomeModel(environment: .mock(backend)))
}

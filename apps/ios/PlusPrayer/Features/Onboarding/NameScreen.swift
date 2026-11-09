import PlusPrayerDomain
import SwiftUI

/// Screen 2: "What's your name?" (Large Title, sans), the 96 pt avatar
/// filling with initials as you type, one field set in Roca (how it
/// prints), focused on arrival; Continue rides above the keyboard, disabled
/// while empty. 40 characters; contact info, offline and a failure show
/// their lines under the field (ink). Continue → setSelfName → Welcome back.
struct NameScreen: View {
    @Bindable var model: OnboardingModel
    @FocusState private var focused: Bool
    private let cap = TextCap.printed(.soul)

    var body: some View {
        ScrollView {
            VStack(spacing: PP.space.xl) {
                Text(L10n.Onboarding.nameTitle)
                    .font(PP.type.onboardingTitle)
                    .foregroundStyle(PP.color.ink)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                MonogramAvatar(initials: model.nameInitials, tone: model.selfTone, size: PP.size.avatar.person,
                               placeholder: PPIcon.person)
                VStack(spacing: PP.space.sm) {
                    TextField(L10n.Add.nameLabel, text: $model.name)
                        .font(PP.type.displayTitle)
                        .foregroundStyle(PP.color.ink)
                        .multilineTextAlignment(.center)
                        .focused($focused)
                        .accessibilityLabel(L10n.Add.nameLabel)
                        .accessibilityIdentifier("onboarding.name.field")
                        .textInputAutocapitalization(.words)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .submitLabel(.continue)
                        .onSubmit(submit)
                        .onChange(of: model.name) { _, new in
                            if new.count > cap { model.name = String(new.prefix(cap)) }
                            model.nameChanged()
                        }
                        .padding(PP.space.md)
                        .background(PP.color.raised, in: RoundedRectangle(cornerRadius: PP.radius.md))
                    footer
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, PP.space.gutter)
            .padding(.vertical, PP.space.xl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(PP.color.ground)
        .navigationBarTitleDisplayMode(.inline)
        // Above the keyboard while it's up; above the home indicator otherwise.
        .safeAreaBar(edge: .bottom) {
            OnboardingButton(title: L10n.Onboarding.nameContinue, prominent: true, busy: model.savingName,
                             identifier: "onboarding.name.continue", action: submit)
                .disabled(!model.canContinueName)
                .padding(.horizontal, PP.space.gutter)
                .padding(.bottom, PP.space.sm)
        }
        .onAppear { focused = true }
    }

    /// An error in ink, and the "34/40" counter in the last 10 characters.
    @ViewBuilder private var footer: some View {
        let problem: String? = switch model.nameProblem {
        case .contact: L10n.Add.contactError
        case .offline: L10n.Onboarding.nameOffline
        case .failed: L10n.Onboarding.nameFailed
        case nil: nil
        }
        if problem != nil || model.name.count >= cap - 10 {
            HStack(alignment: .firstTextBaseline) {
                if let problem { Text(problem).foregroundStyle(PP.color.ink) }
                Spacer(minLength: 0)
                if model.name.count >= cap - 10 {
                    Text(L10n.Add.counter(model.name.count, cap)).monospacedDigit()
                        .foregroundStyle(PP.color.inkMuted)
                }
            }
            .font(PP.type.caption)
        }
    }

    private func submit() {
        Task { await model.submitName() }
    }
}

/// Onboarding's labeled buttons: the native prominent (blue) or glass
/// (ink) button at full width, large; a spinner in place of the title while
/// busy. Titles wrap at the largest text sizes rather than truncate.
struct OnboardingButton: View {
    let title: String
    var icon: Image?
    var prominent = false
    var busy = false
    var identifier: String?
    let action: () -> Void

    var body: some View {
        let button = Button(action: action) {
            ZStack {
                Group {
                    if let icon {
                        Label { Text(title) } icon: { icon }
                    } else {
                        Text(title)
                    }
                }
                .multilineTextAlignment(.center)
                .opacity(busy ? 0 : 1)
                if busy { ProgressView() }
            }
            .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .accessibilityLabel(title)
        .accessibilityIdentifier(identifier ?? title)
        if prominent {
            button.buttonStyle(.glassProminent).tint(PP.color.primary)
        } else {
            button.buttonStyle(.glass).tint(PP.color.ink)
        }
    }
}

#Preview("Name") {
    let home = HomeModel(environment: .mock(MockBackend(seed: .fresh(now: .now), latency: .zero, liveDrift: false)))
    return NavigationStack { NameScreen(model: OnboardingModel(home: home)) }
        .environment(home)
}

#Preview("Name, large type, dark") {
    let home = HomeModel(environment: .mock(MockBackend(seed: .fresh(now: .now), latency: .zero, liveDrift: false)))
    return NavigationStack { NameScreen(model: OnboardingModel(home: home)) }
        .environment(home)
        .dynamicTypeSize(.accessibility5)
        .preferredColorScheme(.dark)
}

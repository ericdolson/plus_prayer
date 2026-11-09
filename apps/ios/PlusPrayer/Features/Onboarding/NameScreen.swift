import PlusPrayerDomain
import SwiftUI

/// Step 1, your name: "Here, we pray for each other." (Roca, regular) ·
/// "What's your name?" · one centered sans field ("Your name"). No keyboard
/// on arrival: tapping the field raises it. Return continues (as does the
/// stage's button); 40 characters; contact info, offline and a failure show
/// their lines under the field (ink).
struct NameStep: View {
    @Bindable var model: OnboardingModel
    /// The space above the lead (`number.onboarding.leadTop`).
    let top: CGFloat
    @FocusState private var focused: Bool
    private let cap = TextCap.printed(.soul)

    var body: some View {
        VStack(spacing: 0) {
            NameStepLead()
                .padding(.top, top)
            UnderlinedField(focused: focused) {
                TextField(L10n.Onboarding.namePlaceholder, text: $model.name,
                          prompt: Text(L10n.Onboarding.namePlaceholder).foregroundStyle(PP.color.inkFaint))
                    .font(PP.type.onboardingField)
                    .foregroundStyle(PP.color.ink)
                    .multilineTextAlignment(.center)
                    .focused($focused)
                    .accessibilityLabel(L10n.Onboarding.namePlaceholder)
                    .accessibilityIdentifier("onboarding.name.field")
                    .textInputAutocapitalization(.words)
                    .textContentType(.name)
                    .autocorrectionDisabled()
                    .submitLabel(.continue)
                    .onSubmit { Task { await model.submitName() } }
                    .onChange(of: model.name) { _, new in
                        if new.count > cap { model.name = String(new.prefix(cap)) }
                        model.nameChanged()
                    }
                    .stageSlot(.nameField)
            }
            .padding(.top, PP.space.lg)
            .onboardingLine(delay: OnboardingTiming.line(2))
            footer
                .padding(.top, PP.space.sm)
        }
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
            .accessibilityElement(children: .combine)
        }
    }
}

/// The lead and the question of step 1. Step 2 lays out an invisible copy
/// so its avatar forms right above where the name was typed.
private struct NameStepLead: View {
    var animated = true

    var body: some View {
        VStack(spacing: 0) {
            Text(L10n.Onboarding.lead)
                .font(PP.type.onboardingLead)
                .foregroundStyle(PP.color.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .modifier(LineIf(animated, delay: OnboardingTiming.line(0)))
            Text(L10n.Onboarding.nameQuestion)
                .font(PP.type.body)
                .foregroundStyle(PP.color.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, PP.space.xxxl)
                .modifier(LineIf(animated, delay: OnboardingTiming.line(1)))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct LineIf: ViewModifier {
    let on: Bool
    let delay: TimeInterval
    init(_ on: Bool, delay: TimeInterval) {
        self.on = on
        self.delay = delay
    }

    func body(content: Content) -> some View {
        if on { content.onboardingLine(delay: delay) } else { content }
    }
}

/// Step 2, the moment: the typed name becomes Roca in place, the avatar
/// forms above it, the name settles onto the "List 53" paper line, then
/// "Pray with today's list. Tomorrow your name is on it." and "The list is
/// printed and sealed each day, and kept private." The avatar and the name
/// are the stage's anchors; this lays out their slots (`momentAvatar`,
/// `nameAbove` exactly where the field was, `nameOnPaper`). No seal, no
/// haptic: both belong to the first Amen.
struct MomentStep: View {
    let model: OnboardingModel
    let top: CGFloat
    /// Arriving from the name (the whole moment) or back from the person
    /// step (the paper and lines simply return).
    let fromName: Bool

    var body: some View {
        let paperAt = fromName ? PP.duration.onboardingMomentPaper : PP.duration.onboardingReturnPaper
        let linesAt = fromName ? PP.duration.onboardingMomentLines : PP.duration.onboardingReturnLines
        VStack(spacing: 0) {
            // Step 1's lead and question, invisible: the avatar sits above
            // where the field was, and the name starts exactly there.
            ZStack(alignment: .bottom) {
                NameStepLead(animated: false)
                    .hidden()
                    .accessibilityHidden(true)
                Color.clear
                    .frame(width: PP.size.avatar.large, height: PP.size.avatar.large)
                    .stageSlot(.momentAvatar)
                    .padding(.bottom, PP.space.sm)
            }
            .padding(.top, top)
            // Where the field's text was: the name's first place.
            UnderlinedField(focused: false, ruled: false) {
                Text(verbatim: model.displayName.isEmpty ? " " : model.displayName)
                    .font(PP.type.onboardingField)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .hidden()
                    .stageSlot(.nameAbove)
            }
            .padding(.top, PP.space.lg)
            .accessibilityHidden(true)
            ListPaperLine(label: model.nextListNumber.map(L10n.Card.title)) {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .stageSlot(.nameOnPaper)
                    .accessibilityElement()
                    .accessibilityLabel(model.displayName)
            }
            .padding(.top, PP.space.xxl)
            .accessibilityElement(children: .contain)
            .onboardingLine(delay: paperAt, rise: PP.size.onboarding.paperRise)
            Text(L10n.Onboarding.mechanic)
                .font(PP.type.onboardingMechanic)
                .foregroundStyle(PP.color.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, PP.space.xl)
                .onboardingLine(delay: OnboardingTiming.line(0, after: linesAt))
            Text(L10n.Onboarding.privacy)
                .font(PP.type.body)
                .foregroundStyle(PP.color.inkMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, PP.space.md)
                .onboardingLine(delay: OnboardingTiming.line(1, after: linesAt))
        }
        .frame(maxWidth: .infinity)
    }
}

/// An onboarding field: a line of type over a hairline (ink at
/// `number.onboarding.hairline`, stronger while focused). No box, no form
/// chrome.
struct UnderlinedField<Field: View>: View {
    let focused: Bool
    var ruled = true
    @ViewBuilder let field: () -> Field

    var body: some View {
        field()
            .padding(.vertical, PP.size.onboarding.fieldPadding)
            .overlay(alignment: .bottom) {
                if ruled {
                    Rectangle()
                        .fill(PP.color.ink.opacity(focused ? PP.number.onboarding.hairlineFocused
                                                           : PP.number.onboarding.hairline))
                        .frame(height: PP.size.onboarding.hairline)
                        .accessibilityHidden(true)
                }
            }
            .tint(PP.color.primary)
    }
}

/// Onboarding's one blue button (a capsule on glass tinted action blue, like
/// the pray button it becomes in the hand-off): full width, the label
/// crossfading as it changes; dim while it can't be used; a spinner in
/// place of the label while busy. The label wraps at the largest sizes.
struct OnboardingButton: View {
    let title: String
    var enabled = true
    var busy = false
    var identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .id(title)
                    .transition(.opacity)
                    .font(PP.type.onboardingButton)
                    .foregroundStyle(PP.color.onPrimary.opacity(enabled ? 1 : PP.number.onboarding.disabledLabel))
                    .multilineTextAlignment(.center)
                    .opacity(busy ? 0 : 1)
                if busy { ProgressView().tint(PP.color.onPrimary) }
            }
            .padding(.horizontal, PP.space.xl)
            .padding(.vertical, PP.space.sm)
            .frame(maxWidth: .infinity, minHeight: PP.size.onboarding.button)
            .contentShape(Capsule())
            .animation(.easeOut(duration: PP.duration.quick), value: title)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular
                        .tint(enabled ? PP.color.primary : PP.color.primary.opacity(PP.number.onboarding.disabledTint))
                        .interactive(enabled && !busy),
                     in: .capsule)
        .disabled(!enabled || busy)
        .accessibilityLabel(title)
        .accessibilityIdentifier(identifier)
    }
}

#Preview("Button") {
    VStack(spacing: PP.space.lg) {
        OnboardingButton(title: "Continue", identifier: "a") {}
        OnboardingButton(title: "Continue", enabled: false, identifier: "b") {}
        OnboardingButton(title: "Add", busy: true, identifier: "c") {}
    }
    .padding(PP.space.gutter)
    .frame(maxHeight: .infinity)
    .background(PP.color.ground)
    .preferredColorScheme(.dark)
}

#Preview("Button, large type") {
    OnboardingButton(title: "Continue", identifier: "a") {}
        .padding(PP.space.gutter)
        .frame(maxHeight: .infinity)
        .background(PP.color.ground)
        .dynamicTypeSize(.accessibility5)
        .preferredColorScheme(.dark)
}

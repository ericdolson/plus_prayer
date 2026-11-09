import PlusPrayerDomain
import SwiftUI

/// Step 3, someone you pray for (optional): "Who do you pray for?" (Roca),
/// the empty place where their avatar forms with the first letter (the
/// stage's anchor; initials from what you call them once there is one),
/// then the add sheet's fields in onboarding's type, no form chrome: Name
/// ("e.g. Julie Olson", "Printed on the list") and "What you call them ·
/// optional" ("e.g. Mom", "Only you see this"). The add sheet's rules
/// (`textFieldRules`, `FieldFooter`). Nothing is saved here. Focused on
/// arrival; Return moves to the next field, then continues.
struct SomeoneStep: View {
    @Bindable var model: OnboardingModel
    @FocusState private var focus: Field?

    private enum Field: Hashable {
        case name, alias
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.Onboarding.someoneTitle)
                .font(PP.type.onboardingLeadSmall)
                .foregroundStyle(PP.color.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, PP.space.lg)
                .onboardingLine(delay: OnboardingTiming.line(0))
            Color.clear
                .frame(width: PP.size.onboarding.personAvatar, height: PP.size.onboarding.personAvatar)
                .stageSlot(.someoneAvatar)
                .frame(maxWidth: .infinity)
                .padding(.vertical, PP.space.xl)
                .accessibilityHidden(true)
            LabeledField(focused: focus == .name, caption: L10n.Onboarding.someoneNameCaption,
                         text: model.personName, cap: TextCap.name,
                         contactIssue: model.contactShown.contains(.personName)) {
                Text(L10n.Add.nameLabel)
            } field: {
                TextField(L10n.Add.nameLabel, text: $model.personName,
                          prompt: prompt(L10n.Onboarding.someoneNamePlaceholder))
                    .focused($focus, equals: .name)
                    .accessibilityLabel(L10n.Add.nameLabel)
                    .accessibilityIdentifier("onboarding.someone.name")
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .onSubmit { focus = .alias }
                    .textFieldRules(text: $model.personName, cap: TextCap.name,
                                    hasContactIssue: { model.hasContactIssue(.personName) },
                                    showContactIssue: { model.showContactIssue(.personName, $0) },
                                    onEdit: model.textChanged)
            }
            .onboardingLine(delay: OnboardingTiming.line(1))
            LabeledField(focused: focus == .alias, caption: L10n.Add.aliasCaption,
                         text: model.personAlias, cap: TextCap.alias, contactIssue: false) {
                let optional = Text(L10n.Onboarding.optional).font(PP.type.bodySmall).foregroundStyle(PP.color.inkFaint)
                Text("\(Text(L10n.Onboarding.someoneAliasLabel))\(Text(verbatim: " · ").foregroundStyle(PP.color.inkFaint))\(optional)")
            } field: {
                TextField(L10n.Add.aliasLabel, text: $model.personAlias, prompt: prompt(L10n.Add.aliasPlaceholder))
                    .focused($focus, equals: .alias)
                    .accessibilityLabel(L10n.Add.aliasLabel)
                    .accessibilityIdentifier("onboarding.someone.alias")
                    .textInputAutocapitalization(.words)
                    .submitLabel(.continue)
                    .onSubmit(model.continueToIntention)
                    .onChange(of: model.personAlias) { _, new in
                        if new.count > TextCap.alias { model.personAlias = String(new.prefix(TextCap.alias)) }
                    }
            }
            .padding(.top, PP.space.xl)
            .onboardingLine(delay: OnboardingTiming.line(2))
        }
        .onAppear { focus = .name }
    }

    private func prompt(_ placeholder: String) -> Text {
        Text(placeholder).foregroundStyle(PP.color.inkFaint)
    }
}

/// A labeled onboarding field: the label above (`onboardingFieldLabel`,
/// inkMuted), the field (`onboardingFieldLabeled`) over its hairline, and
/// the add sheet's footer below (the caption, the contact message in its
/// place, the counter near the cap).
private struct LabeledField<Label: View, Field: View>: View {
    let focused: Bool
    let caption: String
    let text: String
    let cap: Int
    let contactIssue: Bool
    @ViewBuilder let label: () -> Label
    @ViewBuilder let field: () -> Field

    var body: some View {
        VStack(alignment: .leading, spacing: PP.space.xxs) {
            label()
                .font(PP.type.onboardingFieldLabel)
                .foregroundStyle(PP.color.inkMuted)
                .accessibilityHidden(true)
            UnderlinedField(focused: focused) {
                field()
                    .font(PP.type.onboardingFieldLabeled)
                    .foregroundStyle(PP.color.ink)
            }
            FieldFooter(text: text, cap: cap, contactIssue: contactIssue, caption: caption)
                .font(PP.type.caption)
                .foregroundStyle(PP.color.inkMuted)
                .padding(.top, PP.space.xs)
        }
    }
}

/// Step 4, their intention (optional): only them. Their avatar (the stage's
/// anchor, travelled up), what you call them else their name (Roca bold),
/// "Carried on the list with you." with the carried mark, then "What are
/// you praying for, for {alias}?" (Roca), what an intention is, one centered
/// field ("e.g. Healing after surgery"). The stage's Add and Skip run one
/// save sequence (the person, then the intention as their chosen one). A
/// failed save keeps the text and says so (the add sheet's lines).
struct IntentionStep: View {
    @Bindable var model: OnboardingModel
    @FocusState private var focused: Bool

    private var notice: String? {
        if model.isOffline || model.addProblem == .offline { return L10n.Add.offline }
        switch model.addProblem {
        case .cap: return L10n.Add.capReached(subjectCap)
        case .failed: return L10n.Add.failed
        case .offline, nil: return nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(width: PP.size.onboarding.personAvatar, height: PP.size.onboarding.personAvatar)
                .stageSlot(.intentionAvatar)
                .padding(.top, PP.space.lg)
                .accessibilityHidden(true)
            VStack(spacing: PP.space.xs) {
                Text(verbatim: model.personLabel)
                    .font(PP.type.onboardingPersonName)
                    .foregroundStyle(PP.color.ink)
                    .lineLimit(2)
                    .accessibilityAddTraits(.isHeader)
                CarriedMark.after(Text(L10n.Onboarding.carriedWithYou), carried: true, context: .name)
                    .font(PP.type.bodySmall)
                    .foregroundStyle(PP.color.inkMuted)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, PP.space.sm)
            .onboardingLine(delay: PP.duration.onboardingPersonName, rise: PP.size.onboarding.textFall)
            Text(L10n.Onboarding.intentionTitle(model.personLabel))
                .font(PP.type.onboardingLeadSmall)
                .foregroundStyle(PP.color.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, PP.space.xl)
                .onboardingLine(delay: OnboardingTiming.line(0))
            Text(L10n.Onboarding.intentionLine)
                .font(PP.type.bodySmall)
                .foregroundStyle(PP.color.inkMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, PP.space.sm)
                .onboardingLine(delay: OnboardingTiming.line(1))
            if let notice {
                Text(notice)
                    .font(PP.type.body)
                    .foregroundStyle(PP.color.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, PP.space.md)
                    .accessibilityIdentifier("onboarding.intention.notice")
                    .transition(.opacity)
            }
            VStack(spacing: PP.space.xs) {
                UnderlinedField(focused: focused) { field }
                FieldFooter(text: model.intention, cap: TextCap.intention,
                            contactIssue: model.contactShown.contains(.intention))
                    .font(PP.type.caption)
                    .foregroundStyle(PP.color.inkMuted)
            }
            .padding(.top, PP.space.md)
            .onboardingLine(delay: OnboardingTiming.line(2))
        }
        .frame(maxWidth: .infinity)
        .animation(.easeOut(duration: PP.duration.quick), value: notice)
        .onAppear { focused = true }
    }

    /// The intention: grows from one line to three; no line breaks (Return
    /// adds, pasted breaks become spaces); the add sheet's rules.
    private var field: some View {
        TextField(L10n.Add.intentionLabel, text: $model.intention,
                  prompt: Text(L10n.Add.intentionPlaceholder).foregroundStyle(PP.color.inkFaint), axis: .vertical)
            .lineLimit(1...3)
            .font(PP.type.onboardingField)
            .foregroundStyle(PP.color.ink)
            .multilineTextAlignment(.center)
            .focused($focused)
            .accessibilityLabel(L10n.Add.intentionLabel)
            .accessibilityIdentifier("onboarding.intention.field")
            .textInputAutocapitalization(.sentences)
            .submitLabel(.done)
            .onChange(of: model.intention) { old, new in
                guard new.contains(where: \.isNewline) else { return }
                let typedReturn = new.count == old.count + 1 && new.filter { !$0.isNewline } == old
                if typedReturn {
                    model.intention = old
                    Task { await model.save(withIntention: true) }
                } else {
                    model.intention = String(new.map { $0.isNewline ? " " : $0 })
                }
            }
            .textFieldRules(text: $model.intention, cap: TextCap.intention,
                            hasContactIssue: { model.hasContactIssue(.intention) },
                            showContactIssue: { model.showContactIssue(.intention, $0) },
                            onEdit: model.textChanged)
    }
}

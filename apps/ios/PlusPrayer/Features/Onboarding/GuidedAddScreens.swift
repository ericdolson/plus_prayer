import PlusPrayerDomain
import SwiftUI

/// Screen 4, the guided first add: "Who's someone you pray for?", then the
/// add sheet's own fields in its order (a native `Form`, as the sheet's
/// Name tab): the avatar (initials from what you call them, else the name),
/// Name (required; "e.g. Julie Olson"; "Printed on the list") and "What you
/// call them · optional" ("e.g. Mom"; "Only you see this"). Once a name is
/// entered: "{alias} will be carried on the list with you." (carried by
/// default, no switch). Continue → the intention. Nothing is saved here.
struct SomeoneScreen: View {
    @Bindable var model: OnboardingModel
    @FocusState private var focus: Field?

    private enum Field: Hashable {
        case name, alias
    }

    var body: some View {
        Form {
            Section {
                OnboardingQuestion(text: L10n.Onboarding.someoneTitle)
            }
            Section {
                MonogramAvatar(initials: model.personInitials, tone: model.personTone, size: PP.size.avatar.person,
                               placeholder: PPIcon.person)
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets(top: PP.space.sm, leading: 0, bottom: PP.space.sm, trailing: 0))
                    .listRowBackground(Color.clear)
            }
            Section {
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
                    .listRowBackground(PP.color.raised)
            } header: {
                Text(L10n.Add.nameLabel)
            } footer: {
                FieldFooter(text: model.personName, cap: TextCap.name,
                            contactIssue: model.contactShown.contains(.personName),
                            caption: L10n.Onboarding.someoneNameCaption)
            }
            Section {
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
                    .listRowBackground(PP.color.raised)
            } header: {
                Text(L10n.Add.aliasLabel)
            } footer: {
                FieldFooter(text: model.personAlias, cap: TextCap.alias, contactIssue: false,
                            caption: L10n.Add.aliasCaption)
            }
            if model.showsCarriedLine {
                Section {
                    Text(L10n.Onboarding.carriedWithYou(model.personLabel))
                        .foregroundStyle(PP.color.ink)
                        .listRowBackground(Color.clear)
                        .accessibilityIdentifier("onboarding.someone.carried")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(PP.color.ground)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaBar(edge: .bottom) {
            OnboardingButton(title: L10n.Onboarding.someoneContinue, style: .prominent,
                             identifier: "onboarding.someone.continue", action: model.continueToIntention)
                .disabled(!model.canContinuePerson)
                .padding(.horizontal, PP.space.gutter)
                .padding(.bottom, PP.space.sm)
        }
        .onAppear { if focus == nil { focus = .name } }
    }

    private func prompt(_ placeholder: String) -> Text {
        Text(placeholder).foregroundStyle(PP.color.inkMuted)
    }
}

/// Screen 5, optional: "What are you praying for, for {alias}?", what an
/// intention is, a field ("e.g. Healing after surgery"), Add / Skip. Either
/// saves the person (carried) and, with Add, the intention as their chosen
/// one, then returns to Welcome back. A failed save keeps the text and says
/// so (the add sheet's lines); once the person is saved, ‹ goes (their
/// fields can't change from here) and Add retries only the intention.
struct IntentionScreen: View {
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
        // A plain scroll, not a Form: a Form's rows are lazy, and at the
        // largest text sizes the field (below the question) wasn't there to
        // take focus.
        ScrollView {
            VStack(alignment: .leading, spacing: PP.space.lg) {
                OnboardingQuestion(text: L10n.Onboarding.intentionTitle(model.personLabel))
                Text(L10n.Onboarding.intentionLine)
                    .font(PP.type.body)
                    .foregroundStyle(PP.color.inkMuted)
                if let notice {
                    Text(notice)
                        .font(PP.type.body)
                        .foregroundStyle(PP.color.ink)
                        .accessibilityIdentifier("onboarding.intention.notice")
                        .transition(.opacity)
                }
                VStack(alignment: .leading, spacing: PP.space.sm) {
                    field
                        .padding(PP.space.md)
                        .background(PP.color.raised, in: RoundedRectangle(cornerRadius: PP.radius.md))
                    FieldFooter(text: model.intention, cap: TextCap.intention,
                                contactIssue: model.contactShown.contains(.intention))
                        .font(PP.type.caption)
                        .foregroundStyle(PP.color.inkMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, PP.space.gutter)
            .padding(.vertical, PP.space.xl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(PP.color.ground)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(model.personLocked || model.saving)
        .animation(.easeOut(duration: PP.duration.quick), value: notice)
        .safeAreaBar(edge: .bottom) {
            VStack(spacing: PP.space.sm) {
                OnboardingButton(title: L10n.Onboarding.intentionAdd, style: .prominent, busy: model.saving,
                                 identifier: "onboarding.intention.add") { save(withIntention: true) }
                    .disabled(!model.canAddIntention)
                OnboardingButton(title: L10n.Onboarding.intentionSkip, identifier: "onboarding.intention.skip") {
                    save(withIntention: false)
                }
                .disabled(!model.canSave)
            }
            .padding(.horizontal, PP.space.gutter)
            .padding(.bottom, PP.space.sm)
        }
        .onAppear { focused = true }
    }

    /// The intention: grows from one line to three; no line breaks (Return
    /// adds, pasted breaks become spaces); the add sheet's rules.
    private var field: some View {
        TextField(L10n.Add.intentionLabel, text: $model.intention,
                  prompt: Text(L10n.Add.intentionPlaceholder).foregroundStyle(PP.color.inkMuted), axis: .vertical)
            .lineLimit(1...3)
            .focused($focused)
            .foregroundStyle(PP.color.ink)
            .accessibilityLabel(L10n.Add.intentionLabel)
            .accessibilityIdentifier("onboarding.intention.field")
            .textInputAutocapitalization(.sentences)
            .submitLabel(.done)
            .onChange(of: model.intention) { old, new in
                guard new.contains(where: \.isNewline) else { return }
                let typedReturn = new.count == old.count + 1 && new.filter { !$0.isNewline } == old
                if typedReturn {
                    model.intention = old
                    save(withIntention: true)
                } else {
                    model.intention = String(new.map { $0.isNewline ? " " : $0 })
                }
            }
            .textFieldRules(text: $model.intention, cap: TextCap.intention,
                            hasContactIssue: { model.hasContactIssue(.intention) },
                            showContactIssue: { model.showContactIssue(.intention, $0) },
                            onEdit: model.textChanged)
    }

    private func save(withIntention: Bool) {
        Task { await model.save(withIntention: withIntention) }
    }
}

/// An onboarding question at the top of a form: Large Title, sans, on the
/// ground (no row background), wrapping.
struct OnboardingQuestion: View {
    let text: String

    var body: some View {
        Text(text)
            .font(PP.type.onboardingTitle)
            .foregroundStyle(PP.color.ink)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
    }
}

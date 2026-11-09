import PlusPrayerDomain
import SwiftUI

/// Screen 3: no avatar. "Welcome, {full name}." (Roca, the full name as
/// entered), the mechanic, a divider, "Who else do you hold?" and its line,
/// then "＋ Add someone" (prominent) and "Add others later" (→ Home), and
/// the faint privacy footer. After a first add: a row of small avatars of
/// only the people added (never you), and the buttons become "＋ Add
/// another" (the regular add sheet over this screen) and Continue (→ Home).
struct WelcomeBackScreen: View {
    @Bindable var model: OnboardingModel
    @Environment(HomeModel.self) private var home
    @State private var adding: AddSheetModel?

    var body: some View {
        let added = model.added
        ScrollView {
            VStack(spacing: PP.space.lg) {
                Text(L10n.Onboarding.welcomeBack(model.greeting))
                    .font(PP.type.displayLarge)
                    .foregroundStyle(PP.color.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(L10n.Onboarding.mechanic)
                    .font(PP.type.body)
                    .foregroundStyle(PP.color.ink)
                Divider()
                    .padding(.vertical, PP.space.sm)
                Text(L10n.Onboarding.whoElse)
                    .font(PP.type.sectionTitle)
                    .foregroundStyle(PP.color.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(L10n.Onboarding.whoElseLine)
                    .font(PP.type.body)
                    .foregroundStyle(PP.color.inkMuted)
                if !added.isEmpty {
                    addedRow(added)
                        .transition(.opacity)
                }
                Text(L10n.Onboarding.privacy)
                    .font(PP.type.caption)
                    .foregroundStyle(PP.color.inkMuted)
                    .padding(.top, PP.space.xl)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, PP.space.gutter)
            .padding(.vertical, PP.space.xl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(PP.color.ground)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaBar(edge: .bottom) { buttons(hasAdded: !added.isEmpty) }
        .animation(.easeOut(duration: PP.duration.quick), value: added)
        .sheet(item: $adding) { sheet in
            AddSheet(model: sheet)
                .onDisappear { model.addedFromSheet(sheet.addedNameId) }
        }
    }

    /// The people added, small, in order. VoiceOver reads them as one line.
    private func addedRow(_ added: [PickerName]) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: PP.space.sm) {
                ForEach(added) { person in
                    MonogramAvatar(initials: person.initials, tone: person.tone, size: PP.size.avatar.small)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.Onboarding.added(ListFormatter.localizedString(byJoining: added.map(\.label))))
        .accessibilityIdentifier("onboarding.added")
    }

    private func buttons(hasAdded: Bool) -> some View {
        VStack(spacing: PP.space.sm) {
            if hasAdded {
                // Most people move on: Continue is the clear way forward
                // (decisions.md 2026-11-09, build calls).
                OnboardingButton(title: L10n.Onboarding.addAnother, icon: PPIcon.add, style: .tinted,
                                 identifier: "onboarding.back.add") {
                    adding = AddSheetModel(home: home)
                }
                OnboardingButton(title: L10n.Onboarding.backContinue, style: .prominent,
                                 identifier: "onboarding.back.continue", action: model.finish)
            } else {
                OnboardingButton(title: L10n.Onboarding.addSomeone, icon: PPIcon.add, style: .prominent,
                                 identifier: "onboarding.back.add", action: model.addSomeone)
                OnboardingButton(title: L10n.Onboarding.addLater, identifier: "onboarding.back.later",
                                 action: model.finish)
            }
        }
        .padding(.horizontal, PP.space.gutter)
        .padding(.bottom, PP.space.sm)
    }
}

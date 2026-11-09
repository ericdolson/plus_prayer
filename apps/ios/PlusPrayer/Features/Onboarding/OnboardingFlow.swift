import PlusPrayerDomain
import SwiftUI

/// First run (auth-onboarding.md, "Flow (revised 2026-11-09)"): a full-screen
/// cover over Home with one native navigation stack. Welcome is the root;
/// Name, Welcome back, Someone and the intention push, each with the system
/// ‹. One decision per screen, labeled buttons, no swipes or carousel.
/// `OnboardingModel` holds the flow; Home presents it while the account has
/// no self name, and it stays until "Add others later" or Continue.
struct OnboardingFlow: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        NavigationStack(path: $model.path) {
            WelcomeScreen(onBegin: model.begin)
                .navigationDestination(for: OnboardingModel.Screen.self) { screen in
                    switch screen {
                    case .name: NameScreen(model: model)
                    case .welcomeBack: WelcomeBackScreen(model: model)
                    case .someone: SomeoneScreen(model: model)
                    case .intention: IntentionScreen(model: model)
                    }
                }
        }
        // Chrome (‹) in ink; prominent buttons set the action blue themselves.
        .tint(PP.color.ink)
        .interactiveDismissDisabled()
    }
}

/// Screen 1: full bleed, text on the lower third, Begin. The ground and
/// the seal stand in for the photograph of the sealed list in warm low
/// light (`WelcomeBackdrop`), dark and warm in both appearances.
struct WelcomeScreen: View {
    let onBegin: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            WelcomeBackdrop()
                .ignoresSafeArea()
            // Text on the lower third; at the largest sizes it scrolls rather
            // than clip.
            ViewThatFits(in: .vertical) {
                text
                ScrollView { text }.scrollBounceBehavior(.basedOnSize)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        // The photograph is dark in both appearances: its controls are too.
        .environment(\.colorScheme, .dark)
    }

    private var text: some View {
        VStack(spacing: PP.space.lg) {
            Text(L10n.Onboarding.welcomeTitle)
                .font(PP.type.displayLarge)
                .foregroundStyle(PP.color.welcomeInk)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(L10n.Onboarding.welcomeSubtitle)
                .font(PP.type.body)
                .foregroundStyle(PP.color.welcomeInkMuted)
                .multilineTextAlignment(.center)
            OnboardingButton(title: L10n.Onboarding.begin, style: .prominent, identifier: "onboarding.begin",
                             action: onBegin)
                .padding(.top, PP.space.sm)
            // SEAM (auth-onboarding.md screen 1): the quiet "Already have an
            // account? Sign in" link goes here, under Begin, once sign-in
            // (Google / Apple linking) exists. Not shown until then.
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, PP.space.xl)
        .padding(.top, PP.space.xxxl)
        .padding(.bottom, PP.space.xl)
        .background {
            // The photograph's own fall to dark under the text.
            LinearGradient(colors: [PP.color.welcomeGround.opacity(0), PP.color.welcomeGround],
                           startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
        }
    }
}

/// SEAM: the interim Welcome graphic, the large seal on a dark, warm ground.
/// Replace the body with the photograph of the sealed list (names never
/// legible), and later a 5–8 s silent loop of the list being stitched and
/// sealed; the text and Begin sit over it unchanged.
struct WelcomeBackdrop: View {
    var body: some View {
        ZStack {
            PP.color.welcomeGround
            VStack {
                Spacer()
                WaxSeal(variant: 0, size: PP.size.seal.welcome)
                Spacer()
                Spacer()
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview("Welcome") {
    NavigationStack { WelcomeScreen(onBegin: {}) }
}

#Preview("Welcome, large type") {
    NavigationStack { WelcomeScreen(onBegin: {}) }
        .dynamicTypeSize(.accessibility5)
}

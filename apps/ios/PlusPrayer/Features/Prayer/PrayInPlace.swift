import PlusPrayerDomain
import SwiftUI
import UIKit

// Praying on a page, in place (detail-page.md "Praying on the page"): the
// pieces a name's and an intention's page share with each other and with
// Home's prayer mode. The session is the app-level `PrayerSession`; the
// halo and the PrayerSheet (invitation, closing sheet) sit on Home's
// navigation stack, so they show over a page too.

/// A page's bar in the pray-button slot. Browsing: one blue capsule,
/// "🙏 Pray for Dad" ("Pray" on the self page and an intention's). On start
/// the capsule morphs into the round pray button (countdown → Amen) and the
/// pill fades in beside it with the timer · "with N" only (no 🔎).
/// Reduce Motion: the glass fades instead of morphing.
struct PagePrayBar: View {
    let label: String
    /// Non-nil while praying.
    var prayerStartedAt: Date? = nil
    var prayingWith: Int? = nil
    let onPray: () -> Void
    let onAmen: () -> Void

    @Namespace private var glass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var height: CGFloat { PP.size.bar.height }
    private var prayID: GlassID { GlassID(id: "pray", namespace: glass) }

    var body: some View {
        GlassEffectContainer(spacing: PP.size.bar.gap) {
            HStack(spacing: PP.size.bar.gap) {
                if let prayerStartedAt {
                    PrayerTimerLine(startedAt: prayerStartedAt, prayingWith: prayingWith)
                        .padding(.horizontal, PP.space.xl)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: height)
                        .glassEffect(.regular, in: .capsule)
                        .glassEffectTransition(reduceMotion ? .materialize : .matchedGeometry)
                        .transition(.opacity)
                    PrayButton(startedAt: prayerStartedAt, diameter: height, onPray: onPray, onAmen: onAmen,
                               glassID: prayID)
                        .glassEffectTransition(reduceMotion ? .materialize : .matchedGeometry)
                } else {
                    Button(action: onPray) {
                        Label {
                            Text(verbatim: label).lineLimit(1)
                        } icon: {
                            PPIcon.pray.font(.system(size: PP.size.bar.icon, weight: .regular))
                        }
                        .font(PP.type.label)
                        .foregroundStyle(PP.color.onPrimary)
                        .padding(.horizontal, PP.space.xl)
                        .frame(minHeight: height)
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.tint(PP.color.primary).interactive(), in: .capsule)
                    .glassID(prayID)
                    .glassEffectTransition(reduceMotion ? .materialize : .matchedGeometry)
                    .accessibilityLabel(label)
                }
            }
        }
        // The capsule on the trailing (thumb) side; the space beside it is
        // empty, not part of any control.
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, PP.size.bar.inset)
        .animation(.easeOut(duration: reduceMotion ? PP.duration.quick : PP.duration.settle),
                   value: prayerStartedAt == nil)
    }
}

/// "Pray for others": a quiet text link under the intentions (under the
/// name when there are none). It leaves for Home, still praying, the
/// checks kept.
struct PrayForOthersLink: View {
    let action: () -> Void

    var body: some View {
        Button(L10n.Page.prayForOthers, action: action)
            .font(PP.type.body)
            .tint(PP.color.primary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, PP.space.gutter)
            .accessibilityIdentifier("page.prayForOthers")
    }
}

// MARK: Commands shared by Home and the pages

extension PrayerSession {
    /// The pray button's Amen: commits (Home logs it) or opens the invitation first.
    func amen(logTo home: HomeModel) {
        guard let prayer = amen(prayedWithListToday: home.prayedWithListToday) else { return }
        Task { await home.log(prayer) }
    }

    /// Cancel: at once under ~30 s, else ask first ("Discard this prayer?").
    func cancel(confirming: inout Bool) {
        if needsDiscardConfirmation(at: .now) { confirming = true } else { cancel() }
    }
}

extension View {
    /// A page's bar in the pray-button slot, as a safe-area inset: only the
    /// capsule, the pray button and the pill take taps; the empty space
    /// beside them passes them to the content underneath. Not a
    /// `safeAreaBar` (Home's): on iOS 26 that takes taps across its whole
    /// width, even with nothing but a clear, non-hit-testable spacer in it
    /// (checked by `testHistoryFromAPersonsTile`). The cost: no native soft
    /// scroll edge under the page's bar.
    func pagePrayBar<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View {
        safeAreaInset(edge: .bottom) { bar() }
    }

    /// Cancel's confirm past ~30 s (design-direction §4).
    func discardPrayerDialog(isPresented: Binding<Bool>, session: PrayerSession) -> some View {
        confirmationDialog(L10n.Prayer.discardQuestion, isPresented: isPresented, titleVisibility: .visible) {
            // Not .destructive: the system would paint it red, and +Prayer has no red.
            Button(L10n.Prayer.discard) { session.cancel() }
            Button(L10n.Prayer.keepPraying, role: .cancel) {}
        }
    }

    /// Keeps the edge swipe back working while the page hides its back
    /// button (Cancel takes ‹'s place in prayer; detail-page.md: swipe-back
    /// goes to Home like "Pray for others"). Hiding the back button turns
    /// the navigation controller's pop gesture off; while `enabled`, this
    /// page answers for the gesture instead, and hands it back after.
    func swipeBackWhileBackHidden(_ enabled: Bool) -> some View {
        background(SwipeBackEnabler(enabled: enabled).frame(width: 0, height: 0).accessibilityHidden(true))
    }
}

private struct SwipeBackEnabler: UIViewControllerRepresentable {
    let enabled: Bool

    func makeUIViewController(context: Context) -> Controller { Controller() }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.enabled = enabled
    }

    final class Controller: UIViewController, UIGestureRecognizerDelegate {
        var enabled = false { didSet { apply() } }
        /// The navigation controller whose gesture this answers for, while it does.
        private weak var navigation: UINavigationController?
        private weak var original: (any UIGestureRecognizerDelegate)?

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            apply()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            apply()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            release()
        }

        private func apply() {
            guard enabled, isViewLoaded, view.window != nil else { release(); return }
            guard navigation == nil, let navigation = navigationController,
                  let gesture = navigation.interactivePopGestureRecognizer else { return }
            self.navigation = navigation
            original = gesture.delegate
            gesture.delegate = self
        }

        private func release() {
            guard let navigation else { return }
            navigation.interactivePopGestureRecognizer?.delegate = original
            self.navigation = nil
            original = nil
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigation?.viewControllers.count ?? 0) > 1
        }
    }
}

#Preview("Page bar") {
    VStack(spacing: PP.space.xl) {
        PagePrayBar(label: "Pray for Dad", onPray: {}, onAmen: {})
        PagePrayBar(label: "Pray", prayerStartedAt: .now, prayingWith: 282, onPray: {}, onAmen: {})
        PagePrayBar(label: "Pray", prayerStartedAt: .now.addingTimeInterval(-8), prayingWith: 282,
                    onPray: {}, onAmen: {})
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(PP.color.ground)
}

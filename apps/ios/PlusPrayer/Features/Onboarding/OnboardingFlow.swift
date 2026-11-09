import PlusPrayerDomain
import SwiftUI

/// First run (auth-onboarding.md, "Flow (redesigned 2026-11-09, second
/// pass)"; the reference mock design/explorations/onboarding/d-merged): one
/// stage over Home, never pushed pages. `OnboardingModel` holds the steps
/// (name → moment → someone → intention → handoff); this view stages them.
///
/// - **Ground: Candlelight.** Home's own ground with one warm, slowly
///   breathing glow; dark in both appearances (the stage and the window take
///   the dark appearance until the hand-off).
/// - **Fixed slots.** ‹ Back top-leading (steps 2–4), one quiet text action
///   top-trailing (Not now / Skip), the one blue button at the bottom or
///   above the keyboard (never under a field).
/// - **Anchors.** The user's avatar, the person's and the user's name stay
///   on screen and travel between the slots each step lays out (an overlay
///   over the whole stage: `TravelEffect`); text groups fade and rise in and
///   out around them (`onboardingLine`; the outgoing step fades and rises).
/// - **Hand-off.** The glow goes out into Home's ground, the user's avatar
///   travels into Home's header, the person's into their row, Home fades in,
///   and the button becomes the pray button, last. Home reports those views'
///   frames and keeps them hidden until each copy lands (`HomeHandoff`,
///   `handoffAnchor(_:)`).
/// - **Reduce Motion:** every transition is a short fade; nothing travels,
///   scales or blurs; the glow is static.
struct OnboardingFlow: View {
    @Bindable var model: OnboardingModel
    let handoff: HomeHandoff

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var geometry = StageGeometry()
    /// The step the stage last entered (the choreography depends on where
    /// it came from).
    @State private var entered: OnboardingModel.Step?
    @State private var keyboardUp = false
    /// The screen's height without the keyboard (steps 1–2 sit a share of
    /// it down).
    @State private var screenHeight: CGFloat = 0
    /// The step scroll view's visible height (between the top bar and the
    /// button); step 2 centers its composition in it.
    @State private var viewportHeight: CGFloat = 0

    // Anchors
    @State private var selfTrip = Trip()
    @State private var selfProgress: Double = 0
    @State private var selfShown = false
    @State private var selfFormed = false
    @State private var personTrip = Trip()
    @State private var personProgress: Double = 0
    @State private var personShown = false
    @State private var personFormed = false
    @State private var nameTrip = Trip()
    @State private var nameProgress: Double = 0
    @State private var nameShown = false
    /// 0: the field's sans; 1: Roca bold.
    @State private var nameFace: Double = 0
    @State private var nameOnPaper = false
    /// Anchors in flight (unclipped while travelling).
    @State private var flying: Set<Anchor> = []

    // The hand-off
    @State private var groundShown = true
    @State private var buttonTrip = Trip()
    @State private var buttonProgress: Double = 0
    @State private var buttonCopy = false
    @State private var buttonLabelShown = true
    @State private var glyphShown = false

    private enum Anchor: Hashable {
        case me, person, name, button
    }

    var body: some View {
        ZStack {
            CandlelightGround(shown: groundShown)
                .ignoresSafeArea()
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { screenHeight = $0 }
            VStack(spacing: 0) {
                topBar
                content
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { button }
        }
        .overlay { anchors }
        .environment(geometry)
        .environment(\.colorScheme, .dark)
        // The status bar and keyboard follow the dark ground until the hand-off.
        .preferredColorScheme(model.step == .handoff ? nil : .dark)
        .accessibilityElement(children: .contain)
        .task(id: model.step) { await enter(model.step) }
        .task {
            for await _ in NotificationCenter.default.notifications(named: UIResponder.keyboardWillShowNotification) {
                keyboardUp = true
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: UIResponder.keyboardWillHideNotification) {
                keyboardUp = false
            }
        }
        .onChange(of: model.hasPerson) { _, has in
            guard model.step == .someone else { return }
            personAppears(has, forming: true)
        }
    }

    // MARK: Slots

    /// ‹ Back, the user's avatar between the corners on the person step (a
    /// slot), the quiet action. The corners keep the text sizes native bars
    /// do (larger sizes use the large content viewer).
    private var topBar: some View {
        ZStack {
            HStack(spacing: PP.space.sm) {
                if model.canGoBack {
                    Button(action: back) {
                        HStack(spacing: PP.space.xxs) {
                            PPIcon.back.fontWeight(.semibold)
                            Text(L10n.Onboarding.back)
                        }
                        .frame(minHeight: PP.size.hitTarget)
                        .contentShape(Rectangle())
                    }
                    .foregroundStyle(PP.color.ink)
                    .accessibilityLabel(L10n.Onboarding.back)
                    .accessibilityIdentifier("onboarding.back")
                    .transition(.opacity)
                }
                Spacer(minLength: PP.size.avatar.header)
                if let quiet = quietAction {
                    Button(quiet.title, action: quiet.action)
                        .foregroundStyle(PP.color.inkMuted)
                        .frame(minHeight: PP.size.hitTarget)
                        .disabled(!quiet.enabled)
                        .accessibilityIdentifier(quiet.identifier)
                        .id(quiet.identifier)
                        .transition(.opacity)
                }
                // SEAM (auth-onboarding.md step 1): "Sign in" sits in this
                // slot on the name step (a native sheet: Continue with Apple
                // / Continue with Google / Not now; a new account prefills
                // the name, an existing one skips onboarding) once sign-in
                // exists. Empty until then.
            }
            .font(PP.type.body)
            .buttonStyle(.plain)
            .lineLimit(1)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .accessibilityShowsLargeContentViewer()
            Color.clear
                .frame(width: PP.size.avatar.header, height: PP.size.avatar.header)
                .stageSlot(.topAvatar)
                .accessibilityHidden(true)
        }
        .frame(minHeight: PP.size.hitTarget)
        .padding(.leading, PP.space.sm)
        .padding(.trailing, PP.space.lg)
        .animation(.easeOut(duration: PP.duration.quick), value: model.step)
        .animation(.easeOut(duration: PP.duration.quick), value: model.canGoBack)
    }

    private struct QuietAction {
        let title: String
        let identifier: String
        let enabled: Bool
        let action: () -> Void
    }

    private var quietAction: QuietAction? {
        switch model.step {
        case .someone:
            QuietAction(title: L10n.Onboarding.notNow, identifier: "onboarding.notNow", enabled: true,
                        action: model.notNow)
        case .intention:
            QuietAction(title: L10n.Onboarding.skip, identifier: "onboarding.skip", enabled: model.canSave) {
                Task { await model.save(withIntention: false) }
            }
        case .name, .moment, .handoff:
            nil
        }
    }

    /// The step's text, in one scroll view per step (each starts at the
    /// top); the outgoing one fades and rises.
    private var content: some View {
        ZStack {
            ScrollView {
                step(model.step)
                    .padding(.horizontal, PP.space.xxl)
                    .padding(.bottom, PP.space.xl)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.containerSize.height - $0.contentInsets.top - $0.contentInsets.bottom
            } action: { _, height in
                viewportHeight = height
            }
            .stageSlot(.viewport)
            .id(model.step)
            .transition(.asymmetric(insertion: .identity, removal: stepRemoval))
        }
        .animation(.easeIn(duration: reduceMotion ? PP.duration.quick : PP.duration.onboardingTextOut),
                   value: model.step)
    }

    private var stepRemoval: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .offset(y: -PP.size.onboarding.textFall))
    }

    @ViewBuilder private func step(_ step: OnboardingModel.Step) -> some View {
        let top = max(PP.space.xl, screenHeight * PP.number.onboarding.leadTop)
        switch step {
        case .name: NameStep(model: model, top: top)
        case .moment: MomentStep(model: model, top: top, fill: max(0, viewportHeight - PP.space.xl),
                                 fromName: entered != .someone)
        case .someone: SomeoneStep(model: model)
        case .intention: IntentionStep(model: model)
        case .handoff: Color.clear
        }
    }

    /// The one blue button: at the bottom, or above the keyboard. Hidden in
    /// the hand-off, where its copy becomes the pray button.
    private var button: some View {
        let spec = buttonSpec
        return OnboardingButton(title: spec.title, enabled: spec.enabled, busy: spec.busy,
                                identifier: spec.identifier, action: spec.action)
            .padding(.horizontal, PP.space.gutter)
            .padding(.bottom, keyboardUp ? PP.size.onboarding.buttonAboveKeyboard : PP.size.onboarding.buttonRest)
            .stageSlot(.button)
            .opacity(buttonCopy || model.step == .handoff ? 0 : 1)
            .allowsHitTesting(model.step != .handoff)
            .accessibilityHidden(model.step == .handoff)
            .animation(.easeOut(duration: PP.duration.settle), value: keyboardUp)
    }

    private struct ButtonSpec {
        let title: String
        var enabled = true
        var busy = false
        let identifier: String
        let action: () -> Void
    }

    private var buttonSpec: ButtonSpec {
        switch model.step {
        case .name:
            ButtonSpec(title: L10n.Onboarding.continueLabel, enabled: model.canContinueName, busy: model.savingName,
                       identifier: "onboarding.name.continue") { Task { await model.submitName() } }
        case .moment:
            ButtonSpec(title: L10n.Onboarding.continueLabel, identifier: "onboarding.moment.continue",
                       action: model.continueFromMoment)
        case .someone:
            ButtonSpec(title: L10n.Onboarding.continueLabel, enabled: model.canContinuePerson,
                       identifier: "onboarding.someone.continue", action: model.continueToIntention)
        case .intention:
            ButtonSpec(title: L10n.Onboarding.add, enabled: model.canAddIntention, busy: model.saving,
                       identifier: "onboarding.intention.add") { Task { await model.save(withIntention: true) } }
        case .handoff:
            ButtonSpec(title: model.addedPersonId == nil ? L10n.Onboarding.continueLabel : L10n.Onboarding.add,
                       identifier: "onboarding.handoff", action: {})
        }
    }

    private func back() { model.back() }

    // MARK: Anchors

    /// The travelling anchors, over everything (full screen, in global
    /// coordinates less the layer's origin).
    private var anchors: some View {
        ZStack {
            selfAnchor
            personAnchor
            nameAnchor
            buttonAnchor
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onGeometryChange(for: CGPoint.self) { $0.frame(in: .global).origin } action: { geometry.origin = $0 }
        .ignoresSafeArea()
    }

    /// A target's frame in the anchors layer.
    private func rect(_ target: StageTarget?) -> CGRect? { globalFrame(target).map(geometry.local) }

    /// Clip an anchor resting in the scrolling content to its visible part.
    private func clip(_ trip: Trip, _ anchor: Anchor) -> CGRect? {
        guard !flying.contains(anchor), case .slot(let slot) = trip.target,
              slot != .topAvatar, slot != .button else { return nil }
        return geometry.local(.viewport)
    }

    @ViewBuilder private var selfAnchor: some View {
        if let to = rect(selfTrip.target) {
            MonogramAvatar(initials: model.nameInitials, tone: model.selfTone, size: to.width)
                .formed(selfFormed, reduceMotion: reduceMotion)
                .opacity(selfShown && selfFormed ? 1 : 0)
                .modifier(TravelEffect(progress: selfProgress, base: selfTrip.base,
                                       from: selfTrip.from.map(geometry.local), to: to, mode: .scale))
                .modifier(ViewportMask(clip: clip(selfTrip, .me)))
        }
    }

    @ViewBuilder private var personAnchor: some View {
        if let to = rect(personTrip.target) {
            MonogramAvatar(initials: model.personInitials, tone: model.personTone, size: to.width)
                .formed(personFormed, reduceMotion: reduceMotion)
                .opacity(personShown && personFormed ? 1 : 0)
                .modifier(TravelEffect(progress: personProgress, base: personTrip.base,
                                       from: personTrip.from.map(geometry.local), to: to, mode: .scale))
                .modifier(ViewportMask(clip: clip(personTrip, .person)))
        }
    }

    /// The user's name: the field's sans becoming Roca bold, then smaller and
    /// in the paper's ink on the paper line.
    @ViewBuilder private var nameAnchor: some View {
        if let to = rect(nameTrip.target) {
            let scale = nameOnPaper ? PP.number.onboarding.paperNameScale : 1
            ZStack {
                Text(verbatim: model.displayName)
                    .font(PP.type.onboardingField)
                    .foregroundStyle(PP.color.ink)
                    .opacity(1 - nameFace)
                Text(verbatim: model.displayName)
                    .font(PP.type.onboardingName)
                    .foregroundStyle(nameOnPaper ? PP.color.onboardingPaperInk : PP.color.ink)
                    .opacity(nameFace)
            }
            .lineLimit(1)
            .minimumScaleFactor(PP.number.onboarding.paperNameScale)
            .frame(width: to.width / scale)
            .scaleEffect(scale)
            .opacity(nameShown ? 1 : 0)
            .modifier(TravelEffect(progress: nameProgress, base: nameTrip.base,
                                   from: nameTrip.from.map(geometry.local), to: to, mode: .move))
            .modifier(ViewportMask(clip: clip(nameTrip, .name)))
        }
    }

    /// The hand-off's copy of the button, becoming the pray button.
    @ViewBuilder private var buttonAnchor: some View {
        if buttonCopy, let to = rect(buttonTrip.target) {
            ZStack {
                Text(buttonSpec.title)
                    .font(PP.type.onboardingButton)
                    .foregroundStyle(PP.color.onPrimary)
                    .lineLimit(1)
                    .opacity(buttonLabelShown ? 1 : 0)
                PPIcon.pray
                    .font(.system(size: PP.size.bar.icon, weight: .regular))
                    .foregroundStyle(PP.color.onPrimary)
                    .opacity(glyphShown ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect(.regular.tint(PP.color.primary), in: .capsule)
            .modifier(TravelEffect(progress: buttonProgress, base: buttonTrip.base,
                                   from: buttonTrip.from.map(geometry.local), to: to, mode: .resize))
        }
    }

    // MARK: Choreography

    /// A beat `t` seconds in (Reduce Motion: never longer than a short beat).
    private func beat(_ t: TimeInterval) -> TimeInterval {
        reduceMotion ? min(t, PP.duration.onboardingReduceMotionBeat) : t
    }

    private func wait(_ t: TimeInterval) async -> Bool {
        try? await Task.sleep(for: .seconds(beat(t)))
        return !Task.isCancelled
    }

    private var fade: Animation { .easeOut(duration: reduceMotion ? PP.duration.quick : PP.duration.settle) }

    /// Sends an anchor to `target`: travelling (Reduce Motion: it simply
    /// shows there; its own fade covers the change).
    private func travel(_ anchor: Anchor, to target: StageTarget,
                        duration: TimeInterval = PP.duration.onboardingTravel) {
        var trip = trip(anchor)
        let progress = progress(anchor)
        if reduceMotion {
            trip.jump(to: target, progress: progress)
            setTrip(anchor, trip)
            return
        }
        trip.leave(from: globalFrame(trip.target), to: target, progress: progress)
        setTrip(anchor, trip)
        flying.insert(anchor)
        withAnimation(PP.easing.inOut(duration)) {
            setProgress(anchor, progress + 1)
        } completion: {
            flying.remove(anchor)
        }
    }

    /// Sends an anchor to `target` at once.
    private func jump(_ anchor: Anchor, to target: StageTarget?) {
        var trip = trip(anchor)
        trip.jump(to: target, progress: progress(anchor))
        setTrip(anchor, trip)
    }

    private func trip(_ anchor: Anchor) -> Trip {
        switch anchor {
        case .me: selfTrip
        case .person: personTrip
        case .name: nameTrip
        case .button: buttonTrip
        }
    }

    private func setTrip(_ anchor: Anchor, _ trip: Trip) {
        switch anchor {
        case .me: selfTrip = trip
        case .person: personTrip = trip
        case .name: nameTrip = trip
        case .button: buttonTrip = trip
        }
    }

    private func progress(_ anchor: Anchor) -> Double {
        switch anchor {
        case .me: selfProgress
        case .person: personProgress
        case .name: nameProgress
        case .button: buttonProgress
        }
    }

    private func setProgress(_ anchor: Anchor, _ value: Double) {
        switch anchor {
        case .me: selfProgress = value
        case .person: personProgress = value
        case .name: nameProgress = value
        case .button: buttonProgress = value
        }
    }

    /// A target's frame in global coordinates (trips keep global frames, like
    /// the slots and Home's anchors).
    private func globalFrame(_ target: StageTarget?) -> CGRect? {
        switch target {
        case .slot(let slot): geometry.frames[slot]
        case .home(let anchor): handoff.frames[anchor]
        case nil: nil
        }
    }

    private func enter(_ step: OnboardingModel.Step) async {
        let from = entered
        entered = step
        switch step {
        case .name: enterName()
        case .moment: await enterMoment(from: from)
        case .someone: enterSomeone(from: from)
        case .intention: enterIntention()
        case .handoff: await enterHandoff(from: from)
        }
    }

    private func enterName() {
        withAnimation(fade) {
            selfShown = false
            nameShown = false
            personShown = false
        }
        selfFormed = false
    }

    private func enterMoment(from: OnboardingModel.Step?) async {
        withAnimation(fade) { personShown = false }
        if from == .someone {
            // Back: the avatar travels down again; the name returns on the paper.
            travel(.me, to: .slot(.momentAvatar))
            jump(.name, to: .slot(.nameOnPaper))
            nameFace = 1
            nameOnPaper = true
            guard await wait(PP.duration.onboardingReturnPaper) else { return }
            withAnimation(fade) { nameShown = true }
            return
        }
        // The moment. The name takes over from the field's text, where it was.
        nameFace = 0
        nameOnPaper = false
        jump(.name, to: .slot(.nameField))
        nameShown = true
        travel(.name, to: .slot(.nameAbove))
        jump(.me, to: .slot(.momentAvatar))
        selfFormed = false
        selfShown = true
        withAnimation(.easeInOut(duration: reduceMotion ? PP.duration.quick : PP.duration.settle)) { nameFace = 1 }
        guard await wait(PP.duration.onboardingMomentAvatar) else { return }
        withAnimation(reduceMotion ? .easeOut(duration: PP.duration.quick)
                                   : PP.easing.out(PP.duration.onboardingForm)) { selfFormed = true }
        guard await wait(PP.duration.onboardingMomentName - PP.duration.onboardingMomentAvatar) else { return }
        // The name settles onto the paper line.
        if reduceMotion {
            withAnimation(.easeOut(duration: PP.duration.quick)) { nameShown = false }
            jump(.name, to: .slot(.nameOnPaper))
            nameOnPaper = true
            withAnimation(.easeOut(duration: PP.duration.quick)) { nameShown = true }
        } else {
            travel(.name, to: .slot(.nameOnPaper))
            withAnimation(PP.easing.inOut(PP.duration.onboardingTravel)) { nameOnPaper = true }
        }
    }

    private func enterSomeone(from: OnboardingModel.Step?) {
        withAnimation(fade) { nameShown = false }
        if from == .intention {
            // Back: you appear again in the top bar; they travel back down.
            jump(.me, to: .slot(.topAvatar))
            selfFormed = true
            withAnimation(fade) { selfShown = true }
            travel(.person, to: .slot(.someoneAvatar))
        } else {
            selfFormed = true
            selfShown = true
            travel(.me, to: .slot(.topAvatar))
            jump(.person, to: .slot(.someoneAvatar))
            personAppears(model.hasPerson, forming: false)
        }
    }

    private func enterIntention() {
        withAnimation(fade) { selfShown = false }
        personFormed = true
        personShown = true
        travel(.person, to: .slot(.intentionAvatar))
    }

    /// The person's avatar forms with the first letter of their name and
    /// goes when it's cleared.
    private func personAppears(_ has: Bool, forming: Bool) {
        if has {
            guard !personShown else { return }
            personFormed = !forming
            personShown = true
            if forming {
                withAnimation(reduceMotion ? .easeOut(duration: PP.duration.quick)
                                           : PP.easing.out(PP.duration.onboardingForm)) { personFormed = true }
            }
        } else {
            withAnimation(fade) { personShown = false }
        }
    }

    /// The hand-off (auth-onboarding.md step 5): waits for Home to show the
    /// new rows, then the glow goes out, the avatars travel into Home's
    /// header and the person's row, Home fades in, and the button becomes the
    /// pray button, last. Each copy hands over to Home's own view as it lands.
    private func enterHandoff(from: OnboardingModel.Step?) async {
        let personId = model.addedPersonId
        var landing: Set<HandoffAnchor> = [.selfAvatar, .prayButton]
        if let personId { landing.insert(.avatar(personId)) }
        handoff.hidden = landing
        withAnimation(fade) { nameShown = false }

        // Home lays out the new rows (a moment on a real backend).
        let deadline = Date.now.addingTimeInterval(PP.duration.onboardingHandoffWait)
        while !landing.isSubset(of: Set(handoff.frames.keys)), Date.now < deadline {
            try? await Task.sleep(for: .seconds(PP.duration.onboardingStagger))
            if Task.isCancelled { return }
        }

        if reduceMotion {
            withAnimation(.easeOut(duration: PP.duration.quick)) {
                groundShown = false
                selfShown = false
                personShown = false
                handoff.hidden = []
                handoff.homeShown = true
            }
            guard await wait(PP.duration.quick) else { return }
            model.finish()
            return
        }

        withAnimation(PP.easing.inOut(PP.duration.calm)) { groundShown = false }
        // You: into the header (travelling from the top bar, else appearing there).
        if selfShown && from == .someone {
            travel(.me, to: .home(.selfAvatar))
        } else {
            jump(.me, to: .home(.selfAvatar))
            selfFormed = true
            withAnimation(fade) { selfShown = true }
        }
        // The button's copy takes over where the button is.
        jump(.button, to: .slot(.button))
        buttonLabelShown = true
        glyphShown = false
        buttonCopy = true

        guard await wait(PP.duration.onboardingHandoffPerson) else { return }
        if let personId, personShown, handoff.frames[.avatar(personId)] != nil {
            travel(.person, to: .home(.avatar(personId)))
        } else {
            withAnimation(fade) { personShown = false }
        }

        guard await wait(PP.duration.onboardingHandoffHome - PP.duration.onboardingHandoffPerson) else { return }
        withAnimation(fade) { handoff.homeShown = true }

        guard await wait(PP.duration.onboardingTravel - PP.duration.onboardingHandoffHome) else { return }
        land(.selfAvatar) { selfShown = false }

        guard await wait(PP.duration.onboardingHandoffPray - PP.duration.onboardingTravel) else { return }
        if handoff.frames[.prayButton] != nil {
            travel(.button, to: .home(.prayButton), duration: PP.duration.onboardingButtonMorph)
        }
        withAnimation(.easeOut(duration: PP.duration.quick)) { buttonLabelShown = false }

        guard await wait(PP.duration.onboardingHandoffPerson + PP.duration.onboardingTravel
                         - PP.duration.onboardingHandoffPray) else { return }
        if let personId { land(.avatar(personId)) { personShown = false } }

        guard await wait(PP.duration.onboardingHandoffGlyph - PP.duration.onboardingHandoffPerson
                         - PP.duration.onboardingTravel) else { return }
        withAnimation(fade) { glyphShown = true }

        guard await wait(PP.duration.onboardingHandoffPray + PP.duration.onboardingButtonMorph
                         - PP.duration.onboardingHandoffGlyph) else { return }
        land(.prayButton) { buttonCopy = false }
        handoff.hidden = []
        guard await wait(PP.duration.quick) else { return }
        model.finish()
    }

    /// A copy has landed: Home's own view shows, the copy goes.
    private func land(_ anchor: HandoffAnchor, hideCopy: () -> Void) {
        withAnimation(.easeOut(duration: PP.duration.quick)) {
            handoff.hidden.remove(anchor)
            hideCopy()
        }
    }
}

/// Onboarding's ground (Candlelight): Home's ground with one soft, warm
/// glow behind the content, breathing slowly (Reduce Motion: static). It
/// goes out in the hand-off, leaving Home's own ground.
struct CandlelightGround: View {
    var shown = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathIn = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let glow = PP.number.onboarding.self
            EllipticalGradient(stops: [
                .init(color: PP.color.onboardingGlow, location: 0),
                .init(color: PP.color.onboardingGlow.opacity(glow.glowMid), location: glow.glowMidStop),
                .init(color: PP.color.onboardingGlow.opacity(0), location: glow.glowEndStop),
            ])
            .frame(width: size.width * glow.glowWidth * 2, height: size.height * glow.glowHeight * 2)
            .position(x: size.width / 2, y: size.height * glow.glowCenterY)
            .offset(y: breathIn && !reduceMotion ? -PP.size.onboarding.glowDrift : 0)
            .opacity(reduceMotion ? glow.glowReduceMotion : (breathIn ? 1 : glow.glowRestLow))
        }
        .background(PP.color.ground)
        .opacity(shown ? 1 : 0)
        .accessibilityHidden(true)
        .onAppear { breathe() }
        .onChange(of: reduceMotion) { breathe() }
    }

    private func breathe() {
        guard !reduceMotion else {
            breathIn = false
            return
        }
        withAnimation(PP.easing.inOut(PP.duration.onboardingGlowBreath).repeatForever(autoreverses: true)) {
            breathIn = true
        }
    }
}

private extension View {
    /// An avatar forming: from faint, small and blurred to settled (Reduce
    /// Motion: opacity only, set by the caller).
    func formed(_ formed: Bool, reduceMotion: Bool) -> some View {
        scaleEffect(formed || reduceMotion ? 1 : PP.number.onboarding.formScale)
            .blur(radius: formed || reduceMotion ? 0 : PP.size.onboarding.formBlur)
    }
}

#Preview("Onboarding, light appearance") {
    let home = HomeModel(environment: .mock(MockBackend(seed: .fresh(now: .now), latency: .zero, liveDrift: false)))
    return OnboardingFlow(model: OnboardingModel(home: home), handoff: HomeHandoff())
        .environment(home)
        .preferredColorScheme(.light)
}

#Preview("Onboarding, large type") {
    let home = HomeModel(environment: .mock(MockBackend(seed: .fresh(now: .now), latency: .zero, liveDrift: false)))
    return OnboardingFlow(model: OnboardingModel(home: home), handoff: HomeHandoff())
        .environment(home)
        .dynamicTypeSize(.accessibility3)
}

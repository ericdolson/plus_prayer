import PlusPrayerDomain
import SwiftUI

/// The add sheet (screens.md, "Add sheet" and its Details): one native sheet,
/// buttons in its toolbar, a native segmented control for Name | Intention.
///
/// Keyboard: every text field stays in the hierarchy (the hidden tab and the
/// next step are only moved or faded), so focus moves from one field to the
/// next in the same transaction and the keyboard never hides and reappears.
/// The sheet keeps one height, the tallest it has been (the name form), and
/// the offer step pushes in from the trailing edge.
struct AddSheet: View {
    @State var model: AddSheetModel
    /// Where the pool-full links go; nil until those screens exist (hidden).
    var onSeeMembership: (() -> Void)? = nil
    var onYourPortion: (() -> Void)? = nil

    @Environment(HomeModel.self) private var home
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focus: AddSheetModel.Field?
    @State private var width: CGFloat = 0

    private var onForm: Bool { model.step == .form }

    /// The one line at the top: no connection, the ~500 cap, or anything
    /// else that went wrong. Text is kept.
    private var notice: String? {
        if model.isOffline { return L10n.Add.offline }
        if model.isAtCap { return L10n.Add.capReached(subjectCap) }
        if model.failedGenerically { return L10n.Add.failed }
        return nil
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: PP.space.md) {
                if let notice {
                    Text(notice)
                        .font(PP.type.caption)
                        .foregroundStyle(PP.color.inkMuted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                }
                ZStack(alignment: .topLeading) {
                    formPage
                        .offset(x: onForm ? 0 : -width)
                        .opacity(onForm ? 1 : 0)
                        .allowsHitTesting(onForm)
                        .accessibilityHidden(!onForm)
                    stepPage
                        .offset(x: onForm ? width : 0)
                        .opacity(onForm ? 0 : 1)
                        .allowsHitTesting(!onForm)
                        .accessibilityHidden(onForm)
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
            }
            .padding(.horizontal, PP.space.xl)
            .padding(.top, PP.space.md)
            .padding(.bottom, PP.space.xl)
            .animation(reduceMotion ? .easeOut(duration: PP.duration.quick) : .easeInOut(duration: PP.duration.settle),
                       value: model.step)
            .animation(.easeOut(duration: PP.duration.quick), value: notice)
            .toolbar { toolbar }
            .navigationBarTitleDisplayMode(.inline)
            .fittedSheetHeight()
        }
        .tint(PP.color.ink)
        .onAppear { focus = model.activeField }
        .onChange(of: model.isFinished) { _, finished in if finished { dismiss() } }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        switch model.step {
        case .form:
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.Add.cancel) { model.finish() }
            }
            ToolbarItem(placement: .principal) {
                Picker(selection: tabBinding) {
                    Text(L10n.Add.tabName).tag(AddSheetModel.Tab.name)
                    Text(L10n.Add.tabIntention).tag(AddSheetModel.Tab.intention)
                } label: {
                    EmptyView()
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
            ToolbarItem(placement: .confirmationAction) { addButton }
        case .offer, .savedPrivately(_, .soul, _):
            // No back: the name is already saved.
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.Add.notNow) { model.finish() }
            }
            ToolbarItem(placement: .confirmationAction) { addButton }
        case .savedPrivately:
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.Common.done) { model.finish() }
            }
        }
    }

    private var addButton: some View {
        Button(L10n.Add.add) { save() }
            .tint(PP.color.primary)
            .disabled(!model.canAdd)
    }

    /// Switching tabs moves focus to the new tab's field in the same
    /// transaction, so the keyboard stays up.
    private var tabBinding: Binding<AddSheetModel.Tab> {
        Binding(get: { model.tab }, set: { tab in
            model.tab = tab
            focus = tab == .name ? .name : .intention
        })
    }

    private func save() {
        Task {
            await model.add()
            // The next step's field takes focus as the step changes; with
            // nothing to type next (an intention saved privately), let go.
            switch model.step {
            case .offer, .savedPrivately(_, .soul, _): focus = .offer
            case .savedPrivately: focus = nil
            case .form: break
            }
        }
    }

    // MARK: The form (Name | Intention)

    private var formPage: some View {
        ZStack(alignment: .top) {
            nameForm
                .opacity(model.tab == .name ? 1 : 0)
                .allowsHitTesting(model.tab == .name)
                .accessibilityHidden(model.tab != .name)
            intentionForm
                .opacity(model.tab == .intention ? 1 : 0)
                .allowsHitTesting(model.tab == .intention)
                .accessibilityHidden(model.tab != .intention)
        }
    }

    private var nameForm: some View {
        VStack(spacing: PP.space.lg) {
            // A preview only in v1: its tone from the start, initials live by
            // Home's rule.
            MonogramAvatar(initials: model.previewInitials, tone: model.tone, size: PP.size.avatar.large)
                .accessibilityHidden(true)
            field(.name, text: $model.name, placeholder: L10n.Add.namePlaceholder, caption: L10n.Add.nameCaption)
                .onSubmit { focus = .alias }
                .submitLabel(.next)
            field(.alias, text: $model.alias, placeholder: L10n.Add.aliasPlaceholder, caption: L10n.Add.aliasCaption)
                .onSubmit(save)
                .submitLabel(.done)
        }
    }

    private var intentionForm: some View {
        VStack(alignment: .leading, spacing: PP.space.md) {
            namePicker
            field(.intention, text: $model.intention, placeholder: L10n.Add.intentionPlaceholder,
                  caption: L10n.Add.intentionCaption)
                .onSubmit(save)
                .submitLabel(.done)
        }
    }

    /// "For ( M ) Me": a native menu over the sheet; it doesn't take focus
    /// from the field. Items: a small monogram and the alias, Home order, Me
    /// first. (No search in v1: open-questions D5.)
    private var namePicker: some View {
        Menu {
            Picker(selection: $model.parentId) {
                ForEach(home.pickerNames) { name in
                    Label { Text(name.label) } icon: { MonogramImage(name: name) }
                        .tag(name.id)
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)
        } label: {
            HStack(spacing: PP.space.xs) {
                Text(L10n.Add.forLabel).foregroundStyle(PP.color.inkMuted)
                if let parent = model.parent {
                    MonogramAvatar(initials: parent.initials, tone: parent.tone, size: PP.size.avatar.tiny)
                    Text(parent.label).foregroundStyle(PP.color.ink)
                }
                PPIcon.chooser
                    .imageScale(.small)
                    .foregroundStyle(PP.color.inkMuted)
            }
            .font(PP.type.bodySmall)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(L10n.Add.forLabel)
        .accessibilityValue(model.parent?.label ?? "")
    }

    // MARK: The next step

    @ViewBuilder private var stepPage: some View {
        VStack(alignment: .leading, spacing: PP.space.md) {
            switch model.step {
            case .form, .offer:
                Text(L10n.Add.onList(model.offerName))
                    .font(PP.type.displayLine)
                    .foregroundStyle(PP.color.ink)
                offer
            case .savedPrivately(_, let kind, let invitation):
                // "Dad is saved for your own prayers. All 10 places on the
                // list are in use." (free: "Your free place …"; an
                // intention is never quoted).
                VStack(alignment: .leading, spacing: PP.space.xxs) {
                    Text(kind == .intention ? L10n.Add.savedIntention : L10n.Add.savedPrivately(model.offerName))
                        .foregroundStyle(PP.color.ink)
                    Text(model.isFreePool ? L10n.Add.freePlace : L10n.Add.poolFull(model.poolLimit))
                        .foregroundStyle(PP.color.inkMuted)
                }
                .font(PP.type.body)
                invitationView(invitation)
                if kind == .soul { offer }
            }
        }
    }

    /// The one intention offered for the name just saved.
    private var offer: some View {
        VStack(alignment: .leading, spacing: PP.space.md) {
            Text(L10n.Add.offerQuestion(model.offerName))
                .font(PP.type.bodySmall)
                .foregroundStyle(PP.color.inkMuted)
            field(.offer, text: $model.offerText, placeholder: L10n.Add.intentionPlaceholder, caption: nil)
                .onSubmit(save)
                .submitLabel(.done)
        }
    }

    /// Under the pool-full line (PROPOSED cadence, Q31). Membership and Your
    /// portion stay hidden until their screens exist (the model only offers
    /// membership when it's available).
    @ViewBuilder private func invitationView(_ invitation: PoolFullInvitation) -> some View {
        switch invitation {
        case .membership(let premiumPool):
            if let onSeeMembership {
                VStack(alignment: .leading, spacing: PP.space.sm) {
                    Text(L10n.Add.membership(premiumPool))
                        .font(PP.type.bodySmall)
                        .foregroundStyle(PP.color.inkMuted)
                    Button(L10n.Add.seeMembership, action: onSeeMembership)
                        .buttonStyle(.glassProminent)
                        .tint(PP.color.primary)
                }
            }
        case .portionLink:
            if let onYourPortion {
                Button(L10n.Add.yourPortion, action: onYourPortion)
                    .font(PP.type.bodySmall)
                    .tint(PP.color.primary)
            }
        }
    }

    // MARK: A field

    /// A native text field with its muted caption below. Caps stop input; a
    /// muted "34/40" counter shows in the last 10 characters. Contact info
    /// shows its message in place of the caption once typing pauses.
    private func field(_ field: AddSheetModel.Field, text: Binding<String>, placeholder: String,
                       caption: String?) -> some View {
        let cap = AddSheetModel.cap(field)
        let count = text.wrappedValue.count
        let issue = model.contactShown.contains(field)
        return VStack(alignment: .leading, spacing: PP.space.xs) {
            TextField(placeholder, text: text)
                .focused($focus, equals: field)
                .font(PP.type.body)
                .foregroundStyle(PP.color.ink)
                .textInputAutocapitalization(field == .name || field == .alias ? .words : .sentences)
                .padding(PP.space.md)
                .background(PP.color.raised, in: RoundedRectangle(cornerRadius: PP.radius.md))
                .onChange(of: text.wrappedValue) { _, new in
                    if new.count > cap { text.wrappedValue = String(new.prefix(cap)) }
                    model.textChanged()
                }
                .task(id: text.wrappedValue) {
                    // Clears at once when fixed; shows after typing pauses.
                    guard model.hasContactIssue(field) else {
                        model.showContactIssue(field, false)
                        return
                    }
                    try? await Task.sleep(for: .seconds(PP.duration.validationPause))
                    if !Task.isCancelled { model.showContactIssue(field, true) }
                }
            HStack(alignment: .firstTextBaseline, spacing: PP.space.sm) {
                if issue {
                    Text(L10n.Add.contactError).foregroundStyle(PP.color.ink)
                } else if let caption {
                    Text(caption).foregroundStyle(PP.color.inkMuted)
                }
                Spacer(minLength: 0)
                if count >= cap - 10 {
                    Text(L10n.Add.counter(count, cap))
                        .foregroundStyle(PP.color.inkMuted)
                        .monospacedDigit()
                }
            }
            .font(PP.type.caption)
            .padding(.horizontal, PP.space.md)
        }
    }
}

/// A small monogram as an image, for native menu items (they take images,
/// not views).
private struct MonogramImage: View {
    let name: PickerName
    @Environment(\.displayScale) private var scale

    var body: some View {
        let renderer = ImageRenderer(content: MonogramAvatar(initials: name.initials, tone: name.tone,
                                                             size: PP.size.avatar.tiny))
        renderer.scale = scale
        return Group {
            if let image = renderer.uiImage {
                Image(uiImage: image).renderingMode(.original)
            }
        }
    }
}

// MARK: Sheet height

extension View {
    /// A sheet as tall as the tallest its content has been (one height for
    /// both tabs and the next step), measured inside a NavigationStack so the
    /// bar is included.
    func fittedSheetHeight() -> some View { modifier(FittedSheetHeight()) }
}

private struct FittedSheetHeight: ViewModifier {
    @State private var content: CGFloat = 0
    @State private var bar: CGFloat = 0

    func body(content view: Content) -> some View {
        view
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { content = max(content, $0) }
            .frame(maxHeight: .infinity, alignment: .top)
            .background {
                // Reaches under the bar, so its top inset is the bar's height.
                Color.clear
                    .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { bar = $0 }
                    .ignoresSafeArea(.container, edges: .top)
            }
            .presentationDetents(content > 0 ? [.height(content + bar)] : [.medium])
    }
}

// MARK: Previews (on the mock)

private struct AddSheetPreview: View {
    @State private var home = HomeModel(environment: .mock(MockBackend(latency: .zero, liveDrift: false)))
    let tab: AddSheetModel.Tab

    var body: some View {
        Color.clear
            .sheet(isPresented: .constant(true)) {
                AddSheet(model: AddSheetModel(home: home, tab: tab))
                    .environment(home)
            }
            .task { await home.run() }
    }
}

#Preview("Name") { AddSheetPreview(tab: .name).preferredColorScheme(.dark) }
#Preview("Intention") { AddSheetPreview(tab: .intention).preferredColorScheme(.light) }

import PlusPrayerDomain
import SwiftUI

/// The add sheet (screens.md, "Add sheet", revised 2026-11-06): one native
/// sheet, buttons in its toolbar, a native segmented control for Name |
/// Intention, a carry row on every step.
///
/// Keyboard: every text field stays in the hierarchy (the hidden tab and the
/// other pages are only moved or faded), so focus moves from one field to the
/// next in the same transaction and the keyboard never hides and reappears.
/// The sheet keeps one height, the tallest it has been (the name form); the
/// offer step and "Who is this for?" push in from the trailing edge.
struct AddSheet: View {
    @State var model: AddSheetModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focus: AddSheetModel.Field?
    @State private var width: CGFloat = 0
    /// "Make room for {alias}": follows the typed name only once typing
    /// pauses, never mid-word.
    @State private var makeRoomName: String?
    /// The carry row's bloom, ~17 pt tall, scaling with its label.
    @ScaledMetric(relativeTo: .subheadline) private var bloomFont = PP.size.carriedMark.carryRow / CarriedMark.glyphEm

    /// The one line at the top: no connection, the ~500 cap, or anything
    /// else that went wrong. Text is kept.
    private var notice: String? {
        // The intention tab's "Saved, but not carried…" (the offer step has
        // it under its header).
        if model.notCarried == .intention && model.step == .form { return L10n.Add.notCarried }
        if model.isOffline { return L10n.Add.offline }
        if model.isAtCap { return L10n.Add.capReached(subjectCap) }
        if model.failedGenerically { return L10n.Add.failed }
        return nil
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: PP.space.md) {
                if let notice {
                    // At the sheet's one text edge, left-aligned. The saved-
                    // but-not-carried status is 15 pt ink, like on the offer step.
                    Text(notice)
                        .font(isSettled ? PP.type.bodySmall : PP.type.caption)
                        .foregroundStyle(isSettled ? PP.color.ink : PP.color.inkMuted)
                        .multilineTextAlignment(.leading)
                        .padding(.leading, PP.space.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                }
                ZStack(alignment: .topLeading) {
                    page(formPage, shown: model.step == .form, before: true)
                    page(offerPage, shown: isOffer, before: false)
                }
                // Sized to the pages (it never sets the sheet's height); its
                // list scrolls inside.
                .overlay(alignment: .topLeading) {
                    page(chooserPage, shown: model.step == .choosing, before: false)
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
                .disabled(isSettled)
            }
            .padding(.horizontal, PP.space.xl)
            .padding(.top, PP.space.md)
            .padding(.bottom, PP.space.xl)
            .animation(reduceMotion ? .easeOut(duration: PP.duration.quick) : .easeInOut(duration: PP.duration.settle),
                       value: model.step)
            .animation(.easeOut(duration: PP.duration.quick), value: notice)
            .toolbar { toolbar }
            // "Who is this for?" is the pushed page's native inline title.
            .navigationTitle(model.step == .choosing ? L10n.Add.whoIsThisFor : "")
            .navigationBarTitleDisplayMode(.inline)
            .fittedSheetHeight()
        }
        .tint(PP.color.ink)
        .onAppear { focus = model.activeField }
        .task(id: model.typedLabel) {
            guard makeRoomName != nil else {
                makeRoomName = model.typedLabel // a prefilled name shows at once
                return
            }
            try? await Task.sleep(for: .seconds(PP.duration.labelPause))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: PP.duration.quick)) { makeRoomName = model.typedLabel }
        }
        .onChange(of: model.isFinished) { _, finished in if finished { dismiss() } }
    }

    /// Saved, but not carried: nothing left to do but Done.
    private var isSettled: Bool { model.isSettled }

    private var isOffer: Bool {
        if case .offer = model.step { true } else { false }
    }

    /// A page that slides: the form leaves to the leading edge, the others
    /// wait off the trailing edge.
    private func page(_ content: some View, shown: Bool, before: Bool) -> some View {
        content
            .offset(x: shown ? 0 : (before ? -width : width))
            .opacity(shown ? 1 : 0)
            .allowsHitTesting(shown)
            .accessibilityHidden(!shown)
    }

    // MARK: Toolbar

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        if isSettled {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.Common.done) { model.finish() }
            }
        } else {
            stepToolbar
        }
    }

    @ToolbarContentBuilder private var stepToolbar: some ToolbarContent {
        switch model.step {
        case .form:
            // The iOS 26 sheet convention: a round glass X (VoiceOver "Cancel").
            // No discard confirmation for now (open-questions D6).
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .close) { model.finish() }
                    .accessibilityLabel(L10n.Add.cancel)
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
        case .choosing:
            ToolbarItem(placement: .topBarLeading) {
                Button { choose(nil) } label: { PPIcon.back }
                    .accessibilityLabel(L10n.Add.back)
            }
        case .offer:
            // No back: the name is already saved.
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.Add.notNow) { model.finish() }
            }
            ToolbarItem(placement: .confirmationAction) { addButton }
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
            // A saved name pushes the offer: its field takes focus as the
            // step changes, so the keyboard stays up (pool full included).
            if isOffer { focus = .offer }
        }
    }

    /// The For row pushes "Who is this for?" with its search focused.
    private func openChooser() {
        model.openChooser()
        focus = .search
    }

    /// Picking someone (or going back) returns to the intention, focused.
    private func choose(_ id: String?) {
        model.choose(id)
        focus = .intention
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
            field(.name, text: $model.name, label: L10n.Add.nameLabel, placeholder: L10n.Add.namePlaceholder,
                  caption: nil)
                .onSubmit { focus = .alias }
                .submitLabel(.next)
            field(.alias, text: $model.alias, label: L10n.Add.aliasLabel, placeholder: L10n.Add.aliasPlaceholder,
                  caption: L10n.Add.aliasCaption)
                .onSubmit(save)
                .submitLabel(.done)
            carryRow(.name)
        }
    }

    private var intentionForm: some View {
        VStack(alignment: .leading, spacing: PP.space.lg) {
            forRow
            field(.intention, text: $model.intention, label: L10n.Add.intentionLabel,
                  placeholder: L10n.Add.intentionPlaceholder, caption: nil)
                .onSubmit(save)
                .submitLabel(.done)
            carryRow(.intention)
        }
    }

    /// Looks like a Home row: the avatar, the serif name, a blue "Change".
    private var forRow: some View {
        Button(action: openChooser) {
            HStack(spacing: PP.space.md) {
                if let parent = model.parent {
                    MonogramAvatar(initials: parent.initials, tone: parent.tone, size: PP.size.avatar.picker)
                    Text(parent.label)
                        .font(PP.type.name)
                        .foregroundStyle(PP.color.ink)
                        .lineLimit(1)
                }
                Spacer(minLength: PP.space.sm)
                Text(L10n.Add.change)
                    .font(PP.type.body)
                    .foregroundStyle(PP.color.primary)
            }
            .padding(.leading, PP.space.md) // the avatar on the shared edge
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.Add.forLabel)
        .accessibilityValue(model.parent?.label ?? "")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Who is this for?

    private var chooserPage: some View {
        VStack(alignment: .leading, spacing: PP.space.md) {
            HStack(spacing: PP.space.sm) {
                PPIcon.search
                    .foregroundStyle(PP.color.inkMuted)
                    .accessibilityHidden(true)
                TextField(text: $model.chooserQuery,
                          prompt: Text(L10n.Search.placeholder).foregroundStyle(PP.color.inkMuted)) {
                    Text(L10n.Search.placeholder)
                }
                    .focused($focus, equals: .search)
                    .foregroundStyle(PP.color.ink)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    // Return doesn't lower the keyboard (screens.md, "Keyboard stays up").
                    .onSubmit { focus = .search }
            }
            .font(PP.type.body)
            .padding(PP.space.md)
            .background(PP.color.raised, in: RoundedRectangle(cornerRadius: PP.radius.md))
            let names = model.chooserNames
            if names.isEmpty {
                Text(L10n.Add.noMatches(model.chooserQuery.trimmingCharacters(in: .whitespacesAndNewlines)))
                    .font(PP.type.caption)
                    .foregroundStyle(PP.color.inkMuted)
                    .padding(.horizontal, PP.space.md)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(names) { name in
                            chooserRow(name)
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
    }

    private func chooserRow(_ name: PickerName) -> some View {
        Button { choose(name.id) } label: {
            HStack(spacing: PP.space.md) {
                MonogramAvatar(initials: name.initials, tone: name.tone, size: PP.size.avatar.picker)
                Text(name.label)
                    .font(PP.type.name)
                    .foregroundStyle(PP.color.ink)
                    .lineLimit(1)
                Spacer(minLength: PP.space.sm)
                if name.id == model.parentId {
                    PPIcon.check
                        .font(PP.type.body)
                        .foregroundStyle(PP.color.ink)
                }
            }
            .padding(.leading, PP.space.md) // the avatar on the shared edge
            .frame(minHeight: PP.size.row.name)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name.label)
        .accessibilityIdentifier("addSheet.for.\(name.id)")
        .accessibilityAddTraits(name.id == model.parentId ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: The offer step

    private var offerPage: some View {
        VStack(alignment: .leading, spacing: PP.space.md) {
            Text(L10n.Add.added(model.offerName))
                .font(PP.type.displayLine)
                .foregroundStyle(PP.color.ink)
                .padding(.leading, PP.space.md) // the sheet's one text edge
            if model.notCarried != nil {
                Text(L10n.Add.notCarried)
                    .font(PP.type.bodySmall)
                    .foregroundStyle(PP.color.ink)
                    .padding(.leading, PP.space.md)
                    .transition(.opacity)
            }
            // The question is the field's label (screens.md, Form type).
            field(.offer, text: $model.offerText, label: L10n.Add.offerQuestion(model.offerName),
                  placeholder: L10n.Add.intentionPlaceholder, caption: nil)
                .onSubmit(save)
                .submitLabel(.done)
            carryRow(.offer)
                .padding(.top, PP.space.sm)
        }
    }

    // MARK: The carry row

    /// "Carry onto the list ✱" (the bloom trailing the label, as on Home's
    /// rows), the toggle trailing the row; under it, at the label edge, the
    /// meter, "Also carries …", and with no room the blue "Make room …"
    /// (inert until Membership / Your portion exist).
    private func carryRow(_ row: AddSheetModel.CarryRow) -> some View {
        let offer = model.carryOffer(row)
        let isOn = Binding(get: { model.isCarrying(row) }, set: { model.setCarrying(row, $0) })
        let on = model.isCarrying(row)
        let also = model.alsoCarries(row)
        return VStack(alignment: .leading, spacing: PP.space.xxs) {
            HStack(spacing: PP.space.sm) {
                HStack(alignment: .firstTextBaseline, spacing: PP.size.carriedMark.nameGap) {
                    Text(L10n.Add.carryTitle)
                        .font(PP.type.label)
                        .foregroundStyle(PP.color.ink)
                    // inkMuted while on; dims to the row mark's color off or disabled.
                    PPIcon.carried
                        .font(.system(size: bloomFont))
                        .foregroundStyle(on ? PP.color.inkMuted : PP.color.carriedMark)
                }
                .accessibilityHidden(true)
                Spacer(minLength: PP.space.sm)
                Toggle(L10n.Add.carryTitle, isOn: isOn)
                    .ppSwitch()
                    .labelsHidden()
                    .disabled(!offer.hasRoom)
            }
            Text(L10n.Add.carryMeter(model.meter(row)))
                .font(PP.type.caption)
                .foregroundStyle(PP.color.inkMuted)
            if let also {
                Text(L10n.Add.alsoCarries(also.name, cost: also.cost))
                    .font(PP.type.caption)
                    .foregroundStyle(PP.color.inkMuted)
                    .transition(.opacity)
            }
            if !offer.hasRoom {
                makeRoom(row)
                    .padding(.top, PP.space.xxs)
            }
        }
        // The labels' shared leading edge (the fields' text inset).
        .padding(.leading, PP.space.md)
        .animation(.easeOut(duration: PP.duration.quick), value: on)
        .animation(.easeOut(duration: PP.duration.quick), value: also?.name)
    }

    /// Visible but inert for now: what its menu offers is part of the
    /// monetization decision (open-questions Q31/Q32).
    private func makeRoom(_ row: AddSheetModel.CarryRow) -> some View {
        Button(row == .name ? L10n.Add.makeRoom(for: makeRoomName ?? "") : L10n.Add.makeRoomForIntention) {}
            .contentTransition(.opacity)
            .font(PP.type.caption)
            .tint(PP.color.primary)
            .multilineTextAlignment(.leading)
            .accessibilityHint(L10n.Add.makeRoomHint)
    }

    // MARK: A field

    /// A native text field with its label above (if any) and its muted
    /// caption below (if any). Caps stop input; a muted "34/40" counter shows in the
    /// last 10 characters. Contact info shows its message in place of the
    /// caption once typing pauses.
    private func field(_ field: AddSheetModel.Field, text: Binding<String>, label: String? = nil,
                       placeholder: String, caption: String?) -> some View {
        let cap = AddSheetModel.cap(field)
        let count = text.wrappedValue.count
        let issue = model.contactShown.contains(field)
        return VStack(alignment: .leading, spacing: PP.space.xs) {
            if let label {
                Text(label)
                    .font(PP.type.label)
                    .foregroundStyle(PP.color.ink)
                    .padding(.horizontal, PP.space.md)
                    .accessibilityHidden(true)
            }
            TextField(text: text, prompt: Text(placeholder).foregroundStyle(PP.color.inkMuted)) {
                Text(label ?? placeholder)
            }
                .focused($focus, equals: field)
                .font(PP.type.body)
                .foregroundStyle(PP.color.ink)
                .textInputAutocapitalization(field == .name || field == .alias ? .words : .sentences)
                .padding(PP.space.md)
                .background(PP.color.raised, in: RoundedRectangle(cornerRadius: PP.radius.md))
                .accessibilityLabel(label ?? placeholder)
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
            // The line under the field, only when it has something to say.
            if issue || caption != nil || count >= cap - 10 {
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
    let tab: AddSheetModel.Tab
    var poolFull = false
    @State private var backend = MockBackend(latency: .zero, liveDrift: false)
    @State private var home: HomeModel?
    @State private var model: AddSheetModel?

    var body: some View {
        Color.clear
            .sheet(item: $model) { model in
                AddSheet(model: model)
            }
            .task {
                if poolFull { backend.header.update { $0?.entitlementExpiresAt = .now.addingTimeInterval(-60) } }
                let home = HomeModel(environment: .mock(backend))
                self.home = home
                Task { await home.run() }
                while !home.isLoaded || home.header == nil { try? await Task.sleep(for: .milliseconds(10)) }
                model = AddSheetModel(home: home, tab: tab, name: poolFull ? "Gary Olson" : "")
            }
    }
}

#Preview("Name") { AddSheetPreview(tab: .name).preferredColorScheme(.dark) }
#Preview("Intention") { AddSheetPreview(tab: .intention).preferredColorScheme(.light) }
#Preview("Pool full") { AddSheetPreview(tab: .name, poolFull: true).preferredColorScheme(.light) }
#Preview("Pool full, large type") {
    AddSheetPreview(tab: .name, poolFull: true).dynamicTypeSize(.accessibility2)
}

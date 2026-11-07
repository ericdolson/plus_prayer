import PlusPrayerDomain
import SwiftUI

/// The add sheet (screens.md, "Add sheet", rewritten 2026-11-06): one native
/// sheet over native forms (inset grouped, Tier B: the platform owns spacing,
/// type, alignment and row styling). Buttons in the toolbar, a native
/// segmented control for Name | Intention, a carry section on every step.
///
/// Keyboard: every step's form stays in the hierarchy (the hidden tab and
/// the offer step are only faded or moved aside), so focus moves from one
/// field to the next in the same transaction and the keyboard never hides
/// and reappears. "Who is this for?" is a real navigation push whose search
/// takes focus as it appears. The sheet keeps one height, the tallest any
/// step's form has been.
struct AddSheet: View {
    @State var model: AddSheetModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focus: AddSheetModel.Field?
    @State private var width: CGFloat = 0
    /// "Make room for {alias}": follows the typed name only once typing
    /// pauses, never mid-word.
    @State private var makeRoomName: String?
    /// The tallest a form's content has been, for the sheet's one height.
    @State private var contentHeight: CGFloat = 0
    /// The navigation path: "Who is this for?" when pushed.
    @State private var path: [Route] = []

    private enum Route: Hashable {
        case chooser
    }

    /// The one notice at the top: the intention tab's "Saved, but not
    /// carried…", no connection, the ~500 cap, or anything else that went
    /// wrong. Text is kept. (The offer step puts "Saved, but not carried"
    /// under its header.)
    private var notice: String? {
        if model.notCarried == .intention && !isOffer { return L10n.Add.notCarried }
        if model.isOffline { return L10n.Add.offline }
        if model.isAtCap { return L10n.Add.capReached(subjectCap) }
        if model.failedGenerically { return L10n.Add.failed }
        return nil
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                page(nameForm, shown: !isOffer && model.tab == .name, slide: isOffer ? -width : 0)
                page(intentionForm, shown: !isOffer && model.tab == .intention, slide: isOffer ? -width : 0)
                page(offerForm, shown: isOffer, slide: isOffer ? 0 : width)
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
            .disabled(isSettled)
            .animation(reduceMotion ? .easeOut(duration: PP.duration.quick) : .easeInOut(duration: PP.duration.settle),
                       value: isOffer)
            .animation(.easeOut(duration: PP.duration.quick), value: notice)
            .toolbar { toolbar }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Route.self) { _ in chooser }
            .fittedSheetHeight(contentHeight)
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
        // The For row pushes; the native back (or a pick) pops.
        .onChange(of: path) { _, path in
            if path.isEmpty, model.step == .choosing {
                model.choose(nil)
                refocusIntention()
            } else if !path.isEmpty, model.step == .form {
                model.openChooser()
            }
        }
    }

    /// Saved, but not carried: nothing left to do but Done.
    private var isSettled: Bool { model.isSettled }

    private var isOffer: Bool {
        if case .offer = model.step { true } else { false }
    }

    /// A step's form: faded out when it isn't shown, slid aside for the offer.
    /// Its content height feeds the sheet's one height.
    private func page(_ form: some View, shown: Bool, slide: CGFloat) -> some View {
        form
            .scrollContentBackground(.hidden)
            // Its content plus the top inset (the bar and the form's own top
            // margin); the bottom inset is left out (it holds the keyboard).
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentSize.height + $0.contentInsets.top } action: { _, height in
                contentHeight = max(contentHeight, height)
            }
            .offset(x: slide)
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
        } else if isOffer {
            // No back: the name is already saved.
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.Add.notNow) { model.finish() }
            }
            ToolbarItem(placement: .confirmationAction) { addButton }
        } else {
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

    // MARK: Name tab

    private var nameForm: some View {
        Form {
            noticeSection
            // A preview only in v1: its tone from the start, initials live by
            // Home's rule.
            Section {
                MonogramAvatar(initials: model.previewInitials, tone: model.tone, size: PP.size.avatar.large)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
                    .listRowBackground(Color.clear)
            }
            Section {
                TextField(L10n.Add.nameLabel, text: $model.name, prompt: prompt(L10n.Add.namePlaceholder))
                    .focused($focus, equals: .name)
                    .accessibilityLabel(L10n.Add.nameLabel)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.next)
                    .onSubmit { focus = .alias }
                    .fieldRules(.name, text: $model.name, model: model)
                    .listRowBackground(PP.color.raised)
            } header: {
                Text(L10n.Add.nameLabel)
            } footer: {
                fieldFooter(.name, text: model.name, caption: nil)
            }
            Section {
                TextField(L10n.Add.aliasLabel, text: $model.alias, prompt: prompt(L10n.Add.aliasPlaceholder))
                    .focused($focus, equals: .alias)
                    .accessibilityLabel(L10n.Add.aliasLabel)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit(save)
                    .fieldRules(.alias, text: $model.alias, model: model)
                    .listRowBackground(PP.color.raised)
            } header: {
                Text(L10n.Add.aliasLabel)
            } footer: {
                fieldFooter(.alias, text: model.alias, caption: L10n.Add.aliasCaption)
            }
            carrySection(.name)
        }
    }

    // MARK: Intention tab

    private var intentionForm: some View {
        Form {
            noticeSection
            Section {
                NavigationLink(value: Route.chooser) {
                    LabeledContent {
                        if let parent = model.parent {
                            HStack {
                                MonogramAvatar(initials: parent.initials, tone: parent.tone,
                                               size: PP.size.avatar.picker)
                                Text(parent.label)
                                    .foregroundStyle(PP.color.ink)
                                    .lineLimit(1)
                            }
                        }
                    } label: {
                        Text(L10n.Add.forLabel)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n.Add.forLabel)
                .accessibilityValue(model.parent?.label ?? "")
                .accessibilityAddTraits(.isButton)
                .listRowBackground(PP.color.raised)
            }
            Section {
                growingField(.intention, text: $model.intention, label: L10n.Add.intentionLabel)
            } header: {
                Text(L10n.Add.intentionLabel)
            } footer: {
                fieldFooter(.intention, text: model.intention, caption: nil)
            }
            carrySection(.intention)
        }
    }

    // MARK: Who is this for?

    /// A native list with search, everyone in Home order, Me first; the
    /// current person has the checkmark. Picking pops back to the intention.
    private var chooser: some View {
        let names = model.chooserNames
        return List {
            if names.isEmpty {
                Text(L10n.Add.noMatches(model.chooserQuery.trimmingCharacters(in: .whitespacesAndNewlines)))
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }
            ForEach(names) { name in
                Button { choose(name.id) } label: {
                    HStack {
                        MonogramAvatar(initials: name.initials, tone: name.tone, size: PP.size.avatar.picker)
                        Text(name.label)
                            .foregroundStyle(PP.color.ink)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        if name.id == model.parentId {
                            PPIcon.check.foregroundStyle(.tint)
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(name.label)
                .accessibilityIdentifier("addSheet.for.\(name.id)")
                .accessibilityAddTraits(name.id == model.parentId ? [.isButton, .isSelected] : .isButton)
                .listRowBackground(PP.color.raised)
            }
        }
        .scrollContentBackground(.hidden)
        .searchable(text: $model.chooserQuery, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: L10n.Search.placeholder)
        .searchFocused($focus, equals: .search)
        .navigationTitle(L10n.Add.whoIsThisFor)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focus = .search }
    }

    /// Picking someone returns to the intention, focused.
    private func choose(_ id: String) {
        model.choose(id)
        path = []
        refocusIntention()
    }

    /// The intention field is out of the window while the list is pushed, so
    /// it takes focus once the pop has begun and it's back: straight from
    /// the search field, so the keyboard stays up.
    private func refocusIntention() {
        Task { @MainActor in
            await Task.yield()
            focus = .intention
        }
    }

    // MARK: The offer step

    private var offerForm: some View {
        Form {
            noticeSection
            // One clear header block; the question labels the field below.
            Section {
                VStack(alignment: .leading) {
                    Text(L10n.Add.added(model.offerName))
                        .font(PP.type.displayLine)
                        .foregroundStyle(PP.color.ink)
                    if model.notCarried != nil {
                        Text(L10n.Add.notCarried)
                            .foregroundStyle(PP.color.ink)
                            .transition(.opacity)
                    }
                    Text(L10n.Add.offerQuestion(model.offerName))
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
            }
            Section {
                growingField(.offer, text: $model.offerText, label: L10n.Add.offerQuestion(model.offerName))
            } footer: {
                fieldFooter(.offer, text: model.offerText, caption: nil)
            }
            carrySection(.offer)
        }
    }

    // MARK: The carry section

    /// A native toggle: the title "Carry onto the list ✱" (the bloom trailing
    /// it, inkMuted in every state) and the meter as its subtitle. With no
    /// room the footer holds "Make room …", inert until Membership / Your
    /// portion exist.
    private func carrySection(_ row: AddSheetModel.CarryRow) -> some View {
        let offer = model.carryOffer(row)
        let isOn = Binding(get: { model.isCarrying(row) }, set: { model.setCarrying(row, $0) })
        var subtitle = L10n.Add.carryMeter(model.meter(row))
        if let also = model.alsoCarries(row) {
            subtitle += "\n" + L10n.Add.alsoCarries(also.name, cost: also.cost)
        }
        let bloom = Text(PPIcon.carried).foregroundStyle(PP.color.inkMuted)
        return Section {
            Toggle(isOn: isOn) {
                Text("\(Text(L10n.Add.carryTitle))\u{00A0}\(bloom)")
                Text(subtitle)
            }
            .ppSwitch()
            .disabled(!offer.hasRoom)
            .accessibilityLabel(L10n.Add.carryTitle)
            .accessibilityHint(subtitle)
            .listRowBackground(PP.color.raised)
        } footer: {
            if !offer.hasRoom { makeRoom(row) }
        }
    }

    /// Visible but inert for now: what its menu offers is part of the
    /// monetization decision (open-questions Q31/Q32).
    private func makeRoom(_ row: AddSheetModel.CarryRow) -> some View {
        Button(row == .name ? L10n.Add.makeRoom(for: makeRoomName ?? "") : L10n.Add.makeRoomForIntention) {}
            .contentTransition(.opacity)
            .tint(PP.color.primary)
            .accessibilityHint(L10n.Add.makeRoomHint)
    }

    // MARK: Notices, fields and footers

    /// The notice row at the top: offline, the cap, a failure, or the
    /// intention tab's "Saved, but not carried…". Errors in ink, never red.
    @ViewBuilder private var noticeSection: some View {
        if let notice {
            Section {
                Text(notice)
                    .foregroundStyle(PP.color.ink)
                    .listRowBackground(Color.clear)
                    .transition(.opacity)
            }
        }
    }

    private func prompt(_ placeholder: String) -> Text {
        Text(placeholder).foregroundStyle(PP.color.inkMuted)
    }

    /// An intention field: grows from one line to three; no line breaks
    /// (Return submits, as Add does; pasted breaks become spaces).
    private func growingField(_ field: AddSheetModel.Field, text: Binding<String>, label: String) -> some View {
        TextField(label, text: text, prompt: prompt(L10n.Add.intentionPlaceholder), axis: .vertical)
            .lineLimit(1...3)
            .focused($focus, equals: field)
            .accessibilityLabel(label)
            .textInputAutocapitalization(.sentences)
            .submitLabel(.done)
            .onChange(of: text.wrappedValue) { old, new in
                guard new.contains(where: \.isNewline) else { return }
                let typedReturn = new.count == old.count + 1 && new.filter { !$0.isNewline } == old
                if typedReturn {
                    text.wrappedValue = old
                    save()
                } else {
                    text.wrappedValue = String(new.map { $0.isNewline ? " " : $0 })
                }
            }
            .fieldRules(field, text: text, model: model)
            .listRowBackground(PP.color.raised)
    }

    /// The section footer under a field: its contact-info message (ink) in
    /// place of its hint, and the "34/40" counter in the last 10 characters.
    @ViewBuilder private func fieldFooter(_ field: AddSheetModel.Field, text: String, caption: String?) -> some View {
        let cap = AddSheetModel.cap(field)
        let count = text.count
        let issue = model.contactShown.contains(field)
        if issue || caption != nil || count >= cap - 10 {
            HStack(alignment: .firstTextBaseline) {
                if issue {
                    Text(L10n.Add.contactError).foregroundStyle(PP.color.ink)
                } else if let caption {
                    Text(caption)
                }
                Spacer(minLength: 0)
                if count >= cap - 10 {
                    Text(L10n.Add.counter(count, cap)).monospacedDigit()
                }
            }
        }
    }
}

private extension View {
    /// A field's rules: caps stop input; the contact-info check runs once
    /// typing pauses (and clears at once when fixed); typing again clears an
    /// offline or failed add.
    func fieldRules(_ field: AddSheetModel.Field, text: Binding<String>, model: AddSheetModel) -> some View {
        let cap = AddSheetModel.cap(field)
        return self
            .onChange(of: text.wrappedValue) { _, new in
                if new.count > cap { text.wrappedValue = String(new.prefix(cap)) }
                model.textChanged()
            }
            .task(id: text.wrappedValue) {
                guard model.hasContactIssue(field) else {
                    model.showContactIssue(field, false)
                    return
                }
                try? await Task.sleep(for: .seconds(PP.duration.validationPause))
                if !Task.isCancelled { model.showContactIssue(field, true) }
            }
    }
}

// MARK: Sheet height

extension View {
    /// A sheet as tall as its forms' content has been (one height for both
    /// tabs and the offer step), the bar included.
    func fittedSheetHeight(_ content: CGFloat) -> some View {
        presentationDetents(content > 0 ? [.height(content)] : [.medium])
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

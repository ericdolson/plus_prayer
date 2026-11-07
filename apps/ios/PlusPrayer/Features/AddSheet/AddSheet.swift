import PlusPrayerDomain
import SwiftUI

/// The add sheet (screens.md, "Add sheet", revised 2026-11-07): one native
/// sheet over native forms (inset grouped, Tier B: the platform owns spacing,
/// type, alignment and row styling). Buttons in the toolbar, a native
/// segmented control for Name | Intention. The Name tab has no carry row (a
/// new name is auto-carried while there's room; its page manages the rest);
/// intentions have a carry toggle.
///
/// Keyboard: it rises with the sheet (`KeyboardPrimer`) and the first field
/// takes it over. Only the visible tab is in the hierarchy (so in the
/// accessibility tree); switching tabs hands the keyboard to the primer
/// first, so it never hides and reappears while the new tab's field
/// appears and takes it. "Who is this for?" is a real navigation push for tapping: its
/// search starts inactive and the keyboard goes down. The standard large
/// sheet.
///
/// The add-intention form for a person ("Add intention" from their page or
/// a Home row) is its own layout: the person as on Home, the intention, the
/// carry toggle.
struct AddSheet: View {
    @State var model: AddSheetModel

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: AddSheetModel.Field?
    /// Holds the keyboard while one tab's field leaves and the next arrives.
    @State private var primer = KeyboardPrimer.Handle()
    /// The carry title's bloom: `size.carriedMark.carryRow` tall at the
    /// default size, scaling with the title's text.
    @ScaledMetric(relativeTo: .body) private var bloomHeight = PP.size.carriedMark.carryRow
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// The navigation path: "Who is this for?" when pushed.
    @State private var path: [Route] = []

    private enum Route: Hashable {
        case chooser
    }

    /// The one notice at the top: the intention tab's "Saved, but not
    /// carried…", no connection, the ~500 cap, or anything else that went
    /// wrong. Text is kept. (The person form puts "Saved, but not carried"
    /// under its header row.)
    private var notice: String? {
        if model.notCarried && !isPerson { return L10n.Add.notCarried }
        if model.isOffline { return L10n.Add.offline }
        if model.isAtCap { return L10n.Add.capReached(subjectCap) }
        if model.failedGenerically { return L10n.Add.failed }
        return nil
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                if isPerson {
                    page(personForm)
                } else if model.tab == .name {
                    page(nameForm)
                } else {
                    page(intentionForm)
                }
            }
            .disabled(isSettled)
            .animation(.easeOut(duration: PP.duration.quick), value: notice)
            .toolbar { toolbar }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Route.self) { _ in chooser }
        }
        .tint(PP.color.ink)
        .presentationDetents([.large])
        // The keyboard rises with the sheet; the first field takes it over
        // once SwiftUI focuses it (KeyboardPrimer).
        .background {
            KeyboardPrimer(handle: primer, autocapitalization: model.activeField == .name ? .words : .sentences,
                           returnKey: model.activeField == .name ? .next : .done,
                           onType: model.typeAhead)
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
        }
        .onAppear { focus = model.activeField }
        // Opened from a row's context menu, the menu's dismissal sometimes
        // takes the keyboard back as the sheet rises: once it has settled, a
        // field that should have it takes it (late, rather than never).
        .task {
            try? await Task.sleep(for: .seconds(PP.duration.settle))
            if focus == nil && path.isEmpty && !isSettled { focus = model.activeField }
        }
        // A new tab's field takes the keyboard from the primer once it's in
        // the hierarchy. (Not from the form's onAppear: that also runs as
        // "Who is this for?" pops, and focusing mid-pop lost the toolbar.)
        .onChange(of: model.tab) { focus = model.activeField }
        .onChange(of: model.isFinished) { _, finished in if finished { dismiss() } }


        // The For row pushes; the native back (or a pick) pops.
        .onChange(of: path) { _, path in
            if path.isEmpty, model.step == .choosing {
                model.choose(nil)
            } else if !path.isEmpty, model.step == .form {
                // A screen for tapping: the keyboard goes down with the push.
                focus = nil
                model.openChooser()
            }
        }
    }

    /// Saved, but not carried: nothing left to do but Done.
    private var isSettled: Bool { model.isSettled }

    /// The add-intention form for a person.
    private var isPerson: Bool {
        if case .person = model.step { true } else { false }
    }

    /// Only the visible tab is in the hierarchy (and so in the
    /// accessibility tree: a hidden `Form`'s rows ignore `accessibilityHidden`).
    private func page(_ form: some View) -> some View {
        form.scrollContentBackground(.hidden)
    }

    /// The person as on Home: the Home-row avatar and the serif name (the
    /// person form's header).
    private func personRow(initials: String, tone: Int, name: String) -> some View {
        HStack(spacing: PP.space.md) {
            MonogramAvatar(initials: initials, tone: tone, size: PP.size.avatar.row)
            Text(verbatim: name)
                .font(PP.type.name)
                .foregroundStyle(PP.color.ink)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Toolbar

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        if isSettled {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.Common.done) { model.finish() }
            }
        } else {
            // X · segmented control (Name and Intention tabs only) · Add, at
            // opposite ends; the add-intention form has no title. No discard
            // confirmation for now (open-questions D6).
            ToolbarItem(placement: .cancellationAction) { closeButton }
            if !isPerson { segmentedControl }
            ToolbarItem(placement: .confirmationAction) { addButton }
        }
    }

    /// The iOS 26 sheet convention: a round glass X (VoiceOver "Cancel").
    private var closeButton: some View {
        Button(role: .close) { model.finish() }
            .accessibilityLabel(L10n.Add.cancel)
    }


    private var segmentedControl: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Picker(selection: tabBinding) {
                Text(L10n.Add.tabName).tag(AddSheetModel.Tab.name)
                Text(L10n.Add.tabIntention).tag(AddSheetModel.Tab.intention)
            } label: {
                EmptyView()
            }
            .pickerStyle(.segmented)
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
            guard tab != model.tab else { return }
            // The old tab's field leaves the hierarchy: the primer holds the
            // keyboard until the new one is there and takes it (onChange of
            // the tab).
            primer.prime(autocapitalization: tab == .name ? .words : .sentences,
                         returnKey: tab == .name ? .next : .done)
            model.tab = tab
        })
    }

    private func save() {
        Task { await model.add() }
    }

    // MARK: Name tab

    /// Who they are: the avatar on its own row, the name, what you call
    /// them. No carry row (auto-carried while there's room; their page
    /// manages it).
    private var nameForm: some View {
        Form {
            noticeSection
            // A preview only in v1: its tone from the start, initials
            // following the display name live (a person glyph until typing
            // begins). Large, in a tight row.
            Section {
                MonogramAvatar(initials: model.previewInitials, tone: model.tone, size: PP.size.avatar.person,
                               placeholder: PPIcon.person)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
                    .listRowInsets(EdgeInsets(top: PP.space.sm, leading: 0, bottom: PP.space.sm, trailing: 0))
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
    /// The search starts inactive (title and back stay; it's one tap away):
    /// this screen is for tapping.
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
        // Back from here (a pick or back): the intention takes focus once the
        // pop has finished and it's in the window again. (Earlier, from the
        // root's onAppear mid-pop, it sometimes didn't take.)
        .onDisappear { if model.step == .form { focus = .intention } }
    }

    /// Picking someone returns to the intention, focused.
    private func choose(_ id: String) {
        model.choose(id)
        path = []
    }

    // MARK: The add-intention form for a person

    /// "Add intention" from a person's page or a Home row: the person as on
    /// Home, then the intention, then the same carry toggle as the Intention
    /// tab. No For row: the person is given, not chosen.
    private var personForm: some View {
        Form {
            noticeSection
            Section {
                VStack(alignment: .leading, spacing: PP.space.md) {
                    if let person = model.person {
                        personRow(initials: person.initials, tone: person.tone, name: person.label)
                    }
                    if model.notCarried {
                        Text(L10n.Add.notCarried)
                            .foregroundStyle(PP.color.ink)
                            .transition(.opacity)
                    }
                }
                .listRowBackground(Color.clear)
            }
            Section {
                growingField(.person, text: $model.personText, label: L10n.Add.intentionLabel)
            } header: {
                Text(L10n.Add.intentionLabel)
            } footer: {
                fieldFooter(.person, text: model.personText, caption: nil)
            }
            carrySection(.person)
        }
    }

    // MARK: The carry section

    /// A native toggle (the Intention tab and the add-intention form): the
    /// title "Carry onto the list ✱" (the bloom trailing it, inkMuted in
    /// every state) and the meter as its subtitle. With no room the footer
    /// holds "Make room for this intention", inert until Membership / Your
    /// portion exist.
    private func carrySection(_ row: AddSheetModel.CarryRow) -> some View {
        let offer = model.carryOffer(row)
        let isOn = Binding(get: { model.isCarrying(row) }, set: { model.setCarrying(row, $0) })
        var subtitle = L10n.Add.carryMeter(model.meter(row))
        if let also = model.alsoCarries(row) {
            subtitle += "\n" + L10n.Add.alsoCarries(also.name, cost: also.cost)
        }
        return Section {
            Toggle(isOn: isOn) {
                CarryTitle.text(bloomHeight: bloomHeight, dynamicTypeSize: dynamicTypeSize)
                Text(subtitle)
            }
            .ppSwitch()
            .disabled(!offer.hasRoom)
            .accessibilityLabel(L10n.Add.carryTitle)
            .accessibilityHint(subtitle)
            .listRowBackground(PP.color.raised)
        } footer: {
            if !offer.hasRoom { makeRoom }
        }
    }

    /// Visible but inert for now: what its menu offers is part of the
    /// monetization decision (open-questions Q31/Q32).
    private var makeRoom: some View {
        Button(L10n.Add.makeRoomForIntention) {}
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

// MARK: Previews (on the mock)

private struct AddSheetPreview: View {
    let tab: AddSheetModel.Tab
    var poolFull = false
    /// "Add intention" for this person (their page or a Home row).
    var fromName: String?
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
                model = if let fromName {
                    AddSheetModel(home: home, intentionFor: fromName)
                } else {
                    AddSheetModel(home: home, tab: tab)
                }
            }
    }
}

#Preview("Name") { AddSheetPreview(tab: .name).preferredColorScheme(.dark) }
#Preview("Intention") { AddSheetPreview(tab: .intention).preferredColorScheme(.light) }
#Preview("Add intention for a person") { AddSheetPreview(tab: .intention, fromName: "dad").preferredColorScheme(.light) }
#Preview("Pool full") { AddSheetPreview(tab: .intention, poolFull: true).preferredColorScheme(.light) }
#Preview("Pool full, large type") {
    AddSheetPreview(tab: .intention, poolFull: true).dynamicTypeSize(.accessibility2)
}

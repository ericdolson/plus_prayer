import Foundation
import Observation
import PlusPrayerDomain

/// The add sheet's flow (screens.md, "Add sheet", revised 2026-11-07). One
/// sheet, one tap to save:
///
///     form (Name | Intention) ──Add name──▶ close (to the person's page once
///          │                                 it exists; Home for now)
///          ├──Add intention──▶ close
///          └──For row──▶ choosing "Who is this for?" ──pick──▶ form
///
///     a Home row's long-press ──▶ person (the add-intention form) ──Add──▶ close
///
/// A new name is auto-carried while there's room; its carrying is managed
/// on its page. Intentions have a carry toggle, so nothing is reported
/// after the fact, except when the server disagrees (the pool filled from
/// another device): "Saved, but not carried…", then Done instead of
/// closing. The model holds the text, the step, the carry choices and what
/// the toolbar can do; the view owns focus and the live contact check's
/// pause.
@MainActor @Observable
final class AddSheetModel: Identifiable {
    enum Tab: Hashable {
        case name, intention
    }

    enum Field: Hashable {
        case name, alias, intention, person, search
    }

    enum Step: Equatable {
        case form
        /// The For row's push: pick who the intention is for.
        case choosing
        /// The add-intention form for a known person ("Add intention" from
        /// their page or a Home row).
        case person(nameId: String)
    }

    /// Where a carry toggle sits: the Intention tab, or the add-intention
    /// form for a person.
    enum CarryRow: Hashable {
        case intention, person
    }

    var tab: Tab
    private(set) var step: Step = .form
    var name = ""
    var alias = ""
    var intention = ""
    /// The known person's intention (the add-intention form).
    var personText = ""
    /// "Who is this for?"'s search field.
    var chooserQuery = ""
    /// The intention's name (the For row); Me by default. Changing it puts
    /// the intention's carry row back to its default.
    var parentId: String {
        didSet { if parentId != oldValue { carryChoice[.intention] = nil } }
    }
    /// Picked once when the sheet opens (least used on Home); never changes
    /// while typing.
    let tone: Int
    /// Opened for a known person (their page or a Home row): only the
    /// add-intention form, with X / Add.
    let isFromName: Bool

    /// Contact info the view has shown under a field (after the pause).
    private(set) var contactShown: Set<Field> = []
    private(set) var isSaving = false
    /// An add failed for want of a connection (Home's network state covers
    /// the rest).
    private(set) var failedOffline = false
    /// The sheet's work is done: close it.
    private(set) var isFinished = false

    /// The server refused for the ~500 cap.
    private(set) var failedAtCap = false
    /// Anything else went wrong: "Couldn't add this right now…". Add stays
    /// available to try again; the text is kept.
    private(set) var failedGenerically = false

    /// An intention saved but not carried although its toggle was on:
    /// "Saved, but not carried. The list's places filled up." An end state,
    /// Done only.
    private(set) var notCarried = false

    var isSettled: Bool { notCarried }

    /// What the user set on a carry row; nil = its default.
    private var carryChoice: [CarryRow: Bool] = [:]

    private let home: HomeModel

    /// - Parameter name: prefilled from search ("Robe" → "Robert"), capped.
    init(home: HomeModel, tab: Tab = .name, parentId: String? = nil, name: String = "") {
        self.home = home
        self.tab = tab
        self.name = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(TextCap.name))
        self.parentId = parentId ?? home.pickerNames().first?.id ?? ""
        tone = home.toneForNewName()
        isFromName = false
    }

    /// "Add intention" from a person's page or a Home row: the add-intention
    /// form for that person, no For row.
    init(home: HomeModel, intentionFor nameId: String) {
        self.home = home
        tab = .intention
        parentId = nameId
        tone = home.toneForNewName()
        isFromName = true
        step = .person(nameId: nameId)
    }

    // MARK: Derived

    /// Home's initials rule, live: the alias's once it has text, else the name's.
    var previewInitials: String {
        let alias = cleanText(self.alias)
        return initials(alias.isEmpty ? cleanText(name) : alias)
    }

    /// The new person's avatar on the Name tab: the display name's initials
    /// (alias, else name), or "…" until there's one.
    var avatarInitials: String { previewInitials.isEmpty ? "…" : previewInitials }

    var isOffline: Bool { !home.isOnline || failedOffline }

    /// At the ~500 cap: the line at the top, Add disabled.
    var isAtCap: Bool { failedAtCap || home.subjectCount >= subjectCap }

    var parent: PickerName? { home.pickerNames().first { $0.id == parentId } }

    /// "Who is this for?": everyone in Home order, Me first, by name + alias.
    var chooserNames: [PickerName] { home.pickerNames(matching: chooserQuery) }

    /// The field that has the keyboard at this step.
    var activeField: Field {
        switch step {
        case .form: tab == .name ? .name : .intention
        case .choosing: .search
        case .person: .person
        }
    }

    /// The toolbar's Add. Disabled while the text is empty, while a contact
    /// message shows, offline, at the cap, or saving.
    var canAdd: Bool {
        guard !isSaving, !isOffline, !isAtCap, !notCarried else { return false }
        let text = switch activeField {
        case .name: name
        case .intention: intention
        case .person: personText
        case .alias, .search: ""
        }
        if cleanText(text).isEmpty || contactShown.contains(activeField) { return false }
        if activeField == .name && contactShown.contains(.alias) { return false }
        return true
    }

    /// The add-intention form's header: avatar + name as on Home.
    var person: PickerName? {
        guard let id = personId else { return nil }
        return home.pickerNames().first { $0.id == id }
    }

    private var personId: String? {
        if case .person(let id) = step { id } else { nil }
    }

    /// The person's alias, else their name.
    var personName: String { person?.label ?? "" }

    static func cap(_ field: Field) -> Int {
        switch field {
        case .name: TextCap.name
        case .alias: TextCap.alias
        case .intention, .person: TextCap.intention
        case .search: TextCap.name
        }
    }

    /// Whether the text in `field` would be refused for contact info (aliases
    /// never are).
    func hasContactIssue(_ field: Field) -> Bool {
        switch field {
        case .name: validatePrinted(name, kind: .soul) == .contactInfo
        case .intention: validatePrinted(intention, kind: .intention) == .contactInfo
        case .person: validatePrinted(personText, kind: .intention) == .contactInfo
        case .alias, .search: false
        }
    }

    // MARK: The carry row

    /// What the pool allows for this row, now.
    func carryOffer(_ row: CarryRow) -> CarryOffer {
        switch row {
        case .intention: home.carryOffer(kind: .intention, parentId: parentId)
        case .person: home.carryOffer(kind: .intention, parentId: personId)
        }
    }

    /// The toggle: the user's choice while there's room, else its default;
    /// always off with no room.
    func isCarrying(_ row: CarryRow) -> Bool {
        let offer = carryOffer(row)
        return offer.hasRoom && (carryChoice[row] ?? offer.startsOn)
    }

    func setCarrying(_ row: CarryRow, _ on: Bool) {
        guard carryOffer(row).hasRoom else { return }
        carryChoice[row] = on
    }

    /// The meter, previewing the toggle's result.
    func meter(_ row: CarryRow) -> CarryMeter {
        carryMeter(carryOffer(row), kind: .intention, isOn: isCarrying(row))
    }

    /// "Also carries Dad · uses 2 places": the toggle is on and it carries
    /// the intention's name too, at this true cost. The cost is nil when the
    /// meter already says it takes the last places (no repeating it).
    func alsoCarries(_ row: CarryRow) -> (name: String, cost: Int?)? {
        let offer = carryOffer(row)
        guard isCarrying(row), offer.alsoCarriesParent else { return nil }
        let cost: Int? = if case .usesLast = meter(row) { nil } else { offer.cost }
        switch row {
        case .intention: return parent.map { ($0.label, cost) }
        case .person: return (personName, cost)
        }
    }

    // MARK: Commands

    /// The live check, after typing pauses (the view waits); clears at once
    /// when the text is fine again.
    func showContactIssue(_ field: Field, _ shown: Bool) {
        if shown { contactShown.insert(field) } else { contactShown.remove(field) }
    }

    /// Typing again after an offline failure tries the connection afresh.
    func textChanged() {
        failedOffline = false
        failedGenerically = false
    }

    /// Typed while the sheet was opening, before its first field had focus:
    /// goes to that field ("" deletes a character). Caps still apply.
    func typeAhead(_ text: String) {
        func edit(_ value: inout String) {
            if text.isEmpty { _ = value.popLast() } else { value += text }
            value = String(value.prefix(Self.cap(activeField)))
        }
        switch activeField {
        case .name: edit(&name)
        case .alias: edit(&alias)
        case .intention: edit(&intention)
        case .person: edit(&personText)
        case .search: edit(&chooserQuery)
        }
    }

    /// The For row: push "Who is this for?" with an empty search.
    func openChooser() {
        guard step == .form else { return }
        chooserQuery = ""
        step = .choosing
    }

    /// Pick someone (or go back with nil): back to the intention.
    func choose(_ id: String?) {
        if let id { parentId = id }
        step = .form
    }

    func add() async {
        guard canAdd else { return }
        failedGenerically = false
        isSaving = true
        defer { isSaving = false }
        do {
            switch step {
            case .form where tab == .name:
                // Auto-carried while there's room; its page manages the
                // rest. Closes (to that page once it exists; Home for now).
                _ = try await home.addSubject(NewSubject(kind: .soul, publicName: name, alias: alias,
                                                         avatarTone: tone))
                isFinished = true
            case .form:
                try await addIntention(intention, parentId: parentId, row: .intention)
            case .person(let nameId):
                try await addIntention(personText, parentId: nameId, row: .person)
            case .choosing:
                break
            }
        } catch AddSubjectError.offline {
            failedOffline = true
        } catch AddSubjectError.cap {
            failedAtCap = true
        } catch AddSubjectError.input(.contactInfo) {
            contactShown.insert(activeField)
        } catch AddSubjectError.input(_) {
            // Can't happen from this form (caps stop input, empty disables Add).
        } catch {
            failedGenerically = true
        }
    }

    /// Closes, unless the server didn't carry what the toggle asked for: then
    /// it says so and waits for Done.
    private func addIntention(_ text: String, parentId: String, row: CarryRow) async throws {
        let carry = isCarrying(row)
        let input = NewSubject(kind: .intention, publicName: text, parentId: parentId, carry: carry,
                               carryParent: carry && carryOffer(row).alsoCarriesParent)
        let added = try await home.addSubject(input)
        if added.differs(from: input) {
            notCarried = true
        } else {
            isFinished = true
        }
    }

    /// Cancel, or Done once settled.
    func finish() { isFinished = true }
}

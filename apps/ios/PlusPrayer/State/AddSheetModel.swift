import Foundation
import Observation
import PlusPrayerDomain

/// The add sheet's flow (screens.md, "Add sheet", revised 2026-11-06). One
/// sheet, one tap to save:
///
///     form (Name | Intention) ──Add name──▶ offer "Dad is added. Add an intention for Dad?" ──Add──▶ close
///          │                                  (Not now → close; the name is already saved)
///          ├──Add intention──▶ close
///          └──For row──▶ choosing "Who is this for?" ──pick──▶ form
///
/// Every step has a carry row ("Carry onto the list"), so nothing is
/// reported after the fact, except when the server disagrees (the pool
/// filled from another device): "Saved, but not carried…", and an intention
/// then waits for Done instead of closing. The model holds the text, the step, the carry
/// choices and what the toolbar can do; the view owns focus and the live
/// contact check's pause.
@MainActor @Observable
final class AddSheetModel: Identifiable {
    enum Tab: Hashable {
        case name, intention
    }

    enum Field: Hashable {
        case name, alias, intention, offer, search
    }

    enum Step: Equatable {
        case form
        /// The For row's push: pick who the intention is for.
        case choosing
        /// After a name is saved: offer one intention for it.
        case offer(nameId: String)
    }

    /// Where a carry row sits.
    enum CarryRow: Hashable {
        case name, intention, offer
    }

    /// Saved, but the server didn't carry it although the toggle was on.
    enum NotCarried: Equatable {
        /// The name: the offer still follows, with the line under its header.
        case name
        /// An intention (either tab or the offer): Done only.
        case intention
    }

    var tab: Tab
    private(set) var step: Step = .form
    var name = ""
    var alias = ""
    var intention = ""
    /// The offer's intention, for the name just saved.
    var offerText = ""
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

    /// Contact info the view has shown under a field (after the pause).
    private(set) var contactShown: Set<Field> = []
    private(set) var isSaving = false
    /// An add failed for want of a connection (Home's network state covers
    /// the rest).
    private(set) var failedOffline = false
    /// The sheet's work is done: close it.
    private(set) var isFinished = false
    /// The name just saved, as Home will have it (counted by the offer's
    /// carry row until Home's stream brings it).
    private(set) var addedName: Subject?

    /// The server refused for the ~500 cap.
    private(set) var failedAtCap = false
    /// Anything else went wrong: "Couldn't add this right now…". Add stays
    /// available to try again; the text is kept.
    private(set) var failedGenerically = false

    /// "Saved, but not carried. The list's places filled up."
    private(set) var notCarried: NotCarried?

    /// An intention saved but not carried: an end state, Done only.
    var isSettled: Bool { notCarried == .intention }

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
    }

    // MARK: Derived

    /// Home's initials rule, live: the alias's once it has text, else the name's.
    var previewInitials: String {
        let alias = cleanText(self.alias)
        return initials(alias.isEmpty ? cleanText(name) : alias)
    }

    /// What Home will call the name being typed: the alias, else the name
    /// ("Make room for Dad"). Empty while both are.
    var typedLabel: String {
        let alias = cleanText(self.alias)
        return alias.isEmpty ? cleanText(name) : alias
    }

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
        case .offer: .offer
        }
    }

    /// The carry row on screen at this step.
    var activeCarryRow: CarryRow {
        switch step {
        case .form, .choosing: tab == .name ? .name : .intention
        case .offer: .offer
        }
    }

    /// The toolbar's Add. Disabled while the text is empty, while a contact
    /// message shows, offline, at the cap, or saving.
    var canAdd: Bool {
        guard !isSaving, !isOffline, !isAtCap, notCarried != .intention else { return false }
        let text = switch activeField {
        case .name: name
        case .intention: intention
        case .offer: offerText
        case .alias, .search: ""
        }
        if cleanText(text).isEmpty || contactShown.contains(activeField) { return false }
        if activeField == .name && contactShown.contains(.alias) { return false }
        return true
    }

    /// The name just saved, for "{alias} is added." ({alias} falls back to
    /// the name).
    var offerName: String { addedName?.label ?? "" }

    static func cap(_ field: Field) -> Int {
        switch field {
        case .name: TextCap.name
        case .alias: TextCap.alias
        case .intention, .offer: TextCap.intention
        case .search: TextCap.name
        }
    }

    /// Whether the text in `field` would be refused for contact info (aliases
    /// never are).
    func hasContactIssue(_ field: Field) -> Bool {
        switch field {
        case .name: validatePrinted(name, kind: .soul) == .contactInfo
        case .intention: validatePrinted(intention, kind: .intention) == .contactInfo
        case .offer: validatePrinted(offerText, kind: .intention) == .contactInfo
        case .alias, .search: false
        }
    }

    // MARK: The carry row

    /// What the pool allows for this row, now.
    func carryOffer(_ row: CarryRow) -> CarryOffer {
        switch row {
        case .name: home.carryOffer(kind: .soul, parentId: nil)
        case .intention: home.carryOffer(kind: .intention, parentId: parentId)
        case .offer: home.carryOffer(kind: .intention, parentId: addedName?.id, justAdded: addedName)
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
        carryMeter(carryOffer(row), kind: row == .name ? .soul : .intention, isOn: isCarrying(row))
    }

    /// "Also carries Dad · uses 2 places": the toggle is on and it carries
    /// the intention's name too, at this true cost. The cost is nil when the
    /// meter already says it takes the last places (no repeating it).
    func alsoCarries(_ row: CarryRow) -> (name: String, cost: Int?)? {
        let offer = carryOffer(row)
        guard isCarrying(row), offer.alsoCarriesParent else { return nil }
        let cost: Int? = if case .usesLast = meter(row) { nil } else { offer.cost }
        switch row {
        case .name: return nil
        case .intention: return parent.map { ($0.label, cost) }
        case .offer: return (offerName, cost)
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
                let input = NewSubject(kind: .soul, publicName: name, alias: alias, avatarTone: tone,
                                       carry: isCarrying(.name))
                let added = try await home.addSubject(input)
                let alias = cleanText(self.alias)
                addedName = Subject(id: added.id, kind: .soul, publicName: cleanText(name),
                                    alias: alias.isEmpty ? nil : alias, isCarried: added.isCarried,
                                    sortOrder: .max, avatarTone: tone, createdAt: .now)
                offerText = ""
                notCarried = added.differs(from: input) ? .name : nil
                step = .offer(nameId: added.id)
            case .form:
                try await addIntention(intention, parentId: parentId, row: .intention)
            case .offer(let nameId):
                try await addIntention(offerText, parentId: nameId, row: .offer)
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
            notCarried = .intention
        } else {
            isFinished = true
        }
    }

    /// Not now, Cancel, Done.
    func finish() { isFinished = true }
}

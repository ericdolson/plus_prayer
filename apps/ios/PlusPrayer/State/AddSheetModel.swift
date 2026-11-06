import Foundation
import Observation
import PlusPrayerDomain

/// The add sheet's flow (screens.md, "Add sheet" and its Details). One sheet,
/// one tap to save:
///
///     form (Name | Intention) ──Add name──▶ offer "Dad is on your list. Add an intention for Dad?"
///          │                       └─pool full─▶ savedPrivately (+ the same offer below the message)
///          └──Add intention──▶ close  (pool full → savedPrivately, Done only)
///     offer / savedPrivately ──Add──▶ close      (Not now → close; the name is already saved)
///
/// The model holds the text, the step and what the toolbar can do; the view
/// owns focus and the live contact check's pause.
@MainActor @Observable
final class AddSheetModel: Identifiable {
    enum Tab: Hashable {
        case name, intention
    }

    enum Field: Hashable {
        case name, alias, intention, offer
    }

    enum Step: Equatable {
        case form
        /// After a carried name: offer one intention for it.
        case offer(nameId: String)
        /// The pool was full: saved for your own prayers. A name still gets
        /// the intention offer below the message; an intention gets Done.
        case savedPrivately(subjectId: String, kind: SubjectKind, invitation: PoolFullInvitation)
    }

    var tab: Tab
    private(set) var step: Step = .form
    var name = ""
    var alias = ""
    var intention = ""
    /// The offer's intention, for the name just saved.
    var offerText = ""
    /// The intention's name (the picker); Me by default.
    var parentId: String
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
    /// The name or intention just saved, by its label, for the step lines.
    private(set) var savedLabel = ""

    /// The server refused for the ~500 cap.
    private(set) var failedAtCap = false
    /// Anything else went wrong: "Couldn't add this right now…". Add stays
    /// available to try again; the text is kept.
    private(set) var failedGenerically = false

    private let home: HomeModel
    /// Until the Membership screen exists, its invitation stays hidden
    /// (screens.md) and "shown today" isn't spent.
    private let membershipAvailable: Bool

    init(home: HomeModel, tab: Tab = .name, parentId: String? = nil, membershipAvailable: Bool = false) {
        self.home = home
        self.tab = tab
        self.parentId = parentId ?? home.pickerNames.first?.id ?? ""
        self.membershipAvailable = membershipAvailable
        tone = home.toneForNewName()
    }

    // MARK: Derived

    /// Home's initials rule, live: the alias's once it has text, else the name's.
    var previewInitials: String {
        let alias = cleanText(self.alias)
        return initials(alias.isEmpty ? cleanText(name) : alias)
    }

    var isOffline: Bool { !home.isOnline || failedOffline }

    /// At the ~500 cap: the line at the top, Add disabled.
    var isAtCap: Bool { failedAtCap || home.subjectCount >= subjectCap }

    /// "Your free place on the list is in use." vs "All {pool} places …".
    var isFreePool: Bool { home.isFreePool }
    var poolLimit: Int { home.poolLimit }

    var parent: PickerName? { home.pickerNames.first { $0.id == parentId } }

    /// The field Add saves from, at this step.
    var activeField: Field {
        switch step {
        case .form: tab == .name ? .name : .intention
        case .offer, .savedPrivately: .offer
        }
    }

    /// The toolbar's Add. Disabled while the text is empty, while a contact
    /// message shows, offline, or saving.
    var canAdd: Bool {
        guard !isSaving, !isOffline, !isAtCap else { return false }
        if case .savedPrivately(_, .intention, _) = step { return false }
        let text = switch activeField {
        case .name: name
        case .intention: intention
        default: offerText
        }
        if cleanText(text).isEmpty || contactShown.contains(activeField) { return false }
        if activeField == .name && contactShown.contains(.alias) { return false }
        return true
    }

    /// The name just saved, for "{alias} is on your list…" ({alias} falls back
    /// to the name).
    var offerName: String { savedLabel }

    static func cap(_ field: Field) -> Int {
        switch field {
        case .name: TextCap.name
        case .alias: TextCap.alias
        case .intention, .offer: TextCap.intention
        }
    }

    /// Whether the text in `field` would be refused for contact info (aliases
    /// never are).
    func hasContactIssue(_ field: Field) -> Bool {
        switch field {
        case .name: validatePrinted(name, kind: .soul) == .contactInfo
        case .intention: validatePrinted(intention, kind: .intention) == .contactInfo
        case .offer: validatePrinted(offerText, kind: .intention) == .contactInfo
        case .alias: false
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

    func add() async {
        guard canAdd else { return }
        failedGenerically = false
        isSaving = true
        defer { isSaving = false }
        do {
            switch step {
            case .form where tab == .name:
                let added = try await home.addSubject(NewSubject(kind: .soul, publicName: name, alias: alias,
                                                                 avatarTone: tone))
                // What Home will call them: the alias, else the name.
                let alias = cleanText(self.alias)
                savedLabel = alias.isEmpty ? cleanText(name) : alias
                offerText = ""
                step = added.isCarried
                    ? .offer(nameId: added.id)
                    : .savedPrivately(subjectId: added.id, kind: .soul, invitation: invitation())
            case .form:
                let added = try await home.addSubject(NewSubject(kind: .intention, publicName: intention,
                                                                 parentId: parentId))
                if added.isCarried {
                    isFinished = true
                } else {
                    savedLabel = cleanText(intention)
                    step = .savedPrivately(subjectId: added.id, kind: .intention,
                                           invitation: invitation())
                }
            case .offer(let nameId), .savedPrivately(let nameId, .soul, _):
                _ = try await home.addSubject(NewSubject(kind: .intention, publicName: offerText, parentId: nameId))
                isFinished = true
            case .savedPrivately:
                isFinished = true
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

    /// The invitation under the pool-full line; membership only once that
    /// screen exists, and only then is it recorded as shown today.
    private func invitation() -> PoolFullInvitation {
        let invitation = home.poolFullInvitation()
        guard case .membership = invitation else { return invitation }
        guard membershipAvailable else { return .portionLink }
        home.recordMembershipInvitationShown()
        return invitation
    }

    /// Not now, Done, Cancel.
    func finish() { isFinished = true }
}

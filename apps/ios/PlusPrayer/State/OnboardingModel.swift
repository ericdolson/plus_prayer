import Foundation
import Observation
import PlusPrayerDomain

/// First run (auth-onboarding.md, "Flow (revised 2026-11-09)"): one native
/// navigation stack over Home, one decision per screen.
///
///     Welcome ──Begin──▶ Name ──Continue (setSelfName)──▶ Welcome back
///     Welcome back ──Add someone──▶ Someone ──Continue──▶ Intention
///     Intention ──Add / Skip (addSubject ×1–2)──▶ Welcome back, with the row
///     Welcome back ──Add others later / Continue──▶ Home
///     Welcome back ──Add another──▶ the regular add sheet over it
///
/// Shown while Home's header has no self name; once the name is saved it
/// stays up for the rest of this run only (resume is state-based: a later
/// launch with a name opens Home). The guided add saves the person when
/// leaving the intention screen (Add or Skip): one save sequence, so going
/// back from it never leaves a half-made person. If the person saved but the
/// intention didn't, the intention screen keeps its text, hides ‹ (the
/// person can't be edited from here any more), and Add retries only the
/// intention.
@MainActor @Observable
final class OnboardingModel {
    enum Screen: Hashable {
        case name, welcomeBack, someone, intention
    }

    /// What went wrong saving the name (the name step's existing lines).
    enum NameProblem: Equatable {
        case contact, offline, failed
    }

    /// What went wrong in the guided add (the add sheet's existing lines).
    enum AddProblem: Equatable {
        case offline, cap, failed
    }

    /// The fields that show the live contact-info message.
    enum Field: Hashable {
        case personName, intention
    }

    /// The pushed screens; Welcome is the root.
    var path: [Screen] = []

    // MARK: Name

    var name = ""
    /// The name screen's avatar tone; the new self takes it.
    let selfTone: Int
    private(set) var savingName = false
    private(set) var nameProblem: NameProblem?
    /// What setSelfName last saved (Continue again with it unchanged just
    /// moves on).
    private(set) var savedName: String?

    // MARK: The guided add

    var personName = ""
    var personAlias = ""
    var intention = ""
    private(set) var personTone: Int
    private(set) var saving = false
    private(set) var addProblem: AddProblem?
    /// Contact info the view has shown under a field (after the pause).
    private(set) var contactShown: Set<Field> = []
    /// The person, once saved, while their intention is still unsaved.
    private(set) var savedPersonId: String?

    /// The people added in this run, in order (the guided add and the add
    /// sheet): screen 3's row. Never the user.
    private(set) var addedIds: [String] = []

    /// Home: "Add others later" or Continue.
    private(set) var isFinished = false

    private let home: HomeModel

    init(home: HomeModel) {
        self.home = home
        selfTone = home.toneForNewName()
        personTone = home.toneForNewName()
    }

    // MARK: Derived

    /// The name screen's avatar: initials as you type (a person glyph while empty).
    var nameInitials: String { initials(cleanText(name)) }

    var canContinueName: Bool { !savingName && validatePrinted(name, kind: .soul) == nil }

    /// "Welcome, {full name}.": the full name as saved, never split.
    var greeting: String { greetingName(home.header) ?? savedName ?? cleanText(name) }

    /// What you call them, else their name: the avatar, "{alias} will be
    /// carried…" and "What are you praying for, for {alias}?".
    var personLabel: String { PlusPrayerDomain.personLabel(name: personName, alias: personAlias) }

    var personInitials: String { initials(personLabel) }

    /// "{alias} will be carried on the list with you." once a name is entered.
    var showsCarriedLine: Bool { !cleanText(personName).isEmpty }

    var isOffline: Bool { !home.isOnline }

    /// Screen 4's Continue: a printable name, no contact message showing.
    var canContinuePerson: Bool {
        validatePrinted(personName, kind: .soul) == nil && validateAlias(personAlias) == nil
            && !contactShown.contains(.personName)
    }

    /// Screen 5's Add: an intention to save, and nothing in the way.
    var canAddIntention: Bool {
        canSave && validatePrinted(intention, kind: .intention) == nil && !contactShown.contains(.intention)
    }

    /// Skip (and Add) need the connection; the save is online-only.
    var canSave: Bool { !saving && !isOffline && canContinuePerson }

    /// The person is saved, so ‹ back to their fields would edit nothing.
    var personLocked: Bool { savedPersonId != nil }

    /// Screen 3's row: only the people added, in order; never you.
    var added: [PickerName] {
        let names = home.pickerNames()
        return addedIds.compactMap { id in names.first { $0.id == id } }
    }

    // MARK: Fields

    func hasContactIssue(_ field: Field) -> Bool {
        switch field {
        case .personName: validatePrinted(personName, kind: .soul) == .contactInfo
        case .intention: validatePrinted(intention, kind: .intention) == .contactInfo
        }
    }

    /// The live check, after typing pauses (the view waits); clears at once
    /// when the text is fine again.
    func showContactIssue(_ field: Field, _ shown: Bool) {
        if shown { contactShown.insert(field) } else { contactShown.remove(field) }
    }

    func nameChanged() { nameProblem = nil }

    /// Typing again clears a failed save's line.
    func textChanged() { addProblem = nil }

    // MARK: Commands

    func begin() { path = [.name] }

    /// Continue on the name screen: setSelfName (online only), then Welcome back.
    func submitName() async {
        guard canContinueName else {
            if validatePrinted(name, kind: .soul) == .contactInfo { nameProblem = .contact }
            return
        }
        let cleaned = cleanText(name)
        if cleaned == savedName {
            show(.welcomeBack)
            return
        }
        savingName = true
        defer { savingName = false }
        do {
            try await home.setSelfName(cleaned, avatarTone: selfTone)
            savedName = cleaned
            nameProblem = nil
            show(.welcomeBack)
        } catch SelfNameError.input {
            nameProblem = .contact
        } catch SelfNameError.offline {
            nameProblem = .offline
        } catch {
            nameProblem = .failed
        }
    }

    /// "＋ Add someone": a fresh guided add.
    func addSomeone() {
        personName = ""
        personAlias = ""
        intention = ""
        personTone = home.toneForNewName()
        savedPersonId = nil
        addProblem = nil
        contactShown = []
        show(.someone)
    }

    /// Screen 4's Continue: on to the intention (nothing saved yet).
    func continueToIntention() {
        guard canContinuePerson else { return }
        show(.intention)
    }

    /// Add (with the intention) or Skip: saves the person, carried by default
    /// (addSubject), then the intention under them, which becomes their
    /// chosen one (Q32: they have none yet). Then back to Welcome back.
    func save(withIntention: Bool) async {
        guard withIntention ? canAddIntention : canSave else { return }
        saving = true
        addProblem = nil
        defer { saving = false }
        do {
            let personId: String
            if let savedPersonId {
                personId = savedPersonId
            } else {
                let person = try await home.addSubject(NewSubject(kind: .soul, publicName: personName,
                                                                  alias: personAlias, avatarTone: personTone))
                personId = person.id
                savedPersonId = person.id
                addedIds.append(person.id)
            }
            if withIntention {
                _ = try await home.addSubject(NewSubject(kind: .intention, publicName: intention,
                                                         parentId: personId, carry: true))
            }
            savedPersonId = nil
            backToWelcomeBack()
        } catch AddSubjectError.offline {
            addProblem = .offline
        } catch AddSubjectError.cap {
            addProblem = .cap
        } catch AddSubjectError.input(.contactInfo) {
            contactShown.insert(savedPersonId == nil ? .personName : .intention)
        } catch {
            addProblem = .failed
        }
    }

    /// A name added through the regular add sheet ("＋ Add another").
    func addedFromSheet(_ id: String?) {
        guard let id, !addedIds.contains(id) else { return }
        addedIds.append(id)
    }

    /// "Add others later" or Continue: Home.
    func finish() { isFinished = true }

    private func show(_ screen: Screen) {
        if path.last != screen { path.append(screen) }
    }

    private func backToWelcomeBack() {
        if let i = path.firstIndex(of: .welcomeBack) {
            path = Array(path.prefix(through: i))
        } else {
            path = [.name, .welcomeBack]
        }
    }
}

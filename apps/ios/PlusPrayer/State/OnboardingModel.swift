import Foundation
import Observation
import PlusPrayerDomain

/// First run (auth-onboarding.md, "Flow (redesigned 2026-11-09, second
/// pass)"): one stage over Home, four steps, then the hand-off into Home.
///
///     name ──Continue (setSelfName)──▶ moment ──Continue──▶ someone
///     someone ──Continue──▶ intention ──Add / Skip (addSubject ×1–2)──▶ handoff
///     someone ──Not now──▶ handoff
///     ‹ Back: moment → name, someone → moment, intention → someone
///
/// Shown while Home's header has no self name; once the name is saved it
/// stays up for the rest of this run only (resume is state-based: a later
/// launch with a name opens Home). The person is saved when leaving the
/// intention step (Add or Skip): one save sequence, so going back from it
/// never leaves a half-made person. If the person saved but the intention
/// didn't, the step keeps its text, hides ‹ (the person can't be edited from
/// here any more), and Add retries only the intention.
@MainActor @Observable
final class OnboardingModel {
    enum Step: Int, Comparable {
        case name, moment, someone, intention, handoff

        static func < (lhs: Step, rhs: Step) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    /// What went wrong saving the name (the name step's existing lines).
    enum NameProblem: Equatable {
        case contact, offline, failed
    }

    /// What went wrong saving the person (the add sheet's existing lines).
    enum AddProblem: Equatable {
        case offline, cap, failed
    }

    /// The fields that show the live contact-info message.
    enum Field: Hashable {
        case personName, intention
    }

    private(set) var step: Step = .name

    // MARK: Your name

    var name = ""
    /// The user's avatar tone; the new self takes it.
    let selfTone: Int
    private(set) var savingName = false
    private(set) var nameProblem: NameProblem?
    /// What setSelfName last saved (Continue again with it unchanged just
    /// moves on).
    private(set) var savedName: String?

    // MARK: Someone you pray for

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
    /// The person this run added: the hand-off takes their avatar into
    /// their row on Home.
    private(set) var addedPersonId: String?

    /// The hand-off has played: Home.
    private(set) var isFinished = false

    private let home: HomeModel

    init(home: HomeModel) {
        self.home = home
        selfTone = home.toneForNewName()
        personTone = home.toneForNewName()
    }

    // MARK: Derived

    /// The name as it will print (cleaned; the full name, never split).
    var displayName: String { cleanText(name) }

    /// The user's avatar: initials of the name.
    var nameInitials: String { initials(displayName) }

    var canContinueName: Bool { !savingName && validatePrinted(name, kind: .soul) == nil }

    /// "List 53" on the paper line: the list your name goes on (tomorrow's).
    var nextListNumber: Int? { home.listContext.map { $0.listNumber + 1 } }

    /// What you call them, else their name: their avatar, the name under it
    /// and "What are you praying for, for {alias}?".
    var personLabel: String { PlusPrayerDomain.personLabel(name: personName, alias: personAlias) }

    var personInitials: String { initials(personLabel) }

    /// Their avatar forms with the first letter of their name.
    var hasPerson: Bool { !cleanText(personName).isEmpty }

    var isOffline: Bool { !home.isOnline }

    /// The person step's Continue: a printable name, no contact message showing.
    var canContinuePerson: Bool {
        validatePrinted(personName, kind: .soul) == nil && validateAlias(personAlias) == nil
            && !contactShown.contains(.personName)
    }

    /// The intention step's Add: an intention to save, and nothing in the way.
    var canAddIntention: Bool {
        canSave && validatePrinted(intention, kind: .intention) == nil && !contactShown.contains(.intention)
    }

    /// Skip (and Add) need the connection; the save is online-only.
    var canSave: Bool { !saving && !isOffline && canContinuePerson }

    /// The person is saved, so ‹ back to their fields would edit nothing.
    var personLocked: Bool { savedPersonId != nil }

    /// ‹ Back in the top-leading slot (steps 2–4), unless something is saving
    /// or the person is already saved.
    var canGoBack: Bool {
        switch step {
        case .moment, .someone: true
        case .intention: !personLocked && !saving
        case .name, .handoff: false
        }
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

    /// Continue (or Return) on the name: setSelfName (online only), then the
    /// moment. The same name again (after ‹) just moves on.
    func submitName() async {
        guard step == .name else { return }
        guard canContinueName else {
            if validatePrinted(name, kind: .soul) == .contactInfo { nameProblem = .contact }
            return
        }
        let cleaned = displayName
        if cleaned == savedName {
            step = .moment
            return
        }
        savingName = true
        defer { savingName = false }
        do {
            try await home.setSelfName(cleaned, avatarTone: selfTone)
            savedName = cleaned
            nameProblem = nil
            step = .moment
        } catch SelfNameError.input {
            nameProblem = .contact
        } catch SelfNameError.offline {
            nameProblem = .offline
        } catch {
            nameProblem = .failed
        }
    }

    /// The moment's Continue: someone you pray for. Their tone is picked now,
    /// among the tones least used with yours in.
    func continueFromMoment() {
        guard step == .moment else { return }
        if !hasPerson && savedPersonId == nil {
            var generator = SystemRandomNumberGenerator()
            personTone = pickTone(home.pickerNames().map(\.tone) + [selfTone], using: &generator)
        }
        step = .someone
    }

    /// The person step's Continue: on to their intention (nothing saved yet).
    func continueToIntention() {
        guard step == .someone, canContinuePerson else { return }
        step = .intention
    }

    /// "Not now" on the person step: Home, with no one added.
    func notNow() {
        guard step == .someone else { return }
        personName = ""
        personAlias = ""
        intention = ""
        contactShown = []
        addProblem = nil
        step = .handoff
    }

    /// ‹ Back: one step back, the text kept.
    func back() {
        guard canGoBack else { return }
        switch step {
        case .moment: step = .name
        case .someone: step = .moment
        case .intention: step = .someone
        case .name, .handoff: break
        }
    }

    /// Add (with the intention) or Skip: saves the person, carried by default
    /// (addSubject: the pre-trial pool), then the intention under them, which
    /// becomes their chosen one (Q32: they have none yet). Then the hand-off.
    func save(withIntention: Bool) async {
        guard step == .intention, withIntention ? canAddIntention : canSave else { return }
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
                addedPersonId = person.id
            }
            if withIntention {
                _ = try await home.addSubject(NewSubject(kind: .intention, publicName: intention,
                                                         parentId: personId, carry: true))
            }
            savedPersonId = nil
            step = .handoff
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

    /// The hand-off has played: Home.
    func finish() {
        guard step == .handoff else { return }
        isFinished = true
    }
}

import 'local_date.dart';

/// getMyHeader: the signed-in user's stored fields. Display values (effective
/// streak, "prayed with the list today") are derived in `rules/streak.dart`.
class UserHeader {
  const UserHeader({
    required this.id,
    required this.includeLimit,
    this.displayName,
    this.selfSubjectId,
    this.selfAvatarTone,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastListLocalDate,
    this.graceDays = 0,
    this.graceOfferPending = false,
    this.graceOffersEnabled = true,
    this.trialStartedAt,
    this.entitlementExpiresAt,
  });

  final String id;

  /// Null until setSelfName — onboarding resumes at "What's your name?".
  final String? displayName;
  final String? selfSubjectId;
  final int? selfAvatarTone;
  final int currentStreak;
  final int bestStreak;

  /// Last local day the user prayed WITH THE LIST.
  final LocalDate? lastListLocalDate;
  final int graceDays;
  final bool graceOfferPending;
  final bool graceOffersEnabled;

  /// Pool size beyond the self name while an entitlement is active.
  final int includeLimit;
  final DateTime? trialStartedAt;
  final DateTime? entitlementExpiresAt;

  bool get hasSelfName => displayName != null && selfSubjectId != null;

  UserHeader copyWith({
    int? currentStreak,
    int? bestStreak,
    LocalDate? lastListLocalDate,
    int? graceDays,
  }) =>
      UserHeader(
        id: id,
        includeLimit: includeLimit,
        displayName: displayName,
        selfSubjectId: selfSubjectId,
        selfAvatarTone: selfAvatarTone,
        currentStreak: currentStreak ?? this.currentStreak,
        bestStreak: bestStreak ?? this.bestStreak,
        lastListLocalDate: lastListLocalDate ?? this.lastListLocalDate,
        graceDays: graceDays ?? this.graceDays,
        graceOfferPending: graceOfferPending,
        graceOffersEnabled: graceOffersEnabled,
        trialStartedAt: trialStartedAt,
        entitlementExpiresAt: entitlementExpiresAt,
      );
}

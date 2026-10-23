// What You shows for membership (monetization.md: a 14-day reverse trial from
// the first prayer, then a subscription).

import '../models/user_header.dart';

enum MembershipState { free, trial, member }

const reverseTrialLength = Duration(days: 14);

/// An active entitlement that ends within the trial window is the trial;
/// anything longer is a subscription.
MembershipState membershipState(UserHeader user, DateTime now) {
  final until = user.entitlementExpiresAt;
  if (until == null || !until.isAfter(now)) return MembershipState.free;
  final trialStart = user.trialStartedAt;
  if (trialStart != null && !until.isAfter(trialStart.add(reverseTrialLength))) return MembershipState.trial;
  return MembershipState.member;
}

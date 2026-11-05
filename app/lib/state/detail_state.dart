// The detail page's derived state (detail-page.md): its status line, from the
// same carry status and closing window as the community card.

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/rules/detail_status.dart';
import 'home_state.dart';
import 'providers.dart';

final detailStatusProvider = Provider.autoDispose.family<DetailStatus?, String>((ref, id) {
  final tree = ref.watch(subjectTreeProvider).value;
  final subject = tree?[id];
  if (tree == null || subject == null) return null;
  final card = ref.watch(communityCardProvider);
  return detailStatus(
    subject,
    tree,
    list: card?.list,
    tomorrow: card?.carry.status,
    closingMinutes: ref.watch(closingSoonMinutesProvider),
  );
});

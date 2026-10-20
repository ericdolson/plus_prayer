// One add sheet, two entry points (screens.md):
// - From the footer ＋: "Add name" (40); can switch to an intention, which
//   reveals a name picker (default "Me").
// - From a name (long-press its row; its detail page at step 5): "Add
//   intention for {alias}" (80), picker hidden.
// Optional alias for names. New items go to the bottom. After adding a name,
// offer once: "Add an intention for Dad?".
// Names and intentions can't include contact info or links — inline, as the
// user types (domain/rules/validation.dart; the server checks the same).

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/repositories/repositories.dart';
import '../../domain/models/subject.dart';
import '../../domain/rules/validation.dart';
import '../../l10n/app_localizations.dart';
import '../../state/home_state.dart';
import '../../state/providers.dart';
import '../../theme/pp_theme.dart';

Future<void> showAddSheet(BuildContext context, {String? forNameId}) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddSheet(forNameId: forNameId),
    );

class AddSheet extends HookConsumerWidget {
  const AddSheet({super.key, this.forNameId});

  /// Set when opened from a name: intention for that name, picker hidden.
  final String? forNameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final tree = ref.watch(subjectTreeProvider).value;

    // The name an intention is for, when fixed (entry from a name, or the
    // "Add an intention for Dad?" follow-up).
    final fixedName = useState<String?>(forNameId);
    final kind = useState(forNameId == null ? SubjectKind.soul : SubjectKind.intention);
    final pickedName = useState<String?>(null);
    final offerFor = useState<String?>(null); // id of the name just added
    final offered = useState(false);
    final busy = useState(false);
    final serverError = useState<String?>(null);
    final text = useTextEditingController();
    final alias = useTextEditingController();
    useListenable(text);

    if (tree == null) return const SizedBox.shrink();
    final selfId = tree.self?.id;
    final parentId = fixedName.value ?? pickedName.value ?? selfId;
    String labelOf(String? id) {
      final s = id == null ? null : tree[id];
      return s == null ? '' : s.label;
    }

    final issue = validatePrinted(text.text, kind.value);
    final inlineError = serverError.value ??
        switch (issue) {
          TextIssue.contactInfo => l10n.errorContact,
          TextIssue.tooLong => l10n.errorTooLong(TextCaps.forKind(kind.value)),
          _ => null,
        };
    final canSave = issue == null && !busy.value && (kind.value == SubjectKind.soul || parentId != null);

    Future<void> save() async {
      if (!canSave) return;
      busy.value = true;
      serverError.value = null;
      try {
        final isName = kind.value == SubjectKind.soul;
        final added = await ref.read(subjectRepositoryProvider).addSubject(NewSubject(
              kind: kind.value,
              publicName: text.text,
              parentId: isName ? null : parentId,
              alias: isName && alias.text.trim().isNotEmpty ? alias.text : null,
            ));
        if (!added.isCarried) ref.read(justAddedNotCarriedProvider.notifier).add(added.id);
        if (!context.mounted) return;
        if (isName && !offered.value) {
          offered.value = true;
          offerFor.value = added.id;
          return;
        }
        Navigator.of(context).pop();
      } on SubjectInputError catch (e) {
        serverError.value = e.issue == TextIssue.contactInfo ? l10n.errorContact : null;
      } on OfflineError {
        serverError.value = l10n.errorOffline;
      } on SubjectCapError {
        serverError.value = l10n.errorCap;
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final padding = EdgeInsetsDirectional.fromSTEB(pp.space.xl, 0, pp.space.xl, pp.space.xl + insets);

    // "Add an intention for Dad?" — offered once, right after adding a name.
    if (offerFor.value != null) {
      final name = labelOf(offerFor.value);
      return Padding(
        padding: padding,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.offerIntention(name), style: context.text.titleLarge),
              SizedBox(height: pp.space.xl),
              FilledButton(
                onPressed: () {
                  fixedName.value = offerFor.value;
                  kind.value = SubjectKind.intention;
                  offerFor.value = null;
                  text.clear();
                  alias.clear();
                },
                child: Text(l10n.addIntention),
              ),
              SizedBox(height: pp.space.sm),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.notNow)),
            ],
          ),
        ),
      );
    }

    final isName = kind.value == SubjectKind.soul;
    final title = fixedName.value != null
        ? l10n.addIntentionFor(labelOf(fixedName.value))
        : (isName ? l10n.addName : l10n.addIntention);

    return Padding(
      padding: padding,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: context.text.titleLarge),
            SizedBox(height: pp.space.lg),
            if (fixedName.value == null) ...[
              SegmentedButton<SubjectKind>(
                segments: [
                  ButtonSegment(value: SubjectKind.soul, label: Text(l10n.kindName)),
                  ButtonSegment(value: SubjectKind.intention, label: Text(l10n.kindIntention)),
                ],
                selected: {kind.value},
                showSelectedIcon: false,
                onSelectionChanged: (s) {
                  kind.value = s.first;
                  serverError.value = null;
                },
              ),
              SizedBox(height: pp.space.lg),
            ],
            if (!isName && fixedName.value == null) ...[
              DropdownButtonFormField<String>(
                initialValue: parentId,
                decoration: InputDecoration(labelText: l10n.fieldFor),
                dropdownColor: pp.colors.surfaceRaised,
                items: [
                  for (final n in tree.names.where((n) => !n.isResolved))
                    DropdownMenuItem(value: n.id, child: Text(n.label, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (id) => pickedName.value = id,
              ),
              SizedBox(height: pp.space.md),
            ],
            TextField(
              controller: text,
              autofocus: true,
              maxLength: TextCaps.forKind(kind.value),
              maxLines: isName ? 1 : 3,
              minLines: 1,
              textCapitalization: isName ? TextCapitalization.words : TextCapitalization.sentences,
              textInputAction: isName ? TextInputAction.next : TextInputAction.done,
              onChanged: (_) => serverError.value = null,
              onSubmitted: isName ? null : (_) => save(),
              decoration: InputDecoration(
                labelText: isName ? l10n.fieldName : l10n.fieldIntention,
                errorText: inlineError,
                errorMaxLines: 3,
              ),
            ),
            if (isName) ...[
              SizedBox(height: pp.space.sm),
              TextField(
                controller: alias,
                maxLength: TextCaps.alias,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => save(),
                decoration: InputDecoration(labelText: l10n.fieldAlias, helperText: l10n.fieldAliasHelper),
              ),
            ],
            SizedBox(height: pp.space.lg),
            FilledButton(
              onPressed: canSave ? save : null,
              child: busy.value
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: pp.colors.onEmber),
                    )
                  : Text(l10n.add),
            ),
          ],
        ),
      ),
    );
  }
}

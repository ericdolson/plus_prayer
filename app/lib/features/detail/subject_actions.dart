// A subject's actions (detail-page.md "⋯ menu"), one sheet for the detail
// page's ⋯ and Home's long-press, running the same commands:
//
//   [Add intention]   names, from Home only (the page has its own link)
//   Edit              name/alias; the self's name (R10 limits); intention text
//   Answered          open intentions; no thanks note in v1
//   Release           open intentions; confirm, then off the page
//   Archive           not the self; confirm (a name's intentions go too),
//                     then off the page
//
// The commands are online for now: offline they say so and change nothing.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/repositories/repositories.dart';
import '../../domain/models/subject.dart';
import '../../domain/rules/validation.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../theme/pp_icons.dart';
import '../../theme/pp_theme.dart';
import '../add/add_sheet.dart';

/// [onGone]: the subject left the active list (Released, Archived) — the
/// detail page pops back. [withAddIntention]: Home's quick actions on a name.
Future<void> showSubjectActions(
  BuildContext context,
  Subject subject, {
  VoidCallback? onGone,
  bool withAddIntention = false,
}) =>
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => _ActionsSheet(
        subject: subject,
        withAddIntention: withAddIntention,
        // Run with the caller's context: the sheet is gone by then.
        run: (action) {
          Navigator.pop(sheet);
          action(context);
        },
        onGone: onGone,
      ),
    );

class _ActionsSheet extends ConsumerWidget {
  const _ActionsSheet({required this.subject, required this.withAddIntention, required this.run, this.onGone});

  final Subject subject;
  final bool withAddIntention;
  final void Function(Future<void> Function(BuildContext context) action) run;
  final VoidCallback? onGone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final s = subject;
    final open = s.isIntention && !s.isResolved;
    final repo = ref.read(subjectRepositoryProvider);
    // Read now: the actions run after this sheet is gone.
    final hasIntentions = s.isName && (ref.read(subjectTreeProvider).value?.intentionsOf(s.id).isNotEmpty ?? false);

    Widget tile(IconData? icon, String label, Future<void> Function(BuildContext context) action) => ListTile(
          contentPadding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.xl),
          leading: icon == null ? SizedBox(width: pp.size.rowIcon) : Icon(icon, color: pp.colors.ink),
          title: Text(label, style: context.text.bodyLarge),
          onTap: () => run(action),
        );

    return SafeArea(
      child: Padding(
        padding: EdgeInsetsDirectional.only(bottom: pp.space.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(pp.space.xl, 0, pp.space.xl, pp.space.sm),
              child: Text(s.label, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (withAddIntention && s.isName)
              tile(PPIcons.add, l10n.addIntention, (c) => showAddSheet(c, forNameId: s.id)),
            tile(PPIcons.edit, l10n.actionEdit, (c) => showEditSheet(c, s)),
            if (open) ...[
              tile(PPIcons.check, l10n.actionAnswered, (c) => _guard(c, () => repo.markAnswered(s.id))),
              tile(null, l10n.actionRelease, (c) async {
                if (!await _confirm(c, l10n.releaseQuestion, l10n.actionRelease)) return;
                if (!c.mounted) return;
                if (await _guard(c, () => repo.release(s.id))) onGone?.call();
              }),
            ],
            if (!s.isSelf)
              tile(PPIcons.archive, l10n.actionArchive, (c) async {
                final question = hasIntentions ? l10n.archiveNameQuestion(s.label) : l10n.archiveQuestion(s.label);
                if (!await _confirm(c, question, l10n.actionArchive)) return;
                if (!c.mounted) return;
                if (await _guard(c, () => repo.archive(s.id))) onGone?.call();
              }),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirm(BuildContext context, String question, String action) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text(question),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(L10n.of(dialog).cancel)),
          TextButton(onPressed: () => Navigator.of(dialog).pop(true), child: Text(action)),
        ],
      ),
    ) ??
    false;

/// Runs an online command; offline, says so. True when it went through.
Future<bool> _guard(BuildContext context, Future<void> Function() command) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final offline = L10n.of(context).errorNeedsConnection;
  try {
    await command();
    return true;
  } on OfflineError {
    messenger?.showSnackBar(SnackBar(content: Text(offline)));
    return false;
  }
}

Future<void> showEditSheet(BuildContext context, Subject subject) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditSheet(subject: subject),
    );

/// Edit: the printed text and, for a name, the alias. The self's name goes
/// through setSelfName (free until first printed, then once per 7 days); its
/// alias stays "Me".
class EditSheet extends HookConsumerWidget {
  const EditSheet({super.key, required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final s = subject;
    final withAlias = s.isName && !s.isSelf;
    final text = useTextEditingController(text: s.publicName);
    final alias = useTextEditingController(text: s.alias ?? '');
    final busy = useState(false);
    final serverError = useState<String?>(null);
    useListenable(text);

    final issue = validatePrinted(text.text, s.kind);
    final inlineError = serverError.value ??
        switch (issue) {
          TextIssue.contactInfo => l10n.errorContact,
          TextIssue.tooLong => l10n.errorTooLong(TextCaps.forKind(s.kind)),
          _ => null,
        };
    final canSave = issue == null && !busy.value;

    Future<void> save() async {
      if (!canSave) return;
      busy.value = true;
      serverError.value = null;
      final repo = ref.read(subjectRepositoryProvider);
      try {
        if (s.isSelf) {
          await repo.setSelfName(text.text);
        } else {
          await repo.updateSubject(s.id, publicName: text.text, alias: withAlias ? alias.text : null);
        }
        if (context.mounted) Navigator.of(context).pop();
      } on SubjectInputError catch (e) {
        serverError.value = e.issue == TextIssue.contactInfo ? l10n.errorContact : null;
      } on SelfNameTooSoonError catch (e) {
        serverError.value = l10n.selfNameTooSoon(e.nextAvailable);
      } on OfflineError {
        serverError.value = l10n.errorNeedsConnection;
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(pp.space.xl, 0, pp.space.xl, pp.space.xl + insets),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.isName ? l10n.editName : l10n.editIntention, style: context.text.titleLarge),
            SizedBox(height: pp.space.lg),
            TextField(
              controller: text,
              autofocus: true,
              maxLength: TextCaps.forKind(s.kind),
              maxLines: s.isName ? 1 : 3,
              minLines: 1,
              textCapitalization: s.isName ? TextCapitalization.words : TextCapitalization.sentences,
              textInputAction: withAlias ? TextInputAction.next : TextInputAction.done,
              onChanged: (_) => serverError.value = null,
              onSubmitted: withAlias ? null : (_) => save(),
              decoration: InputDecoration(
                labelText: s.isName ? l10n.fieldName : l10n.fieldIntention,
                errorText: inlineError,
                errorMaxLines: 3,
              ),
            ),
            if (withAlias) ...[
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
                      dimension: pp.size.rowIcon,
                      child: CircularProgressIndicator(strokeWidth: 2, color: pp.colors.onPrimary),
                    )
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

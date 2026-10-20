// After the final Amen (app-brief §3): optional "Add a note" (private,
// editable later), then the closing line. The prayer is already written (or
// queued) by the time this shows; the note follows it through the queue.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/rules/validation.dart';
import '../../l10n/app_localizations.dart';
import '../../state/prayer_session.dart';
import '../../theme/pp_theme.dart';

Future<void> showClosingSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ClosingSheet(),
    );

class ClosingSheet extends HookConsumerWidget {
  const ClosingSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final session = ref.watch(prayerSessionProvider);
    final logged = session.logged;
    final writing = useState(false);
    final note = useTextEditingController();

    void done() => Navigator.of(context).pop();

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        pp.space.xl,
        pp.space.sm,
        pp.space.xl,
        pp.space.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (logged != null && logged.includesList && session.listNumber != null) ...[
              Text(
                l10n.closingCarried(session.listNumber! + 1),
                textAlign: TextAlign.center,
                style: context.text.headlineSmall,
              ),
              SizedBox(height: pp.space.xl),
            ],
            if (writing.value) ...[
              TextField(
                controller: note,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                maxLength: TextCaps.note,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: l10n.noteHint),
              ),
              SizedBox(height: pp.space.md),
              FilledButton(
                onPressed: () async {
                  await ref.read(prayerSessionProvider.notifier).addNote(note.text);
                  done();
                },
                child: Text(l10n.save),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () => writing.value = true,
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(l10n.addNote),
              ),
              SizedBox(height: pp.space.sm),
              TextButton(onPressed: done, child: Text(l10n.done)),
            ],
          ],
        ),
      ),
    );
  }
}

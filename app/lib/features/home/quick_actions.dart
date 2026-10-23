// Long-press on a row (design-direction.md §5): quick actions. Only "Add
// intention" exists so far; edit, resolve and archive arrive with the detail
// page (build step 5).

import 'package:flutter/material.dart';

import '../../domain/models/subject.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/pp_icons.dart';
import '../../theme/pp_theme.dart';
import '../add/add_sheet.dart';

Future<void> showQuickActions(BuildContext context, Subject subject) => showModalBottomSheet<void>(
      context: context,
      builder: (sheet) {
        final pp = sheet.pp;
        final l10n = L10n.of(sheet);
        return SafeArea(
          child: Padding(
            padding: EdgeInsetsDirectional.only(bottom: pp.space.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(pp.space.xl, 0, pp.space.xl, pp.space.sm),
                  child:
                      Text(subject.label, style: sheet.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (subject.isName)
                  ListTile(
                    contentPadding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.xl),
                    leading: Icon(PPIcons.add, color: pp.colors.ink),
                    title: Text(l10n.addIntention, style: sheet.text.bodyLarge),
                    onTap: () {
                      Navigator.pop(sheet);
                      showAddSheet(context, forNameId: subject.id);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );

// Long-press on a row (design-direction.md §5): quick actions — the detail
// page's ⋯ actions (Edit, Answered, Release, Archive; detail-page.md), plus
// "Add intention" on a name.

import 'package:flutter/material.dart';

import '../../domain/models/subject.dart';
import '../detail/subject_actions.dart';

Future<void> showQuickActions(BuildContext context, Subject subject) =>
    showSubjectActions(context, subject, withAddIntention: true);

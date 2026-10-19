import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plusprayer/widgets/framework/controls/action_switch.dart';

import '../../../presentation/themes.dart';

class UnprayedFilterSwitch extends StatelessWidget {
  final bool value;
  final Function(bool) onChanged;

  const UnprayedFilterSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final unprayedColor = Theme.of(context).extension<PPCustomTheme>()!.unprayedColor;

    return ActionSwitch(
        color: unprayedColor,
        label: 'Unprayed',
        onChanged: (value) {
          HapticFeedback.selectionClick();
          onChanged(value);
        },
        value: value);
  }
}

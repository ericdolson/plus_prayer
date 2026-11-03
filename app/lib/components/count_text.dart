import 'package:flutter/material.dart';

import '../theme/pp_theme.dart';

/// A localized count line ("4,345 people") with the number in [numberStyle]
/// and the words in [style] (design-direction.md §6). [number] is the number
/// exactly as [text] formats it. Decorative; the caller carries the label.
TextSpan countSpan(String text, String number, {required TextStyle style, required TextStyle numberStyle}) {
  final at = text.indexOf(number);
  if (at < 0) return TextSpan(text: text, style: style);
  return TextSpan(
    style: style,
    children: [
      if (at > 0) TextSpan(text: text.substring(0, at)),
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: CountText(number, style: numberStyle),
      ),
      if (at + number.length < text.length) TextSpan(text: text.substring(at + number.length)),
    ],
  );
}

/// A formatted number in tabular figures, for a [WidgetSpan] (it doesn't
/// scale itself: the span does), where only the changed digits
/// crossfade when it updates live (no rolling counter: Amen → seal stays the
/// one signature motion). Digits are matched from the right, so "999" →
/// "1,000" fades every place that changed.
class CountText extends StatelessWidget {
  const CountText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final tabular = style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final chars = text.characters.toList();
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          for (var i = 0; i < chars.length; i++)
            AnimatedSwitcher(
              // Place from the right: the same place keeps its widget.
              key: ValueKey(chars.length - i),
              duration: context.pp.motion.settle,
              // Inside a WidgetSpan the text's own scaler already scales this.
              child: Text(chars[i], key: ValueKey(chars[i]), style: tabular, textScaler: TextScaler.noScaling),
            ),
        ],
      ),
    );
  }
}

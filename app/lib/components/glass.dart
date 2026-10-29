import 'package:flutter/material.dart';

import '../theme/pp_theme.dart';
import 'frosted.dart';

/// A control's own glass (design-direction.md §4): [Frosted], fully rounded,
/// with a hairline edge so it holds its shape over any row. The floating
/// bar's pill and search field, the header's badge and filter. [width]
/// defaults to the content's; set it to [height] for a circle. [selected]
/// raises the tint (an active filter).
class Glass extends StatelessWidget {
  const Glass({super.key, required this.height, this.width, this.selected = false, required this.child});

  final double height;
  final double? width;
  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.pp.colors;
    final radius = BorderRadius.circular(height / 2);
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: c.hairline, width: .5)),
      child: Frosted(
        color: selected ? c.surfaceRaised : c.surface,
        borderRadius: radius,
        // Ink from the controls inside shows on the glass, not under it.
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox(height: height, width: width, child: child),
        ),
      ),
    );
  }
}

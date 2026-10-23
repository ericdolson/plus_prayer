import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../theme/pp_theme.dart';

/// Bar material (design-direction.md §4): content scrolling beneath shows
/// through, blurred, on iOS; elsewhere (Android, low-end) a semi-opaque fill.
/// [clipper] shapes it (the footer's notch); otherwise it fills its box.
class Frosted extends StatelessWidget {
  const Frosted({super.key, required this.color, required this.child, this.clipper});

  final Color color;
  final Widget child;
  final CustomClipper<Path>? clipper;

  static bool get blurs => defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Widget build(BuildContext context) {
    final bars = context.pp.bars;
    Widget content = ColoredBox(color: color.withValues(alpha: blurs ? bars.tint : bars.opaque), child: child);
    if (blurs) {
      content = BackdropFilter(filter: ImageFilter.blur(sigmaX: bars.blur, sigmaY: bars.blur), child: content);
    }
    return clipper == null ? ClipRect(child: content) : ClipPath(clipper: clipper, child: content);
  }
}

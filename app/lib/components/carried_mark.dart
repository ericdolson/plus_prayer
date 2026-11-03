import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/pp_theme.dart';

/// The carried mark (design-direction.md §5): the logo glyph (the bloom
/// with the "+" cut out) as a flat neutral silhouette, no wax or sheen.
/// Trails every carried name and intention on Home. For now it is the logo;
/// a bloom without the "+" comes later (open-questions D1).
class CarriedMark extends StatelessWidget {
  const CarriedMark({super.key, required this.size});

  static const asset = 'assets/img/+prayer_icon.svg';

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SvgPicture.asset(
          asset,
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(context.pp.colors.carriedMark, BlendMode.srcIn),
        ),
      );

  /// [text], then the mark [gap] after it as an inline span. A word joiner
  /// ties it to the last word, so it never wraps alone onto its own line.
  /// The span scales with the text.
  static TextSpan after(String text, {required bool carried, required double size, required double gap}) => TextSpan(
        text: text,
        children: [
          if (carried) ...[
            const TextSpan(text: '\u2060'),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: gap),
                child: CarriedMark(size: size),
              ),
            ),
          ],
        ],
      );
}

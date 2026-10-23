import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/pp_theme.dart';

/// The logo (the organic cluster with the "+" cut out, brand/CLAUDE.md) as a
/// small wax seal: the streak badge's mark (design-direction.md §4). In a
/// day's wax with its sheen; [muted] is the quiet, unwaxed version.
class LogoSeal extends StatelessWidget {
  const LogoSeal({super.key, required this.variant, required this.size, this.muted = false});

  static const asset = 'assets/img/+prayer_icon.svg';

  /// The wax (0 = Sunday … 6 = Saturday).
  final int variant;
  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.pp.colors;
    final logo = SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(muted ? c.inkFaint : c.wax(variant), BlendMode.srcIn),
    );
    if (muted) return ExcludeSemantics(child: logo);
    // Poured wax: a sheen from the top left, shading toward the far edge.
    return ExcludeSemantics(
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => RadialGradient(
          center: const Alignment(-.4, -.5),
          radius: 1.1,
          colors: [c.waxSheen(variant), c.wax(variant), Color.lerp(c.wax(variant), c.shadow, .35)!],
          stops: const [0, .55, 1],
        ).createShader(bounds),
        child: logo,
      ),
    );
  }
}

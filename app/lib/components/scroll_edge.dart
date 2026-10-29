import 'dart:math' as math;
import 'dart:ui' show FragmentProgram, FragmentShader, ImageFilter;

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../theme/tokens.dart' show PPEdgeLook;

final Future<FragmentProgram> _program = FragmentProgram.fromAsset('shaders/scroll_edge.frag');

/// A scroll edge (design-direction.md §4, iOS 26): no slab and no line. What
/// scrolls beneath blurs and dims toward the screen's edge, sharp again by
/// this box's inner end; controls on it carry their own [Glass]. The header's
/// ground at the top of the screen; with [bottom], the overlay under Home's
/// floating bar. Fills its box, which must touch that screen edge.
///
/// Flutter has no variable blur, so it's layered: each blur in [look] runs
/// through a shader (shaders/scroll_edge.frag) that lays it over what's
/// beneath with a smooth falloff, heavier ones nearer the edge; the last
/// layer also dims. Where shader filters aren't supported, the dim alone.
class ScrollEdge extends HookWidget {
  const ScrollEdge({super.key, required this.ground, required this.look, this.bottom = false, this.child});

  final Color ground;
  final PPEdgeLook look;
  final bool bottom;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final levels = look.blurs;
    final program = useFuture(_program).data;
    final shaders = useMemoized(
      () => [
        if (program != null)
          for (final _ in levels) program.fragmentShader(),
      ],
      [program, levels.length],
    );
    useEffect(
      () => () {
        for (final s in shaders) {
          s.dispose();
        }
      },
      [shaders],
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);

    final effect = IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) => shaders.isNotEmpty && ImageFilter.isShaderFilterSupported
            ? ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Each layer blurs what the ones before left.
                    for (final (i, level) in levels.indexed)
                      BackdropFilter(
                        filter: _filter(
                          shaders[i],
                          height: box.maxHeight * dpr,
                          sigma: level.sigma,
                          from: level.from,
                          to: level.to,
                          dim: i == levels.length - 1 ? look.dim : 0,
                        ),
                        child: const SizedBox.expand(),
                      ),
                  ],
                ),
              )
            : _DimOnly(ground: ground, look: look, bottom: bottom),
      ),
    );
    final content = child;
    if (content == null) return effect;
    return Stack(children: [Positioned.fill(child: effect), content]);
  }

  ImageFilter _filter(
    FragmentShader shader, {
    required double height,
    required double sigma,
    required double from,
    required double to,
    required double dim,
  }) {
    shader
      ..setFloat(2, height)
      ..setFloat(3, ground.r)
      ..setFloat(4, ground.g)
      ..setFloat(5, ground.b)
      ..setFloat(6, dim)
      ..setFloat(7, look.curve)
      ..setFloat(8, from)
      ..setFloat(9, to)
      ..setFloat(10, bottom ? 1 : 0);
    return ImageFilter.compose(
      outer: ImageFilter.shader(shader),
      inner: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    );
  }
}

/// The fallback: the shader's dim curve as a many-stop gradient.
class _DimOnly extends StatelessWidget {
  const _DimOnly({required this.ground, required this.look, required this.bottom});

  final Color ground;
  final PPEdgeLook look;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    const stops = 24;
    double smooth(double t) => t * t * (3 - 2 * t);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: bottom ? Alignment.bottomCenter : Alignment.topCenter,
          end: bottom ? Alignment.topCenter : Alignment.bottomCenter,
          colors: [
            for (var i = 0; i <= stops; i++)
              ground.withValues(alpha: look.dim * (1 - math.pow(smooth(i / stops), look.curve))),
          ],
        ),
      ),
    );
  }
}

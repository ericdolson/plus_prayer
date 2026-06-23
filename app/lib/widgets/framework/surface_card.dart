import 'package:flutter/material.dart';

double surfaceCardHorizontalPadding = 24;
double surfaceCardVerticalPadding = 16;

class SurfaceCard extends StatelessWidget {
  final ImageProvider<Object>? backgroundImageProvider;
  final bool bright;
  final Widget child;
  final EdgeInsets? padding;
  final bool outlined;
  final bool elevated;
  final bool filled;
  final bool tinted;

  const SurfaceCard({super.key,
    this.backgroundImageProvider,
    this.bright = false,
    required this.child,
    this.outlined = false,
    this.elevated = false,
    this.filled = false,
    this.padding,
    this.tinted = false})
      : assert(!(tinted && bright), 'You cannot have both tinted and bright set to true');

  const SurfaceCard.tinted({super.key,
    this.backgroundImageProvider,
    required this.child,
    this.padding,
    this.outlined = false,
    this.elevated = false,
    this.filled = false})
      : tinted = true,
        bright = false;

  const SurfaceCard.bright({super.key,
    this.backgroundImageProvider,
    required this.child,
    this.padding,
    this.outlined = false,
    this.elevated = false,
    this.filled = false})
      : tinted = false,
        bright = true;

  @override
  Widget build(BuildContext context) {
    final color = bright
        ? Theme
        .of(context)
        .colorScheme
        .surfaceBright
        : tinted
        ? Theme
        .of(context)
        .colorScheme
        .surfaceTint
        : Theme
        .of(context)
        .colorScheme
        .surface;

    final outlineColor =
    filled ? Theme
        .of(context)
        .colorScheme
        .surfaceTint : color;

    return Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        padding: padding ??
            EdgeInsets.symmetric(
                horizontal: surfaceCardHorizontalPadding, vertical: surfaceCardVerticalPadding),
        decoration: BoxDecoration(
          color: outlined
              ? filled
              ? color
              : Colors.transparent
              : color,
          border: outlined
              ? Border.all(
            color: outlineColor,
            width: 1,
          )
              : null,
          borderRadius: BorderRadius.circular(24),
          image: backgroundImageProvider != null
              ? DecorationImage(
            image: backgroundImageProvider!,
            fit: BoxFit.cover,
          )
              : null,
          boxShadow: elevated ? [
            BoxShadow(color: Colors.black.withValues(alpha:.1), blurRadius: 3, offset: Offset(0, 2))
          ] : null,
        ),
        child: child);
  }
}

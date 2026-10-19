import 'package:flutter/material.dart';

const String fancyTextFontFamily = 'Roca';
const FontWeight fancyTextFontWeight = FontWeight.w900;
const TextStyle fancyTextStyle =
    TextStyle(fontFamily: fancyTextFontFamily, fontWeight: fancyTextFontWeight);

class FancyText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final Color? color;

  const FancyText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fontWeight = style?.fontWeight ?? fancyTextFontWeight;

    return Text(
      text,
      style: style?.copyWith(
              fontFamily: fancyTextFontFamily,
              fontWeight: fontWeight,
              color: color) ??
          fancyTextStyle,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

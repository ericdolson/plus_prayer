// The intention thread (design-direction.md §5): a thin neutral line drops
// from the bottom-center of a name's avatar and curves to each of its
// intentions, like a prayer strand. Painted behind the rows; it never changes
// color or weight (the held dot sits where it ends).

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// What part of the thread a row draws.
enum ThreadPart {
  /// A name row with intentions below: from under the avatar to the bottom.
  trunk,

  /// An intention with more below: the trunk continues past its branch.
  branch,

  /// The last intention: the trunk ends in its branch.
  lastBranch,
}

class ThreadPainter extends CustomPainter {
  ThreadPainter({
    required this.part,
    required this.color,
    required this.strokeWidth,
    required this.trunkX,
    required this.endX,
    required this.textDirection,
    this.avatarDiameter = 0,
    this.avatarClearance = 0,
    this.radius = 10,
  });

  final ThreadPart part;
  final Color color;
  final double strokeWidth;

  /// From the start edge: the avatar's center, and where a branch ends.
  final double trunkX;
  final double endX;
  final TextDirection textDirection;

  /// Trunk rows: the avatar (vertically centered) and the space kept clear
  /// below it (the held ring's room).
  final double avatarDiameter;
  final double avatarClearance;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rtl = textDirection == TextDirection.rtl;
    double x(double fromStart) => rtl ? size.width - fromStart : fromStart;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final tx = x(trunkX);

    if (part == ThreadPart.trunk) {
      final top = size.height / 2 + avatarDiameter / 2 + avatarClearance;
      if (top < size.height) canvas.drawLine(Offset(tx, top), Offset(tx, size.height), paint);
      return;
    }

    final cy = size.height / 2;
    final r = math.min(radius, cy);
    final ex = x(endX);
    final dir = rtl ? -1.0 : 1.0;
    final path = Path()
      ..moveTo(tx, 0)
      ..lineTo(tx, cy - r)
      ..quadraticBezierTo(tx, cy, tx + dir * r, cy)
      ..lineTo(ex, cy);
    canvas.drawPath(path, paint);
    if (part == ThreadPart.branch) canvas.drawLine(Offset(tx, cy - r), Offset(tx, size.height), paint);
  }

  @override
  bool shouldRepaint(ThreadPainter old) =>
      old.part != part ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.trunkX != trunkX ||
      old.endX != endX ||
      old.textDirection != textDirection ||
      old.avatarDiameter != avatarDiameter ||
      old.avatarClearance != avatarClearance ||
      old.radius != radius;
}

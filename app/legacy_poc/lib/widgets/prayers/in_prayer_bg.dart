import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:plusprayer/hooks/use_in_prayer.dart';

class InPrayerBackground extends StatelessWidget {
  final bool isInPrayer;

  const InPrayerBackground({super.key, required this.isInPrayer});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Stack(children: [
      Container(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      SizedBox(
      width: screenSize.width,
      height: screenSize.height,
      child: CustomPaint(
        painter: CrosshatchPainter(),
      ),
    )]);


    final opacity = isInPrayer ? 0.2 : 0.0;
    return Stack(children: [
      Container(
        color: Theme
            .of(context)
            .scaffoldBackgroundColor,
      ),
      // AnimatedContainer(
      //   duration: 500.ms,
      //   // width: 200,
      //   // height: 800,
      //   decoration: BoxDecoration(
      //     gradient: LinearGradient(
      //       colors: [
      //         Colors.green.withValues(alpha:isInPrayer ? 0.2 : 0),
      //         Colors.orange.withValues(alpha:isInPrayer ? 0.2 : 0),
      //         Colors.red.withValues(alpha:isInPrayer ? 0.2 : 0),
      //         Colors.blue.withValues(alpha:isInPrayer ? 0.2 : 0),
      //       ],
      //       begin: Alignment.topLeft,
      //       end: Alignment.bottomRight,
      //     ),
      //   ),
      // ),
      AnimatedContainer(
        duration: 2000.ms,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 2,
            colors: [Colors.blue.withValues(alpha:opacity), Colors.transparent],
            stops: [0.0, 1.0],
          ),
        ),
      ),
      AnimatedContainer(
        duration: 500.ms,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 2,
            colors: [Colors.red.withValues(alpha:opacity), Colors.transparent],
            stops: [0.0, 1.0],
          ),
        ),
      ),
      AnimatedContainer(
        duration: 500.ms,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomLeft,
            radius: 2,
            colors: [Colors.orange.withValues(alpha:opacity), Colors.transparent],
            stops: [0.0, 1.0],
          ),
        ),
      ),
      AnimatedContainer(
        duration: 500.ms,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomRight,
            radius: 2,
            colors: [Colors.green.withValues(alpha:opacity), Colors.transparent],
            stops: [0.0, 1.0],
          ),
        ),
      )
    ]);
  }
}

// Stack(
// children: [
// Container(
//   decoration: BoxDecoration(
//     gradient: RadialGradient(
//       center: Alignment.topLeft,
//       radius: 2,
//       colors: [Colors.blue.withValues(alpha:0.1), Colors.transparent],
//       stops: [0.0, 1.0],
//     ),
//   ),
// ),
// Container(
//   decoration: BoxDecoration(
//     gradient: RadialGradient(
//       center: Alignment.topRight,
//       radius: 2,
//       colors: [Colors.green.withValues(alpha:0.1), Colors.transparent],
//       stops: [0.0, 1.0],
//     ),
//   ),
// ),
// Container(
//   decoration: BoxDecoration(
//     gradient: RadialGradient(
//       center: Alignment.bottomLeft,
//       radius: 2,
//       colors: [Colors.orange.withValues(alpha:0.1), Colors.transparent],
//       stops: [0.0, 1.0],
//     ),
//   ),
// ),
// Container(
//   decoration: BoxDecoration(
//     gradient: RadialGradient(
//       center: Alignment.bottomRight,
//       radius: 2,
//       colors: [Colors.red.withValues(alpha:0.1), Colors.transparent],
//       stops: [0.0, 1.0],
//     ),
//   ),
// )
// ])

class CrosshatchPainter extends CustomPainter {
  final double spacing;
  final Color lineColor;
  final double lineWidth;

  CrosshatchPainter({
    this.spacing = 20,
    this.lineColor = Colors.black12,
    this.lineWidth = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha:.03)
      ..strokeWidth = lineWidth;

    // Top-left to bottom-right (/)
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // Bottom-left to top-right (\)
    for (double i = 0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i - size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CrosshatchPainter oldDelegate) => false;
}
// The footer's outline from the POC: a bar with rounded top corners and a
// soft-edged circular notch around the docked pray button.
//
// The notch curve is adapted from animated_bottom_navigation_bar
// (CircularNotchedAndCorneredRectangle, NotchSmoothness.softEdge), which the
// POC used. That code is:
//   Copyright (c) 2020, LanarsInc. All rights reserved.
//   BSD 2-Clause License. Redistribution and use in source and binary forms,
//   with or without modification, are permitted provided that the following
//   conditions are met: (1) redistributions of source code must retain the
//   above copyright notice, this list of conditions and the following
//   disclaimer; (2) redistributions in binary form must reproduce the above
//   copyright notice, this list of conditions and the following disclaimer in
//   the documentation and/or other materials provided with the distribution.
//   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//   POSSIBILITY OF SUCH DAMAGE.

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pass to `BottomAppBar.shape` with the button docked at
/// `FloatingActionButtonLocation.centerDocked`.
class NotchedFooterShape extends NotchedShape {
  const NotchedFooterShape({required this.cornerRadius});

  final double cornerRadius;

  // Soft edge: how far the curve reaches along the top edge (s1) and how far
  // it sits outside the notch circle (s2).
  static const _s1 = 20.0;
  static const _s2 = 5.0;

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    final r = cornerRadius;
    final path = Path()
      ..moveTo(host.left, host.bottom)
      ..lineTo(host.left, host.top + r)
      ..arcToPoint(Offset(host.left + r, host.top), radius: Radius.circular(r));

    if (guest != null && host.overlaps(guest)) {
      // The notch: a quadratic curve down from the top edge, an arc around the
      // guest circle, and the mirror curve back up.
      final notchRadius = guest.width / 2;
      final a = -notchRadius - _s2;
      final b = host.top - guest.center.dy;
      final n2 = math.sqrt(b * b * notchRadius * notchRadius * (a * a + b * b - notchRadius * notchRadius));
      final p2xA = (a * notchRadius * notchRadius - n2) / (a * a + b * b);
      final p2xB = (a * notchRadius * notchRadius + n2) / (a * a + b * b);
      final p2yA = math.sqrt(notchRadius * notchRadius - p2xA * p2xA);
      final p2yB = math.sqrt(notchRadius * notchRadius - p2xB * p2xB);
      final cmp = b < 0 ? -1.0 : 1.0;
      final p2 = cmp * p2yA > cmp * p2yB ? Offset(p2xA, p2yA) : Offset(p2xB, p2yB);

      final c = guest.center;
      final p0 = Offset(a - _s1, b) + c;
      final p1 = Offset(a, b) + c;
      final p3 = Offset(-p2.dx, p2.dy) + c;
      final p4 = Offset(-a, b) + c;
      final p5 = Offset(-a + _s1, b) + c;

      path
        ..lineTo(p0.dx, p0.dy)
        ..quadraticBezierTo(p1.dx, p1.dy, p2.dx + c.dx, p2.dy + c.dy)
        ..arcToPoint(p3, radius: Radius.circular(notchRadius), clockwise: false)
        ..quadraticBezierTo(p4.dx, p4.dy, p5.dx, p5.dy);
    }

    return path
      ..lineTo(host.right - r, host.top)
      ..arcToPoint(Offset(host.right, host.top + r), radius: Radius.circular(r))
      ..lineTo(host.right, host.bottom)
      ..close();
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

class CoastPainter extends CustomPainter {
  final bool lit;
  final int chapter;
  CoastPainter({this.lit = false, this.chapter = 0});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 400, size.height / 300);
    final rect = const Rect.fromLTWH(0, 0, 400, 300);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff142936), Color(0xff365250)],
        ).createShader(rect),
    );
    final random = math.Random(11);
    for (int i = 0; i < 22; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * 400, 15 + random.nextDouble() * 155),
        i % 4 == 0 ? 1.1 : .6,
        Paint()..color = const Color(0xffbdcdb8),
      );
    }
    canvas.drawCircle(
      const Offset(317, 68),
      23,
      Paint()..color = const Color(0xffeee1be),
    );
    canvas.drawCircle(
      const Offset(327, 59),
      22,
      Paint()..color = const Color(0xff1b333e),
    );
    final sea = Path()
      ..moveTo(0, 204)
      ..quadraticBezierTo(85, 185, 170, 208)
      ..quadraticBezierTo(280, 225, 400, 194)
      ..lineTo(400, 300)
      ..lineTo(0, 300)
      ..close();
    canvas.drawPath(sea, Paint()..color = const Color(0xff1b3540));
    final ripple = Paint()
      ..color = const Color(0xff789486).withValues(alpha: .25)
      ..strokeWidth = .7;
    for (int i = 0; i < 17; i++) {
      final x = random.nextDouble() * 360;
      final y = 210 + random.nextDouble() * 86;
      canvas.drawLine(Offset(x, y), Offset(x + 25, y), ripple);
    }
    canvas.drawPath(
      Path()
        ..moveTo(99, 255)
        ..lineTo(141, 205)
        ..lineTo(176, 188)
        ..lineTo(228, 202)
        ..lineTo(269, 255)
        ..lineTo(203, 278)
        ..close(),
      Paint()..color = const Color(0xff526c61),
    );
    canvas.drawPath(
      Path()
        ..moveTo(99, 255)
        ..lineTo(172, 226)
        ..lineTo(269, 255)
        ..lineTo(203, 278)
        ..close(),
      Paint()..color = const Color(0xff273e41),
    );
    canvas.drawPath(
      Path()
        ..moveTo(161, 201)
        ..lineTo(168, 99)
        ..lineTo(196, 99)
        ..lineTo(206, 207)
        ..close(),
      Paint()..color = const Color(0xffe4d6b4),
    );
    canvas.drawPath(
      Path()
        ..moveTo(166, 122)
        ..lineTo(199, 130)
        ..lineTo(201, 147)
        ..lineTo(164, 138)
        ..close(),
      Paint()..color = const Color(0xffba7c6b),
    );
    canvas.drawPath(
      Path()
        ..moveTo(163, 167)
        ..lineTo(202, 176)
        ..lineTo(204, 193)
        ..lineTo(162, 184)
        ..close(),
      Paint()..color = const Color(0xffba7c6b),
    );
    canvas.drawRect(
      const Rect.fromLTWH(165, 78, 34, 21),
      Paint()..color = const Color(0xff172e38),
    );
    canvas.drawPath(
      Path()
        ..moveTo(158, 78)
        ..lineTo(182, 59)
        ..lineTo(205, 78)
        ..close(),
      Paint()..color = const Color(0xffc18c74),
    );
    canvas.drawRect(
      const Rect.fromLTWH(172, 84, 21, 11),
      Paint()..color = lit ? const Color(0xffffe2a0) : const Color(0xff859686),
    );
    canvas.drawRect(
      const Rect.fromLTWH(177, 188, 10, 18),
      Paint()..color = const Color(0xff29403f),
    );
    if (lit) {
      final beam = Path()
        ..moveTo(191, 85)
        ..lineTo(400, 25)
        ..lineTo(400, 161)
        ..lineTo(191, 94)
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0x88ffe4a1), Color(0x00ffe4a1)],
          ).createShader(const Rect.fromLTWH(185, 20, 215, 145)),
      );
    }
    if (chapter > 1) {
      canvas.drawPath(
        Path()
          ..moveTo(279, 239)
          ..lineTo(316, 239)
          ..lineTo(307, 248)
          ..lineTo(289, 248)
          ..close(),
        Paint()..color = const Color(0xffb99072),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CoastPainter oldDelegate) =>
      lit != oldDelegate.lit || chapter != oldDelegate.chapter;
}

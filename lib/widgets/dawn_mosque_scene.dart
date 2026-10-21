import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rafiqflutter/theme/rafiq_theme.dart';

class DawnMosqueScene extends StatelessWidget {
  const DawnMosqueScene({super.key});

  @override
  Widget build(BuildContext context) {
    final background = RafiqThemeScope.of(context).background;
    return CustomPaint(
      painter: _DawnMosqueScenePainter(background: background),
      child: const SizedBox.expand(),
    );
  }
}

class _DawnMosqueScenePainter extends CustomPainter {
  _DawnMosqueScenePainter({required this.background});

  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    _drawDawnSky(canvas, size);
    _drawClouds(canvas, size);
    _drawMountains(canvas, size);
    _drawCity(canvas, size);
    _drawMosque(canvas, size);
    _drawWaterAndForeground(canvas, size);
    _drawOverlay(canvas, size);
  }

  void _drawDawnSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF031B17),
            Color(0xFF0A322A),
            Color(0xFF345E50),
            Color(0xFF917151),
            Color(0xFFD0A166),
          ],
          stops: [0, 0.25, 0.48, 0.62, 0.72],
        ).createShader(rect),
    );

    final glowCenter = Offset(size.width * 0.53, size.height * 0.48);
    final glowRadius = size.width * 0.58;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFD98F).withValues(alpha: 0.45),
            const Color(0xFFE1A45C).withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius)),
    );

    canvas.drawCircle(
      Offset(size.width * 0.54, size.height * 0.53),
      size.width * 0.045,
      Paint()..color = const Color(0xFFFFE0A6).withValues(alpha: 0.22),
    );

    for (var i = 0; i <= 17; i++) {
      final x = size.width * ((i * 0.137 + 0.061) % 1);
      final y = size.height * (0.05 + ((i * 0.071) % 0.3));
      canvas.drawCircle(
        Offset(x, y),
        0.5 + (i % 2),
        Paint()
          ..color = Color(0xFFE8E1C8).withValues(alpha: 0.16 + (i % 3) * 0.06),
      );
    }
  }

  void _drawClouds(Canvas canvas, Size size) {
    const bands = <(double, double)>[
      (0.34, 0.028),
      (0.39, 0.018),
      (0.46, 0.022),
      (0.57, 0.026),
      (0.63, 0.035),
    ];

    for (var index = 0; index < bands.length; index++) {
      final fraction = bands[index].$1;
      final thickness = bands[index].$2;
      final topLeft = Offset(
        size.width * (0.05 + index * 0.1),
        size.height * fraction,
      );
      final bandSize = Size(
        size.width * (0.55 + index * 0.08),
        size.height * thickness,
      );
      final rect = Rect.fromLTWH(
        topLeft.dx,
        topLeft.dy,
        bandSize.width,
        bandSize.height,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Color(0xFFA08161).withValues(alpha: 0.12 + index * 0.02),
              Color(0xFFC89A68).withValues(alpha: 0.16 + index * 0.02),
              Colors.transparent,
            ],
          ).createShader(rect),
      );
    }
  }

  void _drawMountains(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final back = Path()
      ..moveTo(0, size.height * 0.66)
      ..lineTo(size.width * 0.08, size.height * 0.54)
      ..lineTo(size.width * 0.15, size.height * 0.59)
      ..lineTo(size.width * 0.26, size.height * 0.48)
      ..lineTo(size.width * 0.38, size.height * 0.59)
      ..lineTo(size.width * 0.52, size.height * 0.51)
      ..lineTo(size.width * 0.66, size.height * 0.60)
      ..lineTo(size.width * 0.81, size.height * 0.44)
      ..lineTo(size.width * 0.93, size.height * 0.55)
      ..lineTo(size.width, size.height * 0.49)
      ..lineTo(size.width, size.height * 0.7)
      ..lineTo(0, size.height * 0.7)
      ..close();
    canvas.drawPath(
      back,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF244F42), Color(0xFF123329)],
        ).createShader(rect),
    );

    final foreground = Path()
      ..moveTo(0, size.height * 0.69)
      ..lineTo(size.width * 0.13, size.height * 0.63)
      ..lineTo(size.width * 0.22, size.height * 0.67)
      ..lineTo(size.width * 0.36, size.height * 0.60)
      ..lineTo(size.width * 0.5, size.height * 0.67)
      ..lineTo(size.width * 0.74, size.height * 0.62)
      ..lineTo(size.width * 0.9, size.height * 0.68)
      ..lineTo(size.width, size.height * 0.63)
      ..lineTo(size.width, size.height * 0.76)
      ..lineTo(0, size.height * 0.76)
      ..close();
    canvas.drawPath(
      foreground,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF163B30), Color(0xFF092219)],
        ).createShader(rect),
    );
  }

  void _drawCity(Canvas canvas, Size size) {
    final baseY = size.height * 0.75;

    const blockWidths = <double>[
      0.04,
      0.03,
      0.06,
      0.035,
      0.05,
      0.04,
      0.06,
      0.03,
      0.05,
      0.04,
      0.06,
    ];
    const heights = <double>[
      0.035,
      0.055,
      0.04,
      0.065,
      0.045,
      0.05,
      0.04,
      0.07,
      0.05,
      0.045,
      0.055,
    ];

    final cityPath = Path()
      ..moveTo(0, baseY)
      ..lineTo(0, size.height * 0.7);
    var x = 0.0;
    for (var index = 0; index < blockWidths.length; index++) {
      final width = blockWidths[index];
      final top = size.height * (0.69 - heights[index]);
      x += size.width * width * 0.7;
      cityPath
        ..lineTo(x, top)
        ..lineTo(x + size.width * width * 0.55, top)
        ..lineTo(x + size.width * width * 0.55, baseY);
      x += size.width * width * 0.55;
    }
    cityPath
      ..lineTo(size.width, baseY)
      ..close();
    canvas.drawPath(cityPath, Paint()..color = const Color(0xFF0C2D24));

    canvas.drawCircle(
      Offset(size.width * 0.77, size.height * 0.645),
      size.width * 0.025,
      Paint()..color = const Color(0xFF0C2D24),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.752,
        size.height * 0.64,
        size.width * 0.036,
        size.height * 0.11,
      ),
      Paint()..color = const Color(0xFF0C2D24),
    );

    const lights = <double>[0.06, 0.12, 0.19, 0.29, 0.63, 0.7, 0.76, 0.83, 0.9];
    for (var index = 0; index < lights.length; index++) {
      final y = size.height * (0.715 + (index % 3) * 0.007);
      canvas.drawRect(
        Rect.fromLTWH(size.width * lights[index], y, 1.7, 1.2),
        Paint()..color = const Color(0xFFFFCA77).withValues(alpha: 0.6),
      );
    }
  }

  void _drawMosque(Canvas canvas, Size size) {
    final ground = size.height * 0.765;
    final center = size.width * 0.37;
    const dark = Color(0xFF092219);
    const darker = Color(0xFF061A13);
    final rim = const Color(0xFFD9B476).withValues(alpha: 0.8);
    const window = Color(0xFFFFCA79);

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.17,
        ground - size.height * 0.09,
        size.width * 0.39,
        size.height * 0.1,
      ),
      Paint()..color = dark,
    );

    final mainDomeRadius = size.width * 0.105;
    final domeBase = ground - size.height * 0.085;
    final dome = Path()
      ..moveTo(center - mainDomeRadius, domeBase)
      ..cubicTo(
        center - mainDomeRadius,
        domeBase - mainDomeRadius * 0.82,
        center - mainDomeRadius * 0.74,
        domeBase - mainDomeRadius * 1.22,
        center,
        domeBase - mainDomeRadius * 1.28,
      )
      ..cubicTo(
        center + mainDomeRadius * 0.74,
        domeBase - mainDomeRadius * 1.22,
        center + mainDomeRadius,
        domeBase - mainDomeRadius * 0.82,
        center + mainDomeRadius,
        domeBase,
      )
      ..close();
    canvas.drawPath(dome, Paint()..color = darker);
    canvas.drawPath(
      dome,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = rim,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        center - mainDomeRadius * 0.93,
        domeBase,
        mainDomeRadius * 1.86,
        size.height * 0.035,
      ),
      Paint()..color = dark,
    );
    canvas.drawLine(
      Offset(center, domeBase - mainDomeRadius * 1.28),
      Offset(center, domeBase - mainDomeRadius * 1.48),
      Paint()
        ..strokeWidth = 1.1
        ..color = const Color(0xFFC89B5B).withValues(alpha: 0.55),
    );
    canvas.drawArc(
      Rect.fromLTWH(center - 4.2, domeBase - mainDomeRadius * 1.58, 8.4, 8.4),
      200 * math.pi / 180,
      140 * math.pi / 180,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = const Color(0xFFE4C487).withValues(alpha: 0.9),
    );

    final smallDomeR = size.width * 0.041;
    for (final domeCenterX in <double>[
      center - size.width * 0.125,
      center + size.width * 0.125,
    ]) {
      final smallBase = domeBase + size.height * 0.002;
      final smallDome = Path()
        ..moveTo(domeCenterX - smallDomeR, smallBase)
        ..cubicTo(
          domeCenterX - smallDomeR,
          smallBase - smallDomeR * 1.2,
          domeCenterX - smallDomeR * 0.55,
          smallBase - smallDomeR * 1.5,
          domeCenterX,
          smallBase - smallDomeR * 1.5,
        )
        ..cubicTo(
          domeCenterX + smallDomeR * 0.55,
          smallBase - smallDomeR * 1.5,
          domeCenterX + smallDomeR,
          smallBase - smallDomeR * 1.2,
          domeCenterX + smallDomeR,
          smallBase,
        )
        ..close();
      canvas.drawPath(smallDome, Paint()..color = darker);
      canvas.drawLine(
        Offset(domeCenterX, smallBase - smallDomeR * 1.5),
        Offset(domeCenterX, smallBase - smallDomeR * 1.85),
        Paint()
          ..strokeWidth = 0.8
          ..color = rim,
      );
    }

    _drawMinaret(
      canvas,
      size,
      x: size.width * 0.22,
      ground: ground,
      height: size.height * 0.31,
      body: dark,
      rim: rim,
      window: window,
    );
    _drawMinaret(
      canvas,
      size,
      x: size.width * 0.51,
      ground: ground,
      height: size.height * 0.25,
      body: dark,
      rim: rim,
      window: window,
    );

    final arcadeLeft = size.width * 0.29;
    final arcadeWidth = size.width * 0.16;
    for (var i = 0; i < 4; i++) {
      final archWidth = arcadeWidth / 4.4;
      final left = arcadeLeft + i * archWidth;
      final top = ground - size.height * 0.055;
      final arch = Path()
        ..moveTo(left, ground)
        ..lineTo(left, top + archWidth * 0.5)
        ..cubicTo(
          left,
          top,
          left + archWidth * 0.9,
          top,
          left + archWidth * 0.9,
          top + archWidth * 0.5,
        )
        ..lineTo(left + archWidth * 0.9, ground);
      canvas.drawPath(
        arch,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = window.withValues(alpha: 0.36),
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(center - 1.3, domeBase + size.height * 0.015, 2.6, 2.6),
      Paint()..color = window.withValues(alpha: 0.7),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, ground, size.width, size.height * 0.02),
      Paint()..color = darker,
    );
    for (var i = 0; i <= 13; i++) {
      canvas.drawCircle(
        Offset(size.width * (0.18 + i * 0.03), ground - 1.5),
        1.2,
        Paint()..color = window.withValues(alpha: 0.85),
      );
    }
  }

  void _drawMinaret(
    Canvas canvas,
    Size size, {
    required double x,
    required double ground,
    required double height,
    required Color body,
    required Color rim,
    required Color window,
  }) {
    final width = size.width * 0.022;
    canvas.drawRect(
      Rect.fromLTWH(x - width / 2, ground - height, width, height),
      Paint()..color = body,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        x - width * 1.25,
        ground - height * 0.64,
        width * 2.5,
        height * 0.035,
      ),
      Paint()..color = body,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        x - width * 0.95,
        ground - height * 0.9,
        width * 1.9,
        height * 0.025,
      ),
      Paint()..color = body,
    );
    final cap = Path()
      ..moveTo(x - width * 1.1, ground - height)
      ..lineTo(x, ground - height - width * 2.4)
      ..lineTo(x + width * 1.1, ground - height)
      ..close();
    canvas.drawPath(cap, Paint()..color = body);
    canvas.drawLine(
      Offset(x, ground - height - width * 2.4),
      Offset(x, ground - height - width * 4.1),
      Paint()
        ..strokeWidth = 0.8
        ..color = rim.withValues(alpha: 0.65),
    );
    canvas.drawArc(
      Rect.fromLTWH(x - 2.8, ground - height - width * 5.5, 5.6, 5.6),
      205 * math.pi / 180,
      130 * math.pi / 180,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = rim,
    );
    canvas.drawCircle(
      Offset(x, ground - height * 0.8),
      1.1,
      Paint()..color = window.withValues(alpha: 0.75),
    );
    canvas.drawCircle(
      Offset(x, ground - height * 0.55),
      1.1,
      Paint()..color = window.withValues(alpha: 0.65),
    );
    canvas.drawLine(
      Offset(x + width * 0.5, ground - height * 0.95),
      Offset(x + width * 0.5, ground),
      Paint()
        ..strokeWidth = 0.7
        ..color = rim.withValues(alpha: 0.26),
    );
  }

  void _drawWaterAndForeground(Canvas canvas, Size size) {
    final waterTop = size.height * 0.765;
    final waterRect = Rect.fromLTWH(
      0,
      waterTop,
      size.width,
      size.height - waterTop,
    );
    canvas.drawRect(
      waterRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2E5A49),
            const Color(0xFF113C2F),
            const Color(0xFF041B14),
            background,
          ],
          stops: [0, 0.2, 0.75, 1],
        ).createShader(waterRect),
    );

    const lights = <double>[0.22, 0.28, 0.37, 0.44, 0.51];
    for (var index = 0; index < lights.length; index++) {
      final x = lights[index];
      final startY = waterTop + (index % 3) * 4;
      final endY = startY + size.height * (0.04 + index * 0.006);
      canvas.drawLine(
        Offset(size.width * x, startY),
        Offset(size.width * x, endY),
        Paint()
          ..strokeWidth = 1.2
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFC97A).withValues(alpha: 0.45),
              const Color(0xFFFFC97A).withValues(alpha: 0.02),
            ],
          ).createShader(Rect.fromLTRB(0, startY, size.width, endY)),
      );
      canvas.drawOval(
        Rect.fromLTWH(size.width * x - 8, startY, 16, size.height * 0.025),
        Paint()..color = const Color(0xFFFFD68E).withValues(alpha: 0.12),
      );
    }

    for (var i = 0; i <= 6; i++) {
      final y = waterTop + size.height * 0.02 + i * size.height * 0.025;
      final shimmer = (math.sin(i * 1.7) * 0.5 + 0.5) * 0.08;
      canvas.drawLine(
        Offset(size.width * (0.1 + i * 0.055), y),
        Offset(size.width * (0.55 + i * 0.035), y),
        Paint()
          ..strokeWidth = 0.8
          ..color = Color(0xFFD8C99E).withValues(alpha: shimmer),
      );
    }

    const treeDark = Color(0xFF04130E);
    canvas.drawOval(
      Rect.fromLTWH(
        -size.width * 0.1,
        waterTop - size.height * 0.1,
        size.width * 0.28,
        size.height * 0.17,
      ),
      Paint()..color = treeDark,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.86,
        waterTop - size.height * 0.08,
        size.width * 0.25,
        size.height * 0.15,
      ),
      Paint()..color = treeDark,
    );
    canvas.drawCircle(
      Offset(size.width * 0.08, waterTop - size.height * 0.09),
      size.width * 0.06,
      Paint()..color = treeDark,
    );
    canvas.drawCircle(
      Offset(size.width * 0.14, waterTop - size.height * 0.12),
      size.width * 0.05,
      Paint()..color = treeDark,
    );
  }

  void _drawOverlay(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF02100B).withValues(alpha: 0.22),
            Colors.transparent,
            Colors.transparent,
            background,
          ],
          stops: [0, 0.18, 0.72, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _DawnMosqueScenePainter oldDelegate) {
    return oldDelegate.background != background;
  }
}

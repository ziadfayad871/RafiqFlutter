import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/rafiq_theme.dart';

class RafiqBackground extends StatelessWidget {
  const RafiqBackground({super.key, this.pattern = true, this.arch = false});

  final bool pattern;
  final bool arch;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Positioned.fill(
      child: CustomPaint(
        painter: _RafiqBackgroundPainter(
          background: palette.background,
          backgroundSecondary: palette.backgroundSecondary,
          backgroundDeep: palette.backgroundDeep,
          mint: palette.mint,
          gold: palette.gold,
          pattern: pattern,
          arch: arch,
        ),
      ),
    );
  }
}

class _RafiqBackgroundPainter extends CustomPainter {
  _RafiqBackgroundPainter({
    required this.background,
    required this.backgroundSecondary,
    required this.backgroundDeep,
    required this.mint,
    required this.gold,
    required this.pattern,
    required this.arch,
  });

  final Color background;
  final Color backgroundSecondary;
  final Color backgroundDeep;
  final Color mint;
  final Color gold;
  final bool pattern;
  final bool arch;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [backgroundSecondary, background, backgroundDeep],
        ).createShader(rect),
    );

    _radialGlow(
      canvas,
      size,
      center: Offset(size.width * 0.78, size.height * 0.06),
      radius: size.width * 0.72,
      color: mint.withValues(alpha: 0.045),
    );
    _radialGlow(
      canvas,
      size,
      center: Offset(size.width * 0.12, size.height * 0.58),
      radius: size.width * 0.65,
      color: gold.withValues(alpha: 0.035),
    );

    if (pattern) {
      _drawIslamicPattern(
        canvas,
        size,
        color: gold.withValues(alpha: 0.035),
        cell: 58,
        strokeWidth: 0.8,
      );
    }
    if (arch) {
      _drawMihrabWatermark(canvas, size, gold.withValues(alpha: 0.04));
    }
  }

  void _radialGlow(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  void _drawIslamicPattern(
    Canvas canvas,
    Size size, {
    required Color color,
    required double cell,
    required double strokeWidth,
  }) {
    final columns = (size.width / cell).floor() + 2;
    final rows = (size.height / cell).floor() + 2;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final centerX = column * cell + (row.isEven ? 0 : cell / 2);
        final centerY = row * cell;
        final outer = cell * 0.33;
        final inner = cell * 0.16;
        _drawGeometricStar(
          canvas,
          Offset(centerX, centerY),
          outerRadius: outer,
          innerRadius: inner,
          color: color,
          stroke: stroke,
        );
        canvas.drawCircle(
          Offset(centerX, centerY),
          cell * 0.025,
          Paint()..color = color,
        );
      }
    }
  }

  void _drawGeometricStar(
    Canvas canvas,
    Offset center, {
    required double outerRadius,
    required double innerRadius,
    required Color color,
    required Paint stroke,
  }) {
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = ((i * 22.5) - 90.0) * math.pi / 180.0;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, stroke);
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.strokeWidth
        ..color = color.withValues(alpha: color.a * 0.65),
    );
  }

  void _drawMihrabWatermark(Canvas canvas, Size size, Color color) {
    final path = Path();
    final width = math.min(size.width * 0.82, size.height * 0.52);
    final left = (size.width - width) / 2;
    final bottom = size.height * 0.95;
    final top = size.height * 0.18;
    path.moveTo(left, bottom);
    path.lineTo(left, top + width * 0.34);
    path.cubicTo(
      left,
      top + width * 0.1,
      left + width * 0.26,
      top,
      left + width / 2,
      top,
    );
    path.cubicTo(
      left + width * 0.74,
      top,
      left + width,
      top + width * 0.1,
      left + width,
      top + width * 0.34,
    );
    path.lineTo(left + width, bottom);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = color,
    );
    canvas.save();
    canvas.translate(size.width / 2, top);
    canvas.rotate(math.pi / 4);
    canvas.drawLine(
      Offset(0, -18),
      Offset(0, 18),
      Paint()
        ..strokeWidth = 1
        ..color = color.withValues(alpha: color.a * 0.8),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RafiqBackgroundPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.mint != mint ||
        oldDelegate.gold != gold ||
        oldDelegate.pattern != pattern ||
        oldDelegate.arch != arch;
  }
}

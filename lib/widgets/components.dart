import 'package:flutter/material.dart';

import '../theme/rafiq_theme.dart';
import 'rafiq_icons.dart';

class RafiqCard extends StatelessWidget {
  const RafiqCard({
    super.key,
    this.shapeRadius = 22,
    this.contentPadding = const EdgeInsets.all(18),
    this.onTap,
    required this.child,
  });

  final double shapeRadius;
  final EdgeInsets contentPadding;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(shapeRadius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.surfaceHigh.withValues(alpha: 0.92),
            palette.surface.withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(color: palette.borderSoft),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(shapeRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(shapeRadius),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(padding: contentPadding, child: child),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: palette.textPrimary),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: palette.textDim),
                ),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class OrnamentalDivider extends StatelessWidget {
  const OrnamentalDivider({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final lineColor = color ?? palette.gold.withValues(alpha: 0.35);
    return SizedBox(
      height: 20,
      width: double.infinity,
      child: CustomPaint(painter: _OrnamentalDividerPainter(lineColor)),
    );
  }
}

class _OrnamentalDividerPainter extends CustomPainter {
  _OrnamentalDividerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    const middleGap = 18.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = color;
    canvas.drawLine(Offset(0, centerY), Offset(size.width / 2 - middleGap, centerY), paint);
    canvas.drawLine(Offset(size.width / 2 + middleGap, centerY), Offset(size.width, centerY), paint);
    final path = Path()
      ..moveTo(size.width / 2, centerY - 6)
      ..lineTo(size.width / 2 + 6, centerY)
      ..lineTo(size.width / 2, centerY + 6)
      ..lineTo(size.width / 2 - 6, centerY)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color,
    );
    canvas.drawCircle(Offset(size.width / 2, centerY), 1.4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _OrnamentalDividerPainter oldDelegate) => oldDelegate.color != color;
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.filled = false,
    this.tint,
  });

  final RafiqIconData icon;
  final VoidCallback onTap;
  final double size;
  final bool filled;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Material(
      color: filled ? palette.surfaceHigh : palette.surface.withValues(alpha: 0.45),
      shape: CircleBorder(side: BorderSide(color: palette.borderSoft)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: RafiqIcon(
              icon,
              size: size * 0.46,
              color: tint ?? palette.gold,
            ),
          ),
        ),
      ),
    );
  }
}

class BuiltinIconTile extends StatelessWidget {
  const BuiltinIconTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconSize = 56,
  });

  final RafiqIconData icon;
  final String label;
  final VoidCallback onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    palette.surfaceHigh,
                    palette.surface.withValues(alpha: 0.9),
                  ],
                ),
                border: Border.all(color: palette.border),
              ),
              child: Center(
                child: RafiqIcon(icon, size: iconSize * 0.46, color: palette.gold),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: active ? 6 : 4,
          width: active ? 18 : 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? palette.gold : palette.borderSoft,
          ),
        );
      }),
    );
  }
}

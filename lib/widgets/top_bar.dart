import 'package:flutter/material.dart';

import '../theme/rafiq_theme.dart';
import 'components.dart';
import 'rafiq_icons.dart';

class RafiqTopBar extends StatelessWidget {
  const RafiqTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return SizedBox(
      height: 62,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: palette.gold,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: palette.textSecondary),
                  ),
              ],
            ),
            if (onBack != null)
              Positioned(
                right: 0,
                child: RoundIconButton(
                  icon: RafiqIcons.arrowLeft,
                  size: 38,
                  onTap: onBack!,
                ),
              ),
            if (actions != null)
              Positioned(
                left: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < actions!.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      actions![i],
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SegmentedPill extends StatelessWidget {
  const SegmentedPill({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        color: palette.surfaceHigh.withValues(alpha: 0.7),
        border: Border.all(color: palette.borderSoft),
      ),
      child: Row(
        children: List.generate(options.length, (index) {
          final selected = index == selectedIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onSelected(index),
              borderRadius: BorderRadius.circular(13),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Container(
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: selected
                      ? LinearGradient(
                          colors: [palette.goldBright, palette.gold],
                        )
                      : null,
                ),
                child: Text(
                  options[index],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: selected ? palette.backgroundDeep : palette.textSecondary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

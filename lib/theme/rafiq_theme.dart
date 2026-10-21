import 'package:flutter/material.dart';

import 'palette.dart';
import 'typography.dart';

class RafiqThemeScope extends InheritedWidget {
  const RafiqThemeScope({
    super.key,
    required this.palette,
    required this.themeId,
    required super.child,
  });

  final RafiqPalette palette;
  final String themeId;

  static RafiqPalette of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RafiqThemeScope>();
    return scope?.palette ?? emeraldPalette;
  }

  static String themeIdOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RafiqThemeScope>();
    return scope?.themeId ?? 'emerald';
  }

  @override
  bool updateShouldNotify(RafiqThemeScope oldWidget) {
    return oldWidget.palette != palette || oldWidget.themeId != themeId;
  }
}

ThemeData buildRafiqTheme(RafiqPalette palette) {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: palette.background,
    canvasColor: palette.background,
    colorScheme: ColorScheme.dark(
      primary: palette.gold,
      onPrimary: palette.backgroundDeep,
      primaryContainer: palette.surfaceHigh,
      onPrimaryContainer: palette.goldBright,
      secondary: palette.mint,
      onSecondary: palette.backgroundDeep,
      secondaryContainer: palette.surfaceHigh,
      onSecondaryContainer: palette.mint,
      tertiary: palette.goldMuted,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      surfaceContainerHighest: palette.surfaceHigh,
      onSurfaceVariant: palette.textSecondary,
      outline: palette.border,
      outlineVariant: palette.borderSoft,
      error: palette.danger,
      onError: palette.backgroundDeep,
      scrim: Colors.black,
    ),
    textTheme: TextTheme(
      displayLarge: RafiqTypography.displayLarge,
      displayMedium: RafiqTypography.displayMedium,
      displaySmall: RafiqTypography.displaySmall,
      headlineLarge: RafiqTypography.headlineLarge,
      headlineMedium: RafiqTypography.headlineMedium,
      headlineSmall: RafiqTypography.headlineSmall,
      titleLarge: RafiqTypography.titleLarge,
      titleMedium: RafiqTypography.titleMedium,
      titleSmall: RafiqTypography.titleSmall,
      bodyLarge: RafiqTypography.bodyLarge,
      bodyMedium: RafiqTypography.bodyMedium,
      bodySmall: RafiqTypography.bodySmall,
      labelLarge: RafiqTypography.labelLarge,
      labelMedium: RafiqTypography.labelMedium,
      labelSmall: RafiqTypography.labelSmall,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
  );
}

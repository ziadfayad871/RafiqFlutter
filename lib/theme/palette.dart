import 'package:flutter/material.dart';

@immutable
class RafiqPalette {
  const RafiqPalette({
    required this.background,
    required this.backgroundSecondary,
    required this.backgroundDeep,
    required this.surface,
    required this.surfaceHigh,
    required this.surfaceSoft,
    required this.border,
    required this.borderSoft,
    required this.gold,
    required this.goldBright,
    required this.goldMuted,
    required this.mint,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDim,
    required this.danger,
    required this.success,
  });

  final Color background;
  final Color backgroundSecondary;
  final Color backgroundDeep;
  final Color surface;
  final Color surfaceHigh;
  final Color surfaceSoft;
  final Color border;
  final Color borderSoft;
  final Color gold;
  final Color goldBright;
  final Color goldMuted;
  final Color mint;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDim;
  final Color danger;
  final Color success;
}

const emeraldPalette = RafiqPalette(
  background: Color(0xFF02100B),
  backgroundSecondary: Color(0xFF041B14),
  backgroundDeep: Color(0xFF000A07),
  surface: Color(0xFF06231B),
  surfaceHigh: Color(0xFF0A3026),
  surfaceSoft: Color(0xFF0C2C23),
  border: Color(0xFF1B4A3C),
  borderSoft: Color(0xFF12382D),
  gold: Color(0xFFE4CE97),
  goldBright: Color(0xFFF2E4BC),
  goldMuted: Color(0xFFB9A56E),
  mint: Color(0xFF72E2CC),
  textPrimary: Color(0xFFF5F1E7),
  textSecondary: Color(0xFFB5C7BD),
  textDim: Color(0xFF789188),
  danger: Color(0xFFE39A8E),
  success: Color(0xFF75DDC5),
);

const midnightPalette = RafiqPalette(
  background: Color(0xFF010B08),
  backgroundSecondary: Color(0xFF031510),
  backgroundDeep: Color(0xFF000604),
  surface: Color(0xFF041B15),
  surfaceHigh: Color(0xFF07261E),
  surfaceSoft: Color(0xFF08251D),
  border: Color(0xFF173E32),
  borderSoft: Color(0xFF0F2D24),
  gold: Color(0xFFD9C58F),
  goldBright: Color(0xFFF2E4BC),
  goldMuted: Color(0xFFB9A56E),
  mint: Color(0xFF72E2CC),
  textPrimary: Color(0xFFF5F1E7),
  textSecondary: Color(0xFFB5C7BD),
  textDim: Color(0xFF789188),
  danger: Color(0xFFE39A8E),
  success: Color(0xFF75DDC5),
);

const dawnPalette = RafiqPalette(
  background: Color(0xFF07130F),
  backgroundSecondary: Color(0xFF0B2119),
  backgroundDeep: Color(0xFF020B08),
  surface: Color(0xFF0A2A21),
  surfaceHigh: Color(0xFF10382D),
  surfaceSoft: Color(0xFF0E3127),
  border: Color(0xFF265546),
  borderSoft: Color(0xFF1A4437),
  gold: Color(0xFFE8D3A0),
  goldBright: Color(0xFFF2E4BC),
  goldMuted: Color(0xFFB9A56E),
  mint: Color(0xFF83E6D0),
  textPrimary: Color(0xFFF5F1E7),
  textSecondary: Color(0xFFB5C7BD),
  textDim: Color(0xFF789188),
  danger: Color(0xFFE39A8E),
  success: Color(0xFF75DDC5),
);

RafiqPalette paletteFor(String themeId) {
  switch (themeId) {
    case 'midnight':
      return midnightPalette;
    case 'dawn':
      return dawnPalette;
    default:
      return emeraldPalette;
  }
}

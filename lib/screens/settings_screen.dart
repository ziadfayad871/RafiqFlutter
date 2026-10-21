import 'package:flutter/material.dart';

import '../theme/rafiq_theme.dart';
import '../widgets/components.dart';
import '../widgets/rafiq_icons.dart';
import '../widgets/top_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.themeId, required this.onThemeChanged});

  final String themeId;
  final ValueChanged<String> onThemeChanged;

  static const _themes = [
    ('emerald', 'أخضر زمردي', RafiqIcons.palette),
    ('midnight', 'منتصف الليل', RafiqIcons.moon),
    ('dawn', 'الفجر', RafiqIcons.sun),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          const RafiqTopBar(title: 'الإعدادات', subtitle: 'اضبط رفيق على ذوقك'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
              children: [
                const SectionHeader(
                  title: 'المظهر',
                  subtitle: 'اختر السمة التي تناسبك',
                ),
                const SizedBox(height: 12),
                RafiqCard(
                  child: Column(
                    children: _themes.map((entry) {
                      final selected = entry.$1 == themeId;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: InkWell(
                          onTap: () => onThemeChanged(entry.$1),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: selected
                                  ? palette.surfaceHigh.withValues(alpha: 0.6)
                                  : Colors.transparent,
                              border: Border.all(
                                color: selected ? palette.gold : palette.borderSoft,
                              ),
                            ),
                            child: Row(
                              children: [
                                RafiqIcon(entry.$3, size: 20, color: palette.gold),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    entry.$2,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: palette.textPrimary),
                                  ),
                                ),
                                if (selected)
                                  RafiqIcon(RafiqIcons.check, size: 18, color: palette.gold),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'عن رفيق'),
                const SizedBox(height: 12),
                RafiqCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'رفيق · رفيقك اليومي',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: palette.gold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'نسخة Flutter تجريبية — نفس التصميم ونفس البيانات، مع الحفاظ على أوقات الصلاة والمصحف والأذكار.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: palette.textDim),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

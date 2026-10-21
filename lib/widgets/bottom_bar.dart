import 'package:flutter/material.dart';

import '../theme/rafiq_theme.dart';
import 'components.dart';
import 'rafiq_icons.dart';

class BottomItem {
  const BottomItem(this.route, this.label, this.icon);

  final String route;
  final String label;
  final RafiqIconData icon;
}

const bottomItems = [
  BottomItem('home', 'الرئيسية', RafiqIcons.home),
  BottomItem('prayer', 'الصلاة', RafiqIcons.mosque),
  BottomItem('quran', 'quran', RafiqIcons.bookOpen),
  BottomItem('adhkar', 'الأذكار', RafiqIcons.prayerBeads),
  BottomItem('settings', 'الإعدادات', RafiqIcons.settings),
];

class RafiqBottomBar extends StatelessWidget {
  const RafiqBottomBar({
    super.key,
    required this.selectedRoute,
    required this.onNavigate,
  });

  final String selectedRoute;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      width: double.infinity,
      color: palette.backgroundSecondary.withValues(alpha: 0.98),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: OrnamentalDivider(
              color: palette.border.withValues(alpha: 0.8),
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: bottomItems.map((item) {
                  final selected = selectedRoute == item.route ||
                      (item.route == 'quran' && selectedRoute.startsWith('quran'));
                  return Expanded(
                    child: InkWell(
                      onTap: () => onNavigate(item.route),
                      borderRadius: BorderRadius.circular(14),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RafiqIcon(
                              item.icon,
                              size: 22,
                              color: selected ? palette.gold : palette.textDim,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 9.5,
                                height: 14 / 9.5,
                                color: selected ? palette.gold : palette.textDim,
                                fontWeight:
                                    selected ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              height: 2,
                              width: 13,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected ? palette.gold : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

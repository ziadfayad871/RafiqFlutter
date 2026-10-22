import 'package:flutter/material.dart';

import '../app.dart';
import '../platform/bridges.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../theme/rafiq_theme.dart';
import '../theme/typography.dart';
import '../util/arabic_formatters.dart';
import '../widgets/components.dart';
import '../widgets/dawn_mosque_scene.dart';
import '../widgets/rafiq_icons.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final appState = AppScope.of(context);
    final prayer = PrayerScope.of(context);
    final now = prayer.now;
    final next = prayer.next;

    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 38, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GreetingHeader(
                greeting: _greeting(now.hour),
                displayName: appState.preferences.displayName,
                locationLabel: appState.preferences.locationLabel,
                onOpenApps: () {
                  appState.click();
                  onNavigate('apps');
                },
              ),
              const SizedBox(height: 14),
              Column(
                children: [
                  Text(
                    toArabicDigits(
                      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                    ),
                    style: RafiqText.clock.copyWith(color: palette.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatGregorianDate(now),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: palette.textSecondary),
                  ),
                  Text(
                    formatHijriDate(now),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: palette.goldMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 210,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: palette.borderSoft),
                ),
                child: const DawnMosqueScene(),
              ),
              const SizedBox(height: 18),
              _NextPrayerCard(
                name: next?.prayer.name,
                time: next?.prayer.formattedTime,
                countdown: next == null
                    ? null
                    : formatCountdown(next.remaining) +
                        (next.tomorrow ? ' (غدًا)' : ''),
                progress: next?.progress ?? 0,
                onTap: () {
                  appState.click();
                  onNavigate('prayer');
                },
              ),
              const SizedBox(height: 20),
              const SectionHeader(title: 'عباداتك اليوم'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: BuiltinIconTile(
                      icon: RafiqIcons.quranBook,
                      label: 'القرآن',
                      onTap: () {
                        appState.click();
                        onNavigate('quran');
                      },
                    ),
                  ),
                  Expanded(
                    child: BuiltinIconTile(
                      icon: RafiqIcons.prayerBeads,
                      label: 'الأذكار',
                      onTap: () {
                        appState.click();
                        onNavigate('adhkar');
                      },
                    ),
                  ),
                  Expanded(
                    child: BuiltinIconTile(
                      icon: RafiqIcons.tasks,
                      label: 'المهام',
                      onTap: () {
                        appState.click();
                        onNavigate('tasks');
                      },
                    ),
                  ),
                  Expanded(
                    child: BuiltinIconTile(
                      icon: RafiqIcons.focus,
                      label: 'التركيز',
                      onTap: () {
                        appState.click();
                        onNavigate('focus');
                      },
                    ),
                  ),
                  Expanded(
                    child: BuiltinIconTile(
                      icon: RafiqIcons.sparkle,
                      label: 'مساعد رفيق',
                      onTap: () {
                        appState.click();
                        onNavigate('assistant');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const PageDots(count: 5, activeIndex: 0),
              const SizedBox(height: 16),
              const _DockRow(),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  static String _greeting(int hour) {
    if (hour >= 4 && hour <= 11) return 'صباح الخير';
    if (hour >= 12 && hour <= 16) return 'طاب نهارك';
    if (hour >= 17 && hour <= 20) return 'مساء الخير';
    return 'طابت ليلتك';
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.greeting,
    required this.displayName,
    required this.locationLabel,
    required this.onOpenApps,
  });

  final String greeting;
  final String displayName;
  final String locationLabel;
  final VoidCallback onOpenApps;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: palette.textDim),
              ),
              Text(
                displayName,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: palette.gold),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: palette.surface.withValues(alpha: 0.7),
            border: Border.all(color: palette.borderSoft),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RafiqIcon(RafiqIcons.location, size: 14, color: palette.mint),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  locationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: palette.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        RoundIconButton(
          icon: RafiqIcons.menuLines,
          size: 38,
          onTap: onOpenApps,
        ),
      ],
    );
  }
}

class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard({
    required this.name,
    required this.time,
    required this.countdown,
    required this.progress,
    required this.onTap,
  });

  final String? name;
  final String? time;
  final String? countdown;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return RafiqCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.surfaceHigh.withValues(alpha: 0.8),
                  border: Border.all(color: palette.border),
                ),
                child: Center(
                  child: RafiqIcon(RafiqIcons.mosque, size: 21, color: palette.gold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الصلاة القادمة',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: palette.textDim),
                    ),
                    Text(
                      name ?? 'جارٍ الحساب',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: palette.textPrimary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    time ?? '--:--',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: palette.gold,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (countdown != null)
                    Text(
                      countdown!,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: palette.textSecondary),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.borderSoft.withValues(alpha: 0.5),
            ),
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.02, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [palette.goldMuted, palette.goldBright],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DockRow extends StatelessWidget {
  const _DockRow();

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final appState = AppScope.of(context);
    return _DockContent(
      palette: palette,
      onOpen: (kind) {
        appState.click();
        LauncherBridge.launchDock(kind);
      },
    );
  }
}

class _DockContent extends StatelessWidget {
  const _DockContent({required this.palette, required this.onOpen});

  final RafiqPalette palette;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: LauncherBridge.dockApps(),
      builder: (context, snapshot) {
        final apps = snapshot.data ?? const [];
        if (apps.isEmpty) {
          return const SizedBox(height: 68);
        }
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: palette.surface.withValues(alpha: 0.55),
            border: Border.all(color: palette.borderSoft),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: apps.map((app) {
              final icon = switch (app.kind) {
                'phone' => RafiqIcons.phone,
                'messages' => RafiqIcons.message,
                'browser' => RafiqIcons.browser,
                _ => RafiqIcons.camera,
              };
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: palette.surfaceHigh,
                        border: Border.all(color: palette.borderSoft),
                      ),
                      child: InkWell(
                        onTap: () => onOpen(app.kind),
                        borderRadius: BorderRadius.circular(15),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        child: Center(
                          child: RafiqIcon(icon, size: 22, color: palette.gold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 9,
                        height: 13 / 9,
                        color: palette.textDim,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

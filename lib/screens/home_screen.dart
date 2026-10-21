import 'dart:async';

import 'package:flutter/material.dart';

import '../data/prayer_calculator.dart';
import '../theme/rafiq_theme.dart';
import '../theme/typography.dart';
import '../util/arabic_formatters.dart';
import '../widgets/components.dart';
import '../widgets/dawn_mosque_scene.dart';
import '../widgets/rafiq_icons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _latitude = 30.0444;
  static const _longitude = 31.2357;

  Timer? _timer;
  DateTime _now = DateTime.now();
  NextPrayerInfo? _next;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refresh() {
    final now = DateTime.now();
    final offset = DateTime(now.year, now.month, now.day, 12).timeZoneOffset;
    final today = PrayerCalculator.calculate(
      date: now,
      latitude: _latitude,
      longitude: _longitude,
      offset: offset,
      method: CalculationMethod.egyptian,
    );
    final tomorrow = PrayerCalculator.calculate(
      date: now.add(const Duration(days: 1)),
      latitude: _latitude,
      longitude: _longitude,
      offset: offset,
      method: CalculationMethod.egyptian,
    );
    final yesterday = PrayerCalculator.calculate(
      date: now.subtract(const Duration(days: 1)),
      latitude: _latitude,
      longitude: _longitude,
      offset: offset,
      method: CalculationMethod.egyptian,
    );
    final next = PrayerCalculator.nextPrayer(
      today: today,
      now: now,
      tomorrow: tomorrow,
      yesterday: yesterday,
    );
    setState(() {
      _now = now;
      _next = next;
    });
  }

  String get _greeting {
    final hour = _now.hour;
    if (hour >= 4 && hour <= 11) return 'صباح الخير';
    if (hour >= 12 && hour <= 16) return 'طاب نهارك';
    if (hour >= 17 && hour <= 20) return 'مساء الخير';
    return 'طابت ليلتك';
  }

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 38, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GreetingHeader(
                greeting: _greeting,
                displayName: 'رفيق',
                locationLabel: 'القاهرة',
                onOpenApps: () => widget.onNavigate('apps'),
              ),
              const SizedBox(height: 14),
              Column(
                children: [
                  Text(
                    toArabicDigits(
                      '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                    ),
                    style: RafiqText.clock.copyWith(color: palette.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatGregorianDate(_now),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: palette.textSecondary),
                  ),
                  Text(
                    formatHijriDate(_now),
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
                name: _next?.prayer.name,
                time: _next?.prayer.formattedTime,
                countdown: _next == null
                    ? null
                    : formatCountdown(_next!.remaining) +
                        (_next!.tomorrow ? ' (غدًا)' : ''),
                progress: _next?.progress ?? 0,
                onTap: () => widget.onNavigate('prayer'),
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
                      onTap: () => widget.onNavigate('quran'),
                    ),
                  ),
                  Expanded(
                    child: BuiltinIconTile(
                      icon: RafiqIcons.prayerBeads,
                      label: 'الأذكار',
                      onTap: () => widget.onNavigate('adhkar'),
                    ),
                  ),
                  Expanded(
                    child: BuiltinIconTile(
                      icon: RafiqIcons.tasks,
                      label: 'المهام',
                      onTap: () => widget.onNavigate('tasks'),
                    ),
                  ),
                  Expanded(
                    child: BuiltinIconTile(
                      icon: RafiqIcons.focus,
                      label: 'التركيز',
                      onTap: () => widget.onNavigate('focus'),
                    ),
                  ),
                  Expanded(
                    child: BuiltinIconTile(
                      icon: RafiqIcons.sparkle,
                      label: 'مساعد رفيق',
                      onTap: () => widget.onNavigate('assistant'),
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

  static const _dock = [
    ('الهاتف', RafiqIcons.phone),
    ('الرسائل', RafiqIcons.message),
    ('المتصفح', RafiqIcons.browser),
    ('الكاميرا', RafiqIcons.camera),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: palette.surface.withValues(alpha: 0.55),
        border: Border.all(color: palette.borderSoft),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _dock.map((entry) {
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
                  child: Center(
                    child: RafiqIcon(entry.$2, size: 22, color: palette.gold),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.$1,
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
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../data/prayer_calculator.dart';
import '../theme/rafiq_theme.dart';
import '../util/arabic_formatters.dart';
import '../widgets/components.dart';
import '../widgets/rafiq_icons.dart';
import '../widgets/top_bar.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  static const _latitude = 30.0444;
  static const _longitude = 31.2357;

  Timer? _timer;
  PrayerTimes? _today;
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
      _today = today;
      _next = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final today = _today;
    final next = _next;
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          const RafiqTopBar(title: 'الصلاة', subtitle: 'المواقيت في القاهرة'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    color: palette.surface.withValues(alpha: 0.45),
                    border: Border.all(color: palette.borderSoft),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'الصلاة القادمة',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: palette.textDim),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        next?.prayer.name ?? 'جارٍ الحساب',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: palette.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        next?.prayer.formattedTime ?? '--:--',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: palette.gold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        next == null
                            ? ''
                            : formatCountdown(next.remaining) +
                                (next.tomorrow ? ' (غدًا)' : ''),
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: palette.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (today != null)
                  RafiqCard(
                    child: Column(
                      children: [
                        _TimeRow(
                          label: 'الفجر',
                          value: today.fajr,
                          active: next?.prayer.id == PrayerId.fajr,
                        ),
                        _TimeRow(
                          label: 'الظهر',
                          value: today.dhuhr,
                          active: next?.prayer.id == PrayerId.dhuhr,
                        ),
                        _TimeRow(
                          label: 'العصر',
                          value: today.asr,
                          active: next?.prayer.id == PrayerId.asr,
                        ),
                        _TimeRow(
                          label: 'المغرب',
                          value: today.maghrib,
                          active: next?.prayer.id == PrayerId.maghrib,
                        ),
                        _TimeRow(
                          label: 'العشاء',
                          value: today.isha,
                          active: next?.prayer.id == PrayerId.isha,
                          last: true,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _InfoChip(
                        icon: RafiqIcons.location,
                        label: 'القاهرة',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoChip(
                        icon: RafiqIcons.settings,
                        label: CalculationMethod.egyptian.arabicName,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.value,
    required this.active,
    this.last = false,
  });

  final String label;
  final DateTime value;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                  color: palette.borderSoft.withValues(alpha: 0.5),
                ),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? palette.gold : palette.borderSoft,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: active ? palette.gold : palette.textPrimary,
                  ),
            ),
          ),
          Text(
            toArabicDigits(
              '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final RafiqIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: palette.surface.withValues(alpha: 0.55),
        border: Border.all(color: palette.borderSoft),
      ),
      child: Row(
        children: [
          RafiqIcon(icon, size: 15, color: palette.mint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
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
    );
  }
}

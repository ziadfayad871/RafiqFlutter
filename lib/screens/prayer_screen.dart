import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../data/prayer_calculator.dart';
import '../state/app_state.dart';
import '../state/settings_state.dart';
import '../theme/rafiq_theme.dart';
import '../theme/typography.dart';
import '../util/arabic_formatters.dart';
import '../widgets/components.dart';
import '../widgets/rafiq_icons.dart';
import '../widgets/top_bar.dart';
import 'settings_screen.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  late final SettingsState _settings;

  @override
  void initState() {
    super.initState();
    _settings = SettingsState(AppScope.read(context));
    _settings.addListener(_handleSettingsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _settings.refreshExactAlarmPermission();
    });
  }

  @override
  void dispose() {
    _settings.removeListener(_handleSettingsChanged);
    _settings.dispose();
    super.dispose();
  }

  void _handleSettingsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleNotifications(bool enabled) async {
    final prayer = PrayerScope.of(context);
    final next = prayer.next;
    await _settings.setNotificationsEnabled(
      enabled,
      triggerAt: next?.prayer.time,
      prayerName: next?.prayer.name,
      prayerTime: next?.prayer.formattedTime,
    );
  }

  Future<void> _openMethodSheet() async {
    final prayer = PrayerScope.of(context);
    final selected = await showPrayerMethodSheet(
      context,
      current: prayer.method,
    );
    if (selected == null) return;
    if (!mounted) return;
    await _settings.setCalculationMethod(selected);
    prayer.update(method: selected);
  }

  Future<void> _openCitySheet() async {
    final prayer = PrayerScope.of(context);
    final selected = await showPrayerCitySheet(
      context,
      currentLabel: prayer.locationLabel,
    );
    if (selected == null) return;
    if (!mounted) return;
    if (selected.id == '__detect__') {
      await _detectLocation();
      return;
    }
    await _settings.setCity(selected);
    prayer.update(
      latitude: selected.latitude,
      longitude: selected.longitude,
      locationLabel: selected.name,
    );
  }

  Future<void> _detectLocation() async {
    final detected = await _settings.detectLocation();
    if (!mounted) return;
    if (detected == null) return;
    final prayer = PrayerScope.of(context);
    prayer.update(
      latitude: detected.latitude,
      longitude: detected.longitude,
      locationLabel: 'موقعك الحالي',
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final appState = AppScope.of(context);
    final prayer = PrayerScope.of(context);
    final today = prayer.today;
    final next = prayer.next;
    final notificationsEnabled = appState.preferences.prayerNotifications;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _settings.syncPrayerAlarm(
        enabled: notificationsEnabled,
        triggerAt: next?.prayer.time,
        prayerName: next?.prayer.name ?? 'الصلاة',
        prayerTime: next?.prayer.formattedTime ?? '',
      );
    });

    return Container(
      color: Colors.transparent,
      child: Stack(
        children: [
          Column(
            children: [
              RafiqTopBar(
                title: 'الصلاة',
                subtitle: 'المواقيت في ${prayer.locationLabel}',
                actions: [
                  RoundIconButton(
                    icon: RafiqIcons.location,
                    size: 38,
                    onTap: () => unawaited(_detectLocation()),
                  ),
                  RoundIconButton(
                    icon: RafiqIcons.bell,
                    size: 38,
                    tint: notificationsEnabled
                        ? palette.goldBright
                        : palette.textDim,
                    onTap: () =>
                        unawaited(_toggleNotifications(!notificationsEnabled)),
                  ),
                  RoundIconButton(
                    icon: RafiqIcons.settings,
                    size: 38,
                    onTap: () => unawaited(_openMethodSheet()),
                  ),
                ],
              ),
              Expanded(
                child: today == null
                    ? const _LoadingOrnament(label: 'جارٍ حساب المواقيت')
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            _buildRing(context, next),
                            Row(
                              children: [
                                Expanded(
                                  child: _Chip(
                                    text: prayer.locationLabel,
                                    icon: RafiqIcons.location,
                                    onTap: () => unawaited(_openCitySheet()),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _Chip(
                                    text: prayer.method.arabicName,
                                    icon: RafiqIcons.settings,
                                    onTap: () => unawaited(_openMethodSheet()),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _buildTimesCard(context, today, next),
                            const SizedBox(height: 14),
                            if (today.highLatitudeApproximation) ...[
                              Text(
                                'في خطوط العرض العالية قد تُقدَّر مواقيت الفجر والعشاء عند تعذّر الحساب الفلكي الدقيق.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: palette.textDim),
                              ),
                              const SizedBox(height: 10),
                            ],
                            Text(
                              'الفجر ${formatTime12Hour(today.fajr)} • '
                              'الشروق ${formatTime12Hour(today.sunrise)}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: palette.textDim),
                            ),
                            if (_supportsExactAlarm) ...[
                              const SizedBox(height: 14),
                              RafiqSettingsGroup(
                                children: [
                                  RafiqSettingsRow(
                                    icon: RafiqIcons.clock,
                                    title: 'إذن المنبّهات الدقيقة',
                                    value: _settings.canScheduleExact
                                        ? 'مسموح'
                                        : 'غير مسموح',
                                    onTap: () => unawaited(
                                      _settings.openExactAlarmSettings(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 14),
                            RafiqSecondaryButton(
                              text: notificationsEnabled
                                  ? 'تنبيهات الصلاة مفعّلة'
                                  : 'تفعيل تنبيهات الصلاة',
                              icon: RafiqIcons.bell,
                              onTap: () => unawaited(
                                _toggleNotifications(!notificationsEnabled),
                              ),
                            ),
                            const SizedBox(height: 10),
                            RafiqSecondaryButton(
                              text: 'إرسال تنبيه تجريبي',
                              icon: RafiqIcons.bell,
                              onTap: () => unawaited(
                                _settings.showTestPrayerNotification(),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          if (_settings.message != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: RafiqTransientMessage(
                message: _settings.message!,
                onConsumed: _settings.consumeMessage,
              ),
            ),
        ],
      ),
    );
  }

  bool get _supportsExactAlarm =>
      defaultTargetPlatform == TargetPlatform.android;

  Widget _buildRing(BuildContext context, NextPrayerInfo? next) {
    final palette = RafiqThemeScope.of(context);
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(230),
            painter: _CountdownRingPainter(
              progress: next?.progress ?? 0,
              trackColor: palette.borderSoft.withValues(alpha: 0.5),
              gradientColors: [
                palette.goldMuted,
                palette.gold,
                palette.goldBright,
                palette.goldMuted,
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الصلاة القادمة',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: palette.textDim),
              ),
              Text(
                next?.prayer.name ?? '--',
                style: RafiqText.ornamentTitle.copyWith(color: palette.gold),
              ),
              Text(
                next == null ? '--:--' : formatTime12Hour(next.prayer.time),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: palette.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                next == null ? '--:--' : formatCountdownShort(next.remaining),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: palette.mint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimesCard(
    BuildContext context,
    PrayerTimes today,
    NextPrayerInfo? next,
  ) {
    final palette = RafiqThemeScope.of(context);
    final prayers = today.prayers;
    return RafiqCard(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < prayers.length; index++) ...[
            _PrayerRow(
              name: prayers[index].name,
              time: formatTime12Hour(prayers[index].time),
              isNext: next?.prayer.id == prayers[index].id,
              estimated: index == 0 && today.highLatitudeApproximation,
            ),
            if (index < prayers.length - 1)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: palette.borderSoft.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.name,
    required this.time,
    required this.isNext,
    required this.estimated,
  });

  final String name;
  final String time;
  final bool isNext;
  final bool estimated;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isNext ? palette.gold : palette.borderSoft,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isNext ? palette.gold : palette.textPrimary,
              ),
            ),
          ),
          if (estimated) ...[
            _CountBadge(text: 'تقديري'),
            const SizedBox(width: 8),
          ],
          Text(
            time,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isNext ? palette.gold : palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: palette.surfaceHigh.withValues(alpha: 0.85),
        border: Border.all(color: palette.borderSoft),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: palette.gold,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.icon, required this.onTap});

  final String text;
  final RafiqIconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: palette.surface.withValues(alpha: 0.7),
            border: Border.all(color: palette.borderSoft),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              RafiqIcon(icon, size: 14, color: palette.goldMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  const _CountdownRingPainter({
    required this.progress,
    required this.trackColor,
    required this.gradientColors,
  });

  final double progress;
  final Color trackColor;
  final List<Color> gradientColors;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final inset = stroke / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - stroke,
      size.height - stroke,
    );
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);
    final sweep = math.max(progress.clamp(0.0, 1.0) * 360, 4);
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: gradientColors,
      ).createShader(Offset.zero & size);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep * math.pi / 180,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      !_sameColors(oldDelegate.gradientColors, gradientColors);
}

bool _sameColors(List<Color> a, List<Color> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class _LoadingOrnament extends StatefulWidget {
  const _LoadingOrnament({required this.label});

  final String label;

  @override
  State<_LoadingOrnament> createState() => _LoadingOrnamentState();
}

class _LoadingOrnamentState extends State<_LoadingOrnament>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 78,
          height: 78,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => CustomPaint(
              painter: _LoadingRingPainter(
                rotation: _controller.value * math.pi * 2,
                borderColor: palette.border,
                goldColor: palette.gold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          widget.label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        ),
      ],
    );
  }
}

class _LoadingRingPainter extends CustomPainter {
  const _LoadingRingPainter({
    required this.rotation,
    required this.borderColor,
    required this.goldColor,
  });

  final double rotation;
  final Color borderColor;
  final Color goldColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = borderColor;
    canvas.drawArc(rect, 0, math.pi * 2, false, borderPaint);
    final goldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [Colors.transparent, goldColor],
      ).createShader(rect);
    canvas.drawArc(rect, rotation, 120 * math.pi / 180, false, goldPaint);
  }

  @override
  bool shouldRepaint(covariant _LoadingRingPainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.goldColor != goldColor;
}

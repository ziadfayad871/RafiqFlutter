import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../platform/bridges.dart';
import '../state/app_state.dart';
import '../state/focus_state.dart';
import '../theme/palette.dart';
import '../theme/rafiq_theme.dart';
import '../theme/typography.dart';
import '../util/arabic_formatters.dart';
import '../widgets/components.dart';
import '../widgets/rafiq_icons.dart';
import '../widgets/top_bar.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({
    super.key,
    required this.onBack,
    this.initialDurationMinutes,
    this.initialSessionTitle,
    this.autoStart = false,
  });

  final VoidCallback onBack;
  final int? initialDurationMinutes;
  final String? initialSessionTitle;
  final bool autoStart;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  late final FocusState _state;
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _state = FocusState(appState: AppScope.read(context));
    _state.init(
      initialDurationMinutes: widget.initialDurationMinutes,
      initialSessionTitle: widget.initialSessionTitle,
    );
    _titleController = TextEditingController(text: _state.sessionTitle);
    if (widget.autoStart && _state.phase == FocusPhase.idle) {
      _state.start();
    }
  }

  @override
  void dispose() {
    _state.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _click() {
    AppScope.read(context).click();
  }

  void _selectTitle(String title) {
    _click();
    _titleController.text = title;
    _titleController.selection = TextSelection.collapsed(offset: title.length);
    _state.setSessionTitle(title);
  }

  String _formatRemaining(int millis) {
    final safe = millis < 0 ? 0 : millis;
    final totalSeconds = safe ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return toArabicDigits(
      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scope = context.dependOnInheritedWidgetOfExactType<RafiqThemeScope>();
    final appState = AppScope.of(context);
    final palette = scope?.palette ?? paletteFor(appState.preferences.theme);
    final themeId = scope?.themeId ?? appState.preferences.theme;
    return RafiqThemeScope(
      palette: palette,
      themeId: themeId,
      child: Container(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.only(
            top: media.padding.top,
            bottom: media.padding.bottom,
          ),
          child: AnimatedBuilder(
            animation: _state,
            builder: (context, _) {
              return Column(
                children: [
                  RafiqTopBar(
                    title: 'التركيز',
                    subtitle: _state.sessionTitle,
                    onBack: () {
                      _click();
                      widget.onBack();
                    },
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildRing(),
                          const SizedBox(height: 8),
                          if (_state.phase == FocusPhase.idle ||
                              _state.phase == FocusPhase.paused) ...[
                            _buildDurationRow(),
                            const SizedBox(height: 12),
                            _buildTitleRow(),
                            const SizedBox(height: 10),
                            _buildTitleInput(),
                            const SizedBox(height: 18),
                          ],
                          _buildActions(),
                          const SizedBox(height: 22),
                          Text(
                            'التطبيقات المسموحة أثناء الجلسة',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: RafiqThemeScope.of(
                                    context,
                                  ).textPrimary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'يفتح أندرويد واجهات التركيز الرسمية فقط للتطبيقات المثبتة كقاذف. رفيق يحتفظ بقائمتك كمرجع وتذكير، وسيستخدمها في تجربة التركيز الكاملة على الأجهزة التي تدعم ذلك.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: RafiqThemeScope.of(context).textDim,
                                ),
                          ),
                          const SizedBox(height: 10),
                          _buildAllowedApps(),
                        ],
                      ),
                    ),
                  ),
                  _TransientMessage(
                    message: _state.message,
                    onConsumed: _state.consumeMessage,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRing() {
    final palette = RafiqThemeScope.of(context);
    final phase = _state.phase;
    final label = switch (phase) {
      FocusPhase.idle => 'جاهز للبدء',
      FocusPhase.running => 'جلسة جارية',
      FocusPhase.paused => 'متوقفة مؤقتًا',
      FocusPhase.completed => 'أُنجزت الجلسة',
    };
    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(230),
            painter: _FocusRingPainter(
              progress: _state.progress,
              active: phase == FocusPhase.running,
              trackColor: palette.borderSoft.withValues(alpha: 0.45),
              gradientColors: [
                phase == FocusPhase.running ? palette.mint : palette.goldMuted,
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
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: palette.textDim),
              ),
              Text(
                _formatRemaining(_state.remainingMs),
                textDirection: TextDirection.ltr,
                style: RafiqText.timer.copyWith(color: palette.textPrimary),
              ),
              Text(
                _state.sessionTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: palette.gold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationRow() {
    const options = <int>[15, 25, 45, 60];
    final palette = RafiqThemeScope.of(context);
    final enabled = _state.phase == FocusPhase.idle;
    return Row(
      children: [
        for (final minutes in options) ...[
          if (minutes != options.first) const SizedBox(width: 8),
          Expanded(
            child: _ChipButton(
              height: 40,
              radius: 14,
              selected: minutes == _state.durationMinutes,
              selectedBackground: palette.gold.withValues(alpha: 0.18),
              selectedBorder: palette.gold,
              selectedTextColor: palette.goldBright,
              background: palette.surface.withValues(alpha: 0.6),
              borderColor: palette.borderSoft,
              textColor: palette.textSecondary,
              text: toArabicDigits('$minutes دقيقة'),
              onTap: enabled
                  ? () {
                      _click();
                      _state.setDuration(minutes);
                    }
                  : null,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTitleRow() {
    const titles = <String>['الدراسة', 'العمل', 'القرآن', 'قراءة'];
    final palette = RafiqThemeScope.of(context);
    return Row(
      children: [
        for (final title in titles) ...[
          if (title != titles.first) const SizedBox(width: 8),
          Expanded(
            child: _ChipButton(
              height: 38,
              radius: 13,
              selected: title == _state.sessionTitle,
              selectedBackground: palette.surfaceHigh,
              selectedBorder: palette.border,
              selectedTextColor: palette.gold,
              background: Colors.transparent,
              borderColor: palette.borderSoft,
              textColor: palette.textSecondary,
              text: title,
              onTap: () => _selectTitle(title),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTitleInput() {
    final palette = RafiqThemeScope.of(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: palette.surface.withValues(alpha: 0.6),
        border: Border.all(color: palette.borderSoft),
      ),
      child: Row(
        children: [
          RafiqIcon(RafiqIcons.edit, size: 16, color: palette.goldMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _titleController,
              onChanged: (value) => _state.setSessionTitle(value),
              onSubmitted: (value) => _state.setSessionTitle(value),
              maxLines: 1,
              textInputAction: TextInputAction.done,
              cursorColor: palette.gold,
              cursorWidth: 1.6,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'اسم الجلسة',
                hintStyle: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: palette.textDim),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    switch (_state.phase) {
      case FocusPhase.idle:
        return _RafiqPrimaryButton(
          text: 'ابدأ جلسة التركيز',
          icon: RafiqIcons.play,
          onTap: () {
            _click();
            _state.start();
          },
        );
      case FocusPhase.running:
        return Row(
          children: [
            Expanded(
              child: _RafiqPrimaryButton(
                text: 'إيقاف مؤقت',
                icon: RafiqIcons.pause,
                onTap: () {
                  _click();
                  _state.pause();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RafiqSecondaryButton(
                text: 'إنهاء',
                icon: RafiqIcons.close,
                onTap: () {
                  _click();
                  _state.reset();
                },
              ),
            ),
          ],
        );
      case FocusPhase.paused:
        return Row(
          children: [
            Expanded(
              child: _RafiqPrimaryButton(
                text: 'متابعة',
                icon: RafiqIcons.play,
                onTap: () {
                  _click();
                  _state.resume();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RafiqSecondaryButton(
                text: 'إنهاء',
                icon: RafiqIcons.close,
                onTap: () {
                  _click();
                  _state.reset();
                },
              ),
            ),
          ],
        );
      case FocusPhase.completed:
        return _RafiqPrimaryButton(
          text: 'جلسة جديدة',
          icon: RafiqIcons.refresh,
          onTap: () {
            _click();
            _state.reset();
          },
        );
    }
  }

  Widget _buildAllowedApps() {
    final palette = RafiqThemeScope.of(context);
    return RafiqCard(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_state.isLoadingApps)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'جارٍ قراءة التطبيقات...',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.textDim),
              ),
            )
          else if (_state.installedApps.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'لا توجد تطبيقات مثبتة ظاهرة',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.textDim),
              ),
            )
          else
            for (final app in _state.installedApps)
              _AllowedAppRow(
                app: app,
                allowed: _state.allowedPackages.contains(app.packageName),
                onToggle: () {
                  _click();
                  _state.toggleAllowedPackage(app.packageName);
                },
              ),
        ],
      ),
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter({
    required this.progress,
    required this.active,
    required this.trackColor,
    required this.gradientColors,
  });

  final double progress;
  final bool active;
  final Color trackColor;
  final List<Color> gradientColors;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
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
    final sweep = math.max(progress.clamp(0.0, 1.0) * 360, 3);
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(colors: gradientColors).createShader(rect);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep * math.pi / 180,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FocusRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.active != active ||
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

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.height,
    required this.radius,
    required this.selected,
    required this.selectedBackground,
    required this.selectedBorder,
    required this.selectedTextColor,
    required this.background,
    required this.borderColor,
    required this.textColor,
    required this.text,
    required this.onTap,
  });

  final double height;
  final double radius;
  final bool selected;
  final Color selectedBackground;
  final Color selectedBorder;
  final Color selectedTextColor;
  final Color background;
  final Color borderColor;
  final Color textColor;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? selectedBackground : background,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: selected ? selectedBorder : borderColor),
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? selectedTextColor : textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _AllowedAppRow extends StatelessWidget {
  const _AllowedAppRow({
    required this.app,
    required this.allowed,
    required this.onToggle,
  });

  final InstalledApp app;
  final bool allowed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return InkWell(
      onTap: onToggle,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            _AppIconImage(icon: app.icon, label: app.label, iconSize: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                app.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: allowed
                    ? palette.gold.withValues(alpha: 0.2)
                    : Colors.transparent,
                border: Border.all(
                  color: allowed ? palette.gold : palette.borderSoft,
                ),
              ),
              alignment: Alignment.center,
              child: allowed
                  ? RafiqIcon(
                      RafiqIcons.check,
                      size: 14,
                      color: palette.goldBright,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppIconImage extends StatelessWidget {
  const _AppIconImage({
    required this.icon,
    required this.label,
    required this.iconSize,
  });

  final Uint8List? icon;
  final String label;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: palette.surfaceHigh,
        border: Border.all(color: palette.borderSoft),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Image.memory(
              icon!,
              width: iconSize * 0.68,
              height: iconSize * 0.68,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
            )
          : Text(
              label.isEmpty ? '؟' : label.substring(0, 1),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: palette.gold),
            ),
    );
  }
}

class _RafiqPrimaryButton extends StatelessWidget {
  const _RafiqPrimaryButton({
    required this.text,
    required this.onTap,
    this.icon,
  });

  final String text;
  final VoidCallback onTap;
  final RafiqIconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            gradient: LinearGradient(
              colors: [palette.goldBright, palette.gold, palette.goldMuted],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (icon != null) ...[
                RafiqIcon(icon!, size: 19, color: palette.backgroundDeep),
                const SizedBox(width: 9),
              ],
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.backgroundDeep,
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

class _RafiqSecondaryButton extends StatelessWidget {
  const _RafiqSecondaryButton({
    required this.text,
    required this.onTap,
    this.icon,
  });

  final String text;
  final VoidCallback onTap;
  final RafiqIconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Material(
      color: palette.surfaceHigh.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (icon != null) ...[
                RafiqIcon(icon!, size: 18, color: palette.gold),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: palette.gold,
                    fontWeight: FontWeight.w500,
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

class _TransientMessage extends StatefulWidget {
  const _TransientMessage({required this.message, required this.onConsumed});

  final String? message;
  final VoidCallback onConsumed;

  @override
  State<_TransientMessage> createState() => _TransientMessageState();
}

class _TransientMessageState extends State<_TransientMessage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant _TransientMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _schedule();
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (widget.message == null) return;
    _timer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      widget.onConsumed();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    if (message == null) return const SizedBox.shrink();
    final palette = RafiqThemeScope.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: palette.surfaceHigh.withValues(alpha: 0.97),
          border: Border.all(color: palette.border),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
        ),
      ),
    );
  }
}

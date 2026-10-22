import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../platform/bridges.dart';
import '../state/app_state.dart';
import '../state/apps_state.dart';
import '../theme/palette.dart';
import '../theme/rafiq_theme.dart';
import '../widgets/components.dart';
import '../widgets/rafiq_icons.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key, required this.onBack, this.onOpenDestination});

  final VoidCallback onBack;
  final ValueChanged<String>? onOpenDestination;

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  final AppsState _state = AppsState();
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _state.refresh();
  }

  @override
  void dispose() {
    _state.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _click() {
    AppScope.read(context).click();
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
    });
  }

  void _openBuiltin(BuiltinApp app) {
    _click();
    final handler = widget.onOpenDestination;
    if (handler != null) {
      handler(app.destination);
    }
  }

  void _openInstalled(InstalledApp app) {
    _click();
    _state.launch(app);
  }

  List<BuiltinApp> _filteredBuiltins() {
    if (_query.trim().isEmpty) return AppsState.builtinApps;
    final needle = normalizeArabicForSearch(_query);
    return AppsState.builtinApps
        .where((app) => normalizeArabicForSearch(app.label).contains(needle))
        .toList();
  }

  List<InstalledApp> _filteredInstalled() {
    if (_query.trim().isEmpty) return _state.installedApps;
    final needle = normalizeArabicForSearch(_query);
    return _state.installedApps
        .where((app) => normalizeArabicForSearch(app.label).contains(needle))
        .toList();
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
        child: AnimatedBuilder(
          animation: _state,
          builder: (context, _) {
            final builtins = _filteredBuiltins();
            final installed = _filteredInstalled();
            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: 18,
                      end: 18,
                      top: media.padding.top + 40,
                      bottom: media.padding.bottom + 14,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            RoundIconButton(
                              icon: RafiqIcons.arrowLeft,
                              onTap: () {
                                _click();
                                widget.onBack();
                              },
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SearchField(
                                controller: _queryController,
                                onChanged: _onQueryChanged,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Expanded(child: _buildContent(builtins, installed)),
                        const SizedBox(height: 10),
                        const PageDots(count: 4, activeIndex: 0),
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
    );
  }

  Widget _buildContent(
    List<BuiltinApp> builtins,
    List<InstalledApp> installed,
  ) {
    if (_state.isLoading) {
      return const _LoadingOrnament(label: 'جارٍ ترتيب التطبيقات');
    }
    if (_state.error != null) {
      return _ErrorOrnament(
        message: _state.error!,
        onRetry: () {
          _click();
          _state.refresh();
        },
      );
    }
    final tiles = <Widget>[
      for (final app in builtins)
        BuiltinIconTile(
          icon: app.icon,
          label: app.label,
          iconSize: 58,
          onTap: () => _openBuiltin(app),
        ),
      for (final app in installed)
        _InstalledAppTile(app: app, onTap: () => _openInstalled(app)),
    ];
    if (tiles.isEmpty) {
      return Column(
        children: [
          const Expanded(child: SizedBox.shrink()),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'لا توجد نتائج مطابقة',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: RafiqThemeScope.of(context).textDim,
              ),
            ),
          ),
        ],
      );
    }
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 6,
      mainAxisSpacing: 14,
      mainAxisExtent: 95,
      padding: EdgeInsets.zero,
      children: tiles,
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: palette.surface.withValues(alpha: 0.75),
        border: Border.all(color: palette.borderSoft),
      ),
      child: Row(
        children: [
          RafiqIcon(RafiqIcons.search, size: 17, color: palette.goldMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              maxLines: 1,
              textInputAction: TextInputAction.search,
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
                hintText: 'ابحث عن تطبيق',
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
}

class _InstalledAppTile extends StatelessWidget {
  const _InstalledAppTile({required this.app, required this.onTap});

  final InstalledApp app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AppIconImage(icon: app.icon, label: app.label, iconSize: 58),
            const SizedBox(height: 7),
            Text(
              app.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: palette.textSecondary),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _LoadingArcPainter(
                    rotation: _controller.value * 2 * math.pi,
                    track: palette.border,
                    accent: palette.gold,
                  ),
                );
              },
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
      ),
    );
  }
}

class _LoadingArcPainter extends CustomPainter {
  const _LoadingArcPainter({
    required this.rotation,
    required this.track,
    required this.accent,
  });

  final double rotation;
  final Color track;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 2;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = accent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      rotation,
      math.pi * 2 / 3,
      false,
      arcPaint,
    );
    canvas.drawCircle(
      center,
      3,
      Paint()..color = accent.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _LoadingArcPainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
      oldDelegate.track != track ||
      oldDelegate.accent != accent;
}

class _ErrorOrnament extends StatelessWidget {
  const _ErrorOrnament({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.surface.withValues(alpha: 0.7),
                border: Border.all(color: palette.border),
              ),
              child: Center(
                child: RafiqIcon(
                  RafiqIcons.info,
                  size: 34,
                  color: palette.gold,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'تعذّر إكمال الطلب',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: 18),
            _RafiqSecondaryButton(
              text: 'إعادة المحاولة',
              icon: RafiqIcons.refresh,
              onTap: onRetry,
            ),
          ],
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
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                RafiqIcon(icon!, size: 18, color: palette.gold),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: palette.gold,
                  fontWeight: FontWeight.w500,
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
        margin: const EdgeInsets.symmetric(horizontal: 24),
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

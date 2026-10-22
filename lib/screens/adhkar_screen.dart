import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/repositories.dart';
import '../state/adhkar_state.dart';
import '../state/app_state.dart';
import '../theme/rafiq_theme.dart';
import '../theme/typography.dart';
import '../widgets/components.dart';
import '../widgets/rafiq_icons.dart';
import '../widgets/top_bar.dart';

class AdhkarScreen extends StatefulWidget {
  const AdhkarScreen({super.key});

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  final AdhkarState _state = AdhkarState();
  int _quickTab = 0;

  @override
  void initState() {
    super.initState();
    _state.load();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  void _click() {
    AppScope.read(context).click();
  }

  void _openSources() {
    final palette = RafiqThemeScope.of(context);
    final source =
        _state.data?.source ??
        'أذكار الصباح والمساء من حصن المسلم ومصادر موثقة.';
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: const RoundedRectangleBorder(),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.surfaceHigh, palette.backgroundSecondary],
              ),
              border: Border.all(color: palette.border),
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'مصادر الأذكار',
                        style: Theme.of(
                          dialogContext,
                        ).textTheme.titleLarge?.copyWith(color: palette.gold),
                      ),
                    ),
                    RoundIconButton(
                      icon: RafiqIcons.close,
                      size: 34,
                      onTap: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  source,
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _state,
        builder: (context, _) {
          final category = _state.selectedCategory;
          if (category != null) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop) {
                  _state.closeCategory();
                }
              },
              child: _AdhkarReader(
                category: category,
                completed: _state.completedIn(category),
                countFor: _state.countFor,
                onIncrement: (item) {
                  _click();
                  _state.increment(item);
                },
                onResetItem: (item) {
                  _click();
                  _state.resetItem(item);
                },
                onResetCategory: () {
                  _click();
                  _state.resetCategory(category);
                },
                onBack: () {
                  _click();
                  _state.closeCategory();
                },
              ),
            );
          }
          return _AdhkarBrowser(
            isLoading: _state.isLoading,
            error: _state.error,
            categories: _state.categories,
            quickTab: _quickTab,
            onQuickTab: (index) {
              setState(() => _quickTab = index);
              _click();
              _state.openCategory(index == 0 ? 'morning' : 'evening');
            },
            onOpenCategory: (id) {
              _click();
              _state.openCategory(id);
            },
            onRetry: () {
              _click();
              _state.retry();
            },
            onShowSources: () {
              _click();
              _openSources();
            },
          );
        },
      ),
    );
  }
}

class _AdhkarBrowser extends StatelessWidget {
  const _AdhkarBrowser({
    required this.isLoading,
    required this.error,
    required this.categories,
    required this.quickTab,
    required this.onQuickTab,
    required this.onOpenCategory,
    required this.onRetry,
    required this.onShowSources,
  });

  final bool isLoading;
  final String? error;
  final List<AdhkarCategory> categories;
  final int quickTab;
  final ValueChanged<int> onQuickTab;
  final ValueChanged<String> onOpenCategory;
  final VoidCallback onRetry;
  final VoidCallback onShowSources;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RafiqTopBar(
          title: 'الأذكار',
          subtitle: 'حصّن يومك بذكر الله',
          actions: [
            RoundIconButton(
              icon: RafiqIcons.info,
              size: 38,
              onTap: onShowSources,
            ),
          ],
        ),
        if (isLoading)
          const Expanded(child: _LoadingOrnament(label: 'جارٍ تحميل الأذكار'))
        else if (error != null)
          Expanded(
            child: _ErrorOrnament(message: error!, onRetry: onRetry),
          )
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedPill(
                    options: const ['أذكار الصباح', 'أذكار المساء'],
                    selectedIndex: quickTab,
                    onSelected: onQuickTab,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: categories.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return _CategoryCard(
                          category: category,
                          onTap: () => onOpenCategory(category.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final AdhkarCategory category;
  final VoidCallback onTap;

  RafiqIconData get _icon {
    switch (category.icon) {
      case 'sun':
        return RafiqIcons.sun;
      case 'moon':
        return RafiqIcons.moon;
      case 'bed':
        return RafiqIcons.bed;
      default:
        return RafiqIcons.sparkle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return RafiqCard(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: palette.surfaceHigh.withValues(alpha: 0.85),
              border: Border.all(color: palette.border),
            ),
            child: Center(
              child: RafiqIcon(_icon, size: 22, color: palette.gold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: palette.textPrimary),
                ),
                Text(
                  category.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.textDim),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${category.items.length}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: palette.gold),
              ),
              Text(
                'ذكرًا',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: palette.textDim),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdhkarReader extends StatelessWidget {
  const _AdhkarReader({
    required this.category,
    required this.completed,
    required this.countFor,
    required this.onIncrement,
    required this.onResetItem,
    required this.onResetCategory,
    required this.onBack,
  });

  final AdhkarCategory category;
  final int completed;
  final int Function(AdhkarItem item) countFor;
  final ValueChanged<AdhkarItem> onIncrement;
  final ValueChanged<AdhkarItem> onResetItem;
  final VoidCallback onResetCategory;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RafiqTopBar(
          title: category.title,
          subtitle: 'أتممت $completed من ${category.items.length}',
          onBack: onBack,
          actions: [
            RoundIconButton(
              icon: RafiqIcons.refresh,
              size: 38,
              onTap: onResetCategory,
            ),
          ],
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            itemCount: category.items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = category.items[index];
              return _DhikrCard(
                item: item,
                current: countFor(item).clamp(0, item.count),
                onIncrement: () => onIncrement(item),
                onReset: () => onResetItem(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DhikrCard extends StatelessWidget {
  const _DhikrCard({
    required this.item,
    required this.current,
    required this.onIncrement,
    required this.onReset,
  });

  final AdhkarItem item;
  final int current;
  final VoidCallback onIncrement;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final done = current >= item.count;
    return _AdhkarCard(
      onTap: onIncrement,
      contentPadding: const EdgeInsets.all(16),
      borderColor: done
          ? palette.gold.withValues(alpha: 0.55)
          : palette.borderSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.title != null) ...[
            Text(
              item.title!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: palette.goldMuted),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            item.text,
            textAlign: TextAlign.center,
            style: RafiqText.quranSmall.copyWith(
              fontSize: 20,
              height: 38 / 20,
              color: palette.textPrimary,
            ),
          ),
          if (item.benefit.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.benefit,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.mint,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Material(
                color: done
                    ? palette.gold.withValues(alpha: 0.16)
                    : palette.surfaceHigh,
                shape: CircleBorder(
                  side: BorderSide(
                    color: done ? palette.gold : palette.borderSoft,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onIncrement,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: Center(
                      child: Text(
                        '$current/${item.count}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: done
                              ? palette.goldBright
                              : palette.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.countText.isNotEmpty)
                      Text(
                        item.countText,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textDim,
                        ),
                      ),
                    Text(
                      item.source,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: palette.textDim),
                    ),
                  ],
                ),
              ),
              RoundIconButton(
                icon: RafiqIcons.refresh,
                size: 34,
                tint: palette.textDim,
                onTap: onReset,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdhkarCard extends StatelessWidget {
  const _AdhkarCard({
    required this.child,
    this.contentPadding = const EdgeInsets.all(18),
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets contentPadding;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final radius = BorderRadius.circular(22);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.surfaceHigh.withValues(alpha: 0.92),
            palette.surface.withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(color: borderColor ?? palette.borderSoft),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(padding: contentPadding, child: child),
        ),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
    return _EmptyState(
      icon: RafiqIcons.info,
      title: 'تعذّر إكمال الطلب',
      body: message,
      action: _RafiqSecondaryButton(
        text: 'إعادة المحاولة',
        icon: RafiqIcons.refresh,
        onTap: onRetry,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final RafiqIconData icon;
  final String title;
  final String body;
  final Widget? action;

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
                child: RafiqIcon(icon, size: 34, color: palette.gold),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
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

import 'package:flutter/material.dart';

import '../data/repositories.dart';
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
  final _repository = AdhkarRepository();
  AdhkarData? _data;
  AdhkarCategory? _selected;
  final Map<String, int> _progress = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repository.load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _openCategory(String id) {
    final data = _data;
    if (data == null) return;
    for (final category in data.categories) {
      if (category.id == id) {
        setState(() => _selected = category);
        return;
      }
    }
  }

  void _increment(AdhkarItem item) {
    setState(() {
      final current = _progress[item.id] ?? 0;
      _progress[item.id] = current >= item.count ? 0 : current + 1;
    });
  }

  void _resetItem(AdhkarItem item) {
    setState(() => _progress.remove(item.id));
  }

  void _resetCategory(AdhkarCategory category) {
    setState(() {
      for (final item in category.items) {
        _progress.remove(item.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final category = _selected;
    if (category != null) {
      final completed = category.items
          .where((item) => (_progress[item.id] ?? 0) >= item.count)
          .length;
      return Container(
        color: Colors.transparent,
        child: Column(
          children: [
            RafiqTopBar(
              title: category.title,
              subtitle: 'أتممت $completed من ${category.items.length}',
              onBack: () => setState(() => _selected = null),
              actions: [
                RoundIconButton(
                  icon: RafiqIcons.refresh,
                  size: 38,
                  onTap: () => _resetCategory(category),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                itemCount: category.items.length,
                itemBuilder: (context, index) {
                  final item = category.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DhikrCard(
                      item: item,
                      current: (_progress[item.id] ?? 0).clamp(0, item.count),
                      onIncrement: () => _increment(item),
                      onReset: () => _resetItem(item),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          RafiqTopBar(
            title: 'الأذكار',
            subtitle: 'حصّن يومك بذكر الله',
            actions: [
              RoundIconButton(
                icon: RafiqIcons.info,
                size: 38,
                onTap: () => _showSources(context),
              ),
            ],
          ),
          if (_loading)
            Expanded(
              child: Center(
                child: Text(
                  'جارٍ تحميل الأذكار',
                  style: TextStyle(color: palette.textSecondary, fontFamily: 'Tajawal'),
                ),
              ),
            )
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    SegmentedPill(
                      options: const ['أذكار الصباح', 'أذكار المساء'],
                      selectedIndex: 0,
                      onSelected: (index) => _openCategory(index == 0 ? 'morning' : 'evening'),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: _data?.categories.length ?? 0,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _data!.categories[index];
                          return _CategoryCard(
                            category: item,
                            onTap: () => _openCategory(item.id),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showSources(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: palette.borderSoft),
        ),
        title: Text(
          'مصادر الأذكار',
          style: TextStyle(color: palette.gold, fontFamily: 'Tajawal', fontWeight: FontWeight.w700),
        ),
        content: Text(
          _data?.source ?? 'أذكار الصباح والمساء من حصن المسلم ومصادر موثقة.',
          style: TextStyle(color: palette.textSecondary, fontFamily: 'Tajawal', fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إغلاق', style: TextStyle(color: palette.gold)),
          ),
        ],
      ),
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
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: palette.textPrimary),
                ),
                Text(
                  category.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: palette.textDim),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${category.items.length}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: palette.gold),
              ),
              Text(
                'ذكرًا',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: palette.textDim),
              ),
            ],
          ),
        ],
      ),
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
    return RafiqCard(
      onTap: onIncrement,
      contentPadding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.title != null) ...[
            Text(
              item.title!,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: palette.goldMuted),
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
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: Center(
                      child: Text(
                        '$current/${item.count}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: done ? palette.goldBright : palette.textSecondary,
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
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: palette.textDim),
                      ),
                    Text(
                      item.source,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: palette.textDim),
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

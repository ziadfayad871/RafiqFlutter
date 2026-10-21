import 'package:flutter/material.dart';

import '../data/repositories.dart';
import '../theme/rafiq_theme.dart';
import '../theme/typography.dart';
import '../widgets/components.dart';
import '../widgets/rafiq_icons.dart';
import '../widgets/top_bar.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final _repository = QuranRepository();
  QuranData? _data;
  int _surahNumber = 1;
  int _mode = 0;
  bool _loading = true;
  String? _error;

  QuranSurah? get _surah {
    final data = _data;
    if (data == null) return null;
    for (final surah in data.surahs) {
      if (surah.number == _surahNumber) return surah;
    }
    return null;
  }

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
      setState(() {
        _error = 'تعذر تحميل المصحف';
        _loading = false;
      });
    }
  }

  void _openIndex() {
    final data = _data;
    if (data == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SurahIndexSheet(
        surahs: data.surahs,
        selected: _surahNumber,
        onSelect: (number) {
          setState(() => _surahNumber = number);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _openSources() {
    final data = _data;
    showDialog<void>(
      context: context,
      builder: (context) {
        final palette = RafiqThemeScope.of(context);
        return AlertDialog(
          backgroundColor: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: palette.borderSoft),
          ),
          title: Text(
            'مصادر المصحف',
            style: TextStyle(color: palette.gold, fontFamily: 'Tajawal', fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data?.source ?? '',
                style: TextStyle(color: palette.textSecondary, fontFamily: 'Tajawal', fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 10),
              Text(
                data?.translationSource ?? '',
                style: TextStyle(color: palette.textSecondary, fontFamily: 'Tajawal', fontSize: 14, height: 1.6),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إغلاق', style: TextStyle(color: palette.gold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final surah = _surah;
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          RafiqTopBar(
            title: 'القرآن الكريم',
            subtitle: surah == null ? null : '${surah.name} • ${surah.revelation}',
            actions: [
              RoundIconButton(
                icon: RafiqIcons.menuLines,
                size: 38,
                onTap: _openIndex,
              ),
              RoundIconButton(
                icon: RafiqIcons.bookmark,
                size: 38,
                onTap: () {},
              ),
              RoundIconButton(
                icon: RafiqIcons.info,
                size: 38,
                onTap: _openSources,
              ),
            ],
          ),
          if (_loading)
            Expanded(
              child: Center(
                child: Text(
                  'جارٍ فتح المصحف',
                  style: TextStyle(color: palette.textSecondary, fontFamily: 'Tajawal'),
                ),
              ),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Text(
                  _error!,
                  style: TextStyle(color: palette.danger, fontFamily: 'Tajawal'),
                ),
              ),
            )
          else if (surah != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SegmentedPill(
                      options: const ['المصحف', 'الترجمة'],
                      selectedIndex: _mode,
                      onSelected: (index) => setState(() => _mode = index),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        Text(
                          'سورة ${surah.name}',
                          style: RafiqText.ornamentTitle.copyWith(color: palette.gold),
                        ),
                        Text(
                          '${surah.versesCount} آية • ${surah.revelation}',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: palette.textDim),
                        ),
                        if (surah.bismillahBefore && surah.number != 9) ...[
                          const SizedBox(height: 6),
                          Text(
                            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                            style: RafiqText.quranSmall.copyWith(color: palette.goldMuted),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    const OrnamentalDivider(),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: surah.verses.length,
                        itemBuilder: (context, index) {
                          final verse = surah.verses[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: _AyahRow(
                              number: verse.number,
                              text: verse.text,
                              translation: _mode == 1 ? verse.translation : null,
                            ),
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
}

class _AyahRow extends StatelessWidget {
  const _AyahRow({required this.number, required this.text, this.translation});

  final int number;
  final String text;
  final String? translation;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text,
            textAlign: TextAlign.justify,
            style: RafiqText.quran.copyWith(color: palette.textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.borderSoft),
                ),
                child: Text(
                  '$number',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: palette.goldMuted),
                ),
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                icon: RafiqIcons.play,
                size: 32,
                onTap: () {},
              ),
              const SizedBox(width: 6),
              RoundIconButton(
                icon: RafiqIcons.bookmark,
                size: 32,
                tint: palette.goldMuted,
                onTap: () {},
              ),
            ],
          ),
          if (translation != null) ...[
            const SizedBox(height: 8),
            Text(
              translation!,
              textAlign: TextAlign.start,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: palette.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _SurahIndexSheet extends StatelessWidget {
  const _SurahIndexSheet({required this.surahs, required this.selected, required this.onSelect});

  final List<QuranSurah> surahs;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: palette.borderSoft),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'فهرس السور',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: palette.gold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: surahs.length,
                itemBuilder: (context, index) {
                  final surah = surahs[index];
                  final isSelected = surah.number == selected;
                  return InkWell(
                    onTap: () => onSelect(surah.number),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      color: isSelected
                          ? palette.surfaceHigh.withValues(alpha: 0.6)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.borderSoft),
                            ),
                            child: Text(
                              '${surah.number}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: palette.goldMuted),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              surah.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: palette.textPrimary),
                            ),
                          ),
                          Text(
                            '${surah.versesCount} آية',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: palette.textDim),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            surah.revelation,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: palette.goldMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

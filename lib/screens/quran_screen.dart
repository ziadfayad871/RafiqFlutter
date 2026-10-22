import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repositories.dart';
import '../state/app_state.dart';
import '../state/quran_state.dart';
import '../theme/palette.dart';
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
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = <int, GlobalKey>{};

  QuranState? _state;
  Timer? _messageTimer;
  String? _visibleMessage;
  int? _pendingScrollAyah;
  int? _pendingScrollSurah;

  List<double>? _cachedOffsets;
  int _cachedSurah = -1;
  bool _cachedTranslation = false;
  double _cachedWidth = -1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state != null) return;
    final appState = AppScope.of(context);
    final state = QuranState(
      preferencesRepository: appState.preferencesRepository,
    )..init();
    _state = state;
    state.addListener(_handleStateChanged);
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    final state = _state;
    if (state != null) {
      state.removeListener(_handleStateChanged);
      state.dispose();
    }
    super.dispose();
  }

  void _handleStateChanged() {
    if (!mounted) return;
    final state = _state;
    if (state == null) return;
    _syncTransientMessage(state);
    final request = state.scrollRequest;
    if (request != null) {
      if (_pendingScrollAyah != request ||
          _pendingScrollSurah != state.surahNumber) {
        _pendingScrollAyah = request;
        _pendingScrollSurah = state.surahNumber;
        _scheduleScrollTo(state.surahNumber, request);
      }
      _pendingScrollAyah = null;
      _pendingScrollSurah = null;
      state.consumeScrollRequest();
    }
    setState(() {});
  }

  void _syncTransientMessage(QuranState state) {
    final text = state.message ?? state.audioMessage;
    if (text == _visibleMessage) return;
    _visibleMessage = text;
    _messageTimer?.cancel();
    if (text == null) return;
    _messageTimer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      _visibleMessage = null;
      state.consumeMessages();
      setState(() {});
    });
  }

  double _contentWidth() {
    return MediaQuery.sizeOf(context).width - 32 - 24;
  }

  List<double> _offsetsFor(QuranSurah surah) {
    final width = _contentWidth();
    final translation = _state?.showTranslation ?? false;
    if (_cachedOffsets != null &&
        _cachedSurah == surah.number &&
        _cachedTranslation == translation &&
        _cachedWidth == width) {
      return _cachedOffsets!;
    }
    final palette = RafiqThemeScope.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final offsets = <double>[];
    var cursor = 0.0;
    for (final verse in surah.verses) {
      offsets.add(cursor);
      cursor += _measureVerseHeight(verse, width, translation, palette, scaler);
    }
    _cachedOffsets = offsets;
    _cachedSurah = surah.number;
    _cachedTranslation = translation;
    _cachedWidth = width;
    return offsets;
  }

  double _measureVerseHeight(
    QuranVerse verse,
    double width,
    bool showTranslation,
    RafiqPalette palette,
    TextScaler scaler,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: verse.text,
        style: RafiqText.quran.copyWith(color: palette.textPrimary),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      textScaler: scaler,
    )..layout(maxWidth: width);
    var height = 20.0 + textPainter.height + 8 + 32;
    if (showTranslation && verse.translation.isNotEmpty) {
      final translationPainter = TextPainter(
        text: TextSpan(
          text: verse.translation,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.start,
        textScaler: scaler,
      )..layout(maxWidth: width);
      height += 8 + translationPainter.height;
    }
    return height + 4;
  }

  int _indexAt(List<double> offsets, double pixels) {
    if (offsets.isEmpty) return -1;
    var low = 0;
    var high = offsets.length - 1;
    var result = 0;
    while (low <= high) {
      final middle = (low + high) ~/ 2;
      if (offsets[middle] <= pixels) {
        result = middle;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    return result;
  }

  void _handleScroll() {
    final state = _state;
    if (state == null) return;
    if (!_scrollController.hasClients) return;
    final surah = state.surah;
    if (surah == null || surah.verses.isEmpty) return;
    final offsets = _offsetsFor(surah);
    final index = _indexAt(offsets, _scrollController.position.pixels);
    if (index < 0 || index >= surah.verses.length) return;
    state.onAyahVisible(surah.number, surah.verses[index].number);
  }

  void _scheduleScrollTo(int surahNumber, int ayah) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToAyah(surahNumber, ayah, 0);
    });
  }

  void _scrollToAyah(int surahNumber, int ayah, int attempt) {
    if (!mounted) return;
    final state = _state;
    final surah = state?.surah;
    if (surah == null || surah.number != surahNumber) return;
    if (!_scrollController.hasClients) {
      if (attempt < 6) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToAyah(surahNumber, ayah, attempt + 1);
        });
      }
      return;
    }
    final index = surah.verses.indexWhere((verse) => verse.number == ayah);
    if (index < 0) return;
    final offsets = _offsetsFor(surah);
    final position = _scrollController.position;
    final target = offsets[index].clamp(0.0, position.maxScrollExtent);
    if ((position.pixels - target).abs() > 0.5) {
      position.jumpTo(target);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _verseKeys[ayah]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          alignment: 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else if (attempt < 6) {
        _scrollToAyah(surahNumber, ayah, attempt + 1);
      }
    });
  }

  void _openIndexSheet() {
    final state = _state;
    if (state == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (sheetContext) => _QuranSheet(
        builder: (available) => _IndexSheet(
          surahs: state.surahs,
          selected: state.surahNumber,
          availableHeight: available,
          onSelect: (number) {
            state.selectSurah(number);
            Navigator.of(sheetContext).pop();
          },
        ),
      ),
    );
  }

  void _openBookmarksSheet() {
    final state = _state;
    if (state == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (sheetContext) => _QuranSheet(
        builder: (available) => _BookmarksSheet(
          bookmarks: state.bookmarks,
          availableHeight: available,
          onOpen: (bookmark) {
            state.openBookmark(bookmark);
            Navigator.of(sheetContext).pop();
          },
          onDelete: (bookmark) {
            unawaited(state.deleteBookmark(bookmark));
          },
        ),
      ),
    );
  }

  void _openSourcesDialog() {
    final state = _state;
    if (state == null) return;
    final data = state.data;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _SourcesDialog(
        source: data?.source ?? '',
        translationSource: data?.translationSource ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state == null) {
      return const SizedBox.shrink();
    }
    final palette = RafiqThemeScope.of(context);
    final surah = state.surah;
    final message = _visibleMessage;
    return Container(
      color: Colors.transparent,
      child: Stack(
        children: [
          Column(
            children: [
              RafiqTopBar(
                title: 'القرآن الكريم',
                subtitle: surah == null
                    ? null
                    : '${surah.name} • ${surah.revelation}',
                actions: [
                  RoundIconButton(
                    icon: RafiqIcons.menuLines,
                    size: 38,
                    onTap: _openIndexSheet,
                  ),
                  RoundIconButton(
                    icon: RafiqIcons.bookmark,
                    size: 38,
                    onTap: _openBookmarksSheet,
                  ),
                  RoundIconButton(
                    icon: RafiqIcons.info,
                    size: 38,
                    onTap: _openSourcesDialog,
                  ),
                ],
              ),
              if (state.isLoading)
                const _LoadingOrnament(label: 'جارٍ فتح المصحف')
              else if (state.error != null)
                _ErrorOrnament(message: state.error!, onRetry: state.retry)
              else if (surah != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SegmentedPill(
                          options: const ['المصحف', 'الترجمة'],
                          selectedIndex: state.mode,
                          onSelected: state.setMode,
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: [
                            Text(
                              'سورة ${surah.name}',
                              style: RafiqText.ornamentTitle.copyWith(
                                color: palette.gold,
                              ),
                            ),
                            Text(
                              '${surah.versesCount} آية • ${surah.revelation}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: palette.textDim),
                            ),
                            if (surah.bismillahBefore && surah.number != 9) ...[
                              const SizedBox(height: 6),
                              Text(
                                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                                style: RafiqText.quranSmall.copyWith(
                                  color: palette.goldMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        const OrnamentalDivider(),
                        const SizedBox(height: 6),
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: surah.verses.length,
                            itemBuilder: (context, index) {
                              final verse = surah.verses[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: _AyahRow(
                                  key: _verseKeys.putIfAbsent(
                                    verse.number,
                                    GlobalKey.new,
                                  ),
                                  number: verse.number,
                                  text: verse.text,
                                  translation: state.showTranslation
                                      ? verse.translation
                                      : null,
                                  isBookmarked: state.isBookmarked(
                                    surah.number,
                                    verse.number,
                                  ),
                                  isPlaying:
                                      state.playingAyah == verse.number &&
                                      state.audioPhase != QuranAudioPhase.idle,
                                  onBookmark: () {
                                    unawaited(
                                      state.toggleBookmark(
                                        surah.number,
                                        verse.number,
                                      ),
                                    );
                                  },
                                  onPlay: () {
                                    unawaited(state.playAyah(verse.number));
                                  },
                                  onSelect: () {
                                    state.onAyahVisible(
                                      surah.number,
                                      verse.number,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        _AudioBar(
                          statusText: state.audioStatusText,
                          isPlaying:
                              state.audioPhase == QuranAudioPhase.playing,
                          onToggle: () {
                            unawaited(state.togglePlayPause());
                          },
                          onNext: () {
                            unawaited(state.skipNext());
                          },
                          onPrevious: () {
                            unawaited(state.skipPrevious());
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (message != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 110,
              child: _TransientMessage(message: message),
            ),
        ],
      ),
    );
  }
}

class _AyahRow extends StatelessWidget {
  const _AyahRow({
    super.key,
    required this.number,
    required this.text,
    required this.translation,
    required this.isBookmarked,
    required this.isPlaying,
    required this.onBookmark,
    required this.onPlay,
    required this.onSelect,
  });

  final int number;
  final String text;
  final String? translation;
  final bool isBookmarked;
  final bool isPlaying;
  final VoidCallback onBookmark;
  final VoidCallback onPlay;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Material(
      color: isPlaying
          ? palette.surfaceHigh.withValues(alpha: 0.55)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelect,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.goldMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        RoundIconButton(
                          icon: RafiqIcons.play,
                          size: 32,
                          onTap: onPlay,
                        ),
                        const SizedBox(width: 6),
                        RoundIconButton(
                          icon: isBookmarked
                              ? RafiqIcons.bookmarkFilled
                              : RafiqIcons.bookmark,
                          size: 32,
                          tint: isBookmarked
                              ? palette.goldBright
                              : palette.goldMuted,
                          onTap: onBookmark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (translation != null) ...[
                const SizedBox(height: 8),
                Text(
                  translation!,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioBar extends StatelessWidget {
  const _AudioBar({
    required this.statusText,
    required this.isPlaying,
    required this.onToggle,
    required this.onNext,
    required this.onPrevious,
  });

  final String statusText;
  final bool isPlaying;
  final VoidCallback onToggle;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Column(
      children: [
        OrnamentalDivider(color: palette.borderSoft),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تلاوة الشيخ مشاري العفاسي',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      statusText,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: palette.textDim),
                    ),
                  ],
                ),
              ),
              RoundIconButton(
                icon: RafiqIcons.previous,
                size: 38,
                onTap: onPrevious,
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                icon: isPlaying ? RafiqIcons.pause : RafiqIcons.play,
                size: 46,
                filled: true,
                onTap: onToggle,
              ),
              const SizedBox(width: 8),
              RoundIconButton(icon: RafiqIcons.next, size: 38, onTap: onNext),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuranSheet extends StatelessWidget {
  const _QuranSheet({required this.builder});

  final Widget Function(double availableHeight) builder;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.backgroundSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = MediaQuery.sizeOf(context).height;
            final maxHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : screenHeight;
            final available = maxHeight - 110;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 3,
                  margin: const EdgeInsets.only(top: 12, bottom: 6),
                  decoration: BoxDecoration(
                    color: palette.gold.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: builder(available),
                ),
                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IndexSheet extends StatelessWidget {
  const _IndexSheet({
    required this.surahs,
    required this.selected,
    required this.onSelect,
    required this.availableHeight,
  });

  final List<QuranSurah> surahs;
  final int selected;
  final ValueChanged<int> onSelect;
  final double availableHeight;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final listHeight = availableHeight < 430 ? availableHeight : 430.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'فهرس السور',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: palette.gold),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: listHeight,
          child: ListView.builder(
            itemCount: surahs.length,
            itemBuilder: (context, index) {
              final surah = surahs[index];
              final isSelected = surah.number == selected;
              return InkWell(
                onTap: () => onSelect(surah.number),
                borderRadius: BorderRadius.circular(14),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isSelected
                        ? palette.surfaceHigh.withValues(alpha: 0.9)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.surfaceHigh,
                          border: Border.all(color: palette.borderSoft),
                        ),
                        child: Text(
                          '${surah.number}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: isSelected
                                    ? palette.gold
                                    : palette.textSecondary,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          surah.name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: isSelected
                                    ? palette.gold
                                    : palette.textPrimary,
                              ),
                        ),
                      ),
                      Text(
                        '${surah.versesCount} آية',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textDim,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        surah.revelation,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BookmarksSheet extends StatelessWidget {
  const _BookmarksSheet({
    required this.bookmarks,
    required this.onOpen,
    required this.onDelete,
    required this.availableHeight,
  });

  final List<QuranBookmark> bookmarks;
  final ValueChanged<QuranBookmark> onOpen;
  final ValueChanged<QuranBookmark> onDelete;
  final double availableHeight;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final listHeight = availableHeight < 420 ? availableHeight : 420.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'علاماتي المرجعية',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: palette.gold),
        ),
        const SizedBox(height: 10),
        if (bookmarks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'لم تحفظ أي علامة بعد. اضغط على أيقونة العلامة بجانب الآية لحفظها هنا.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
            ),
          )
        else
          SizedBox(
            height: listHeight,
            child: ListView.builder(
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = bookmarks[index];
                return InkWell(
                  onTap: () => onOpen(bookmark),
                  borderRadius: BorderRadius.circular(14),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${bookmark.surahName} • الآية ${bookmark.ayahNumber}',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(color: palette.gold),
                              ),
                              Text(
                                bookmark.snippet,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: RafiqText.quranSmall.copyWith(
                                  fontSize: 17,
                                  height: 30 / 17,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        RoundIconButton(
                          icon: RafiqIcons.trash,
                          size: 34,
                          onTap: () => onDelete(bookmark),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SourcesDialog extends StatelessWidget {
  const _SourcesDialog({required this.source, required this.translationSource});

  final String source;
  final String translationSource;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
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
                    'مصادر النص',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: palette.gold),
                  ),
                ),
                RoundIconButton(
                  icon: RafiqIcons.close,
                  size: 34,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'النص القرآني: النص العثماني الموثق عبر Quran.com API.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'الترجمة: Saheeh International، وتظهر عند اختيار تبويب الترجمة.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'التلاوة: الشيخ مشاري العفاسي — everyayah.com.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
            ),
            if (source.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                source,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: palette.textDim),
              ),
            ],
            if (translationSource.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                translationSource,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: palette.textDim),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TransientMessage extends StatelessWidget {
  const _TransientMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
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
    );
  }
}

class _LoadingOrnament extends StatelessWidget {
  const _LoadingOrnament({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: palette.gold,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorOrnament extends StatelessWidget {
  const _ErrorOrnament({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 82,
            height: 82,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surface.withValues(alpha: 0.7),
              border: Border.all(color: palette.border),
            ),
            child: RafiqIcon(RafiqIcons.info, size: 34, color: palette.gold),
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
          _SecondaryButton(
            text: 'إعادة المحاولة',
            icon: RafiqIcons.refresh,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final RafiqIconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Material(
      color: palette.surfaceHigh.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
            children: [
              RafiqIcon(icon, size: 18, color: palette.gold),
              const SizedBox(width: 8),
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

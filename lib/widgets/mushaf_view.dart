import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/mushaf.dart';
import '../data/repositories.dart';
import '../theme/palette.dart';
import '../theme/rafiq_theme.dart';

const _paper = Color(0xFFF8F2E3);
const _paperDeep = Color(0xFFEFE6D0);
const _ink = Color(0xFF14382B);
const _inkSoft = Color(0xFF33604A);
const _frame = Color(0xFF2E5D46);
const _goldAccent = Color(0xFFAE7C2D);
const _badgeRing = Color(0xFF2E5D46);
const _badgeWell = Color(0xFFEFE7D2);
const _bismillah = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

const int mushafTotalPages = 604;
const int mushafSpreadCount = 302;

String _arabicDigits(int value) {
  final builder = StringBuffer();
  for (final ch in value.toString().split('')) {
    final code = ch.codeUnitAt(0);
    if (code >= 0x30 && code <= 0x39) {
      builder.writeCharCode(0x0660 + code - 0x30);
    } else {
      builder.write(ch);
    }
  }
  return builder.toString();
}

class MushafReader extends StatefulWidget {
  const MushafReader({
    super.key,
    required this.surahs,
    required this.startSurah,
    required this.startAyah,
    required this.bookmarks,
    required this.playingSurah,
    required this.playingAyah,
    required this.onPosition,
    required this.onPlayFrom,
    required this.onBookmark,
  });

  final List<QuranSurah> surahs;
  final int startSurah;
  final int startAyah;
  final Set<MushafAyahRef> bookmarks;
  final int playingSurah;
  final int? playingAyah;
  final void Function(int surah, int ayah) onPosition;
  final void Function(int surah, int ayah) onPlayFrom;
  final void Function(int surah, int ayah) onBookmark;

  @override
  State<MushafReader> createState() => MushafReaderState();
}

class MushafReaderState extends State<MushafReader> {
  MushafData? _mushaf;
  bool _failed = false;
  PageController? _controller;
  int _page = 1;
  MushafAyahRef? _selected;
  MushafAyahRef? _anchor;

  @override
  void initState() {
    super.initState();
    MushafData.load()
        .then((data) {
          if (!mounted) return;
          final initial =
              data.pageOf(widget.startSurah, widget.startAyah).clamp(1, mushafTotalPages);
          setState(() {
            _mushaf = data;
            _page = initial;
            _controller = PageController(initialPage: (initial - 1) ~/ 2);
          });
        })
        .catchError((Object error) {
          if (!mounted) return;
          setState(() => _failed = true);
        });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void jumpToAyah(int surah, int ayah) {
    final mushaf = _mushaf;
    final controller = _controller;
    if (mushaf == null || controller == null || !controller.hasClients) return;
    final page = mushaf.pageOf(surah, ayah).clamp(1, mushafTotalPages);
    final spread = (page - 1) ~/ 2;
    setState(() {
      _anchor = MushafAyahRef(surah, ayah);
      _selected = null;
      _page = page;
    });
    final current = controller.page?.round() ?? spread;
    if (current != spread) {
      controller.animateToPage(
        spread,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handleSpreadChanged(int spreadIndex) {
    final mushaf = _mushaf;
    if (mushaf == null) return;
    final leftPage = (spreadIndex * 2 + 2).clamp(1, mushafTotalPages);
    final forwardmost = mushaf.lastAyahOf(leftPage);
    setState(() {
      _page = leftPage;
      _selected = null;
      _anchor = null;
    });
    widget.onPosition(forwardmost.surah, forwardmost.ayah);
  }

  void _goSpread(int delta) {
    final controller = _controller;
    if (controller == null || !controller.hasClients) return;
    final current = controller.page?.round() ?? 0;
    final target = (current + delta).clamp(0, mushafSpreadCount - 1);
    if (target == current) return;
    controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final mushaf = _mushaf;
    if (mushaf == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_failed)
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                'تعذّر تجهيز صفحات المصحف',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: palette.textPrimary),
              ),
          ],
        ),
      );
    }
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
                child: PageView.builder(
                  reverse: true,
                  physics: const PageScrollPhysics(),
                  controller: _controller,
                  onPageChanged: _handleSpreadChanged,
                  itemCount: mushafSpreadCount,
                  itemBuilder: (context, spreadIndex) {
                    return _SpreadView(
                      spreadIndex: spreadIndex,
                      mushaf: mushaf,
                      surahs: widget.surahs,
                      selected: _selected,
                      anchor: _anchor,
                      bookmarks: widget.bookmarks,
                      playingSurah: widget.playingSurah,
                      playingAyah: widget.playingAyah,
                      onSelect: (ref) {
                        setState(() {
                          _selected = _selected == ref ? null : ref;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            _PageIndicator(
              page: _page,
              totalPages: mushafTotalPages,
              color: palette.textDim,
              onBack: () => _goSpread(-1),
              onForward: () => _goSpread(1),
            ),
            const SizedBox(height: 4),
          ],
        ),
        if (_selected != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 40,
            child: _AyahActionSheet(
              ref: _selected!,
              surahs: widget.surahs,
              palette: palette,
              isBookmarked: widget.bookmarks.contains(_selected!),
              onPlay: () {
                final ref = _selected!;
                setState(() => _selected = null);
                widget.onPlayFrom(ref.surah, ref.ayah);
              },
              onBookmark: () {
                final ref = _selected!;
                setState(() => _selected = null);
                widget.onBookmark(ref.surah, ref.ayah);
              },
              onClose: () => setState(() => _selected = null),
            ),
          ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.page,
    required this.totalPages,
    required this.color,
    required this.onBack,
    required this.onForward,
  });

  final int page;
  final int totalPages;
  final Color color;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NudgeButton(
          icon: Icons.chevron_right,
          onTap: onBack,
        ),
        Text(
          '${_arabicDigits(page)} من ${_arabicDigits(totalPages)}',
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: color, letterSpacing: 0.4),
        ),
        _NudgeButton(
          icon: Icons.chevron_left,
          onTap: onForward,
        ),
      ],
    );
  }
}

class _NudgeButton extends StatelessWidget {
  const _NudgeButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Icon(icon, size: 22, color: palette.goldMuted),
      ),
    );
  }
}

class _SpreadView extends StatelessWidget {
  const _SpreadView({
    required this.spreadIndex,
    required this.mushaf,
    required this.surahs,
    required this.selected,
    required this.anchor,
    required this.bookmarks,
    required this.playingSurah,
    required this.playingAyah,
    required this.onSelect,
  });

  final int spreadIndex;
  final MushafData mushaf;
  final List<QuranSurah> surahs;
  final MushafAyahRef? selected;
  final MushafAyahRef? anchor;
  final Set<MushafAyahRef> bookmarks;
  final int playingSurah;
  final int? playingAyah;
  final ValueChanged<MushafAyahRef> onSelect;

  @override
  Widget build(BuildContext context) {
    final rightPage = spreadIndex * 2 + 1;
    final leftPage = rightPage + 1;
    final hasLeft = leftPage <= mushaf.pageCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: _MushafPage(
              page: rightPage,
              mushaf: mushaf,
              surahs: surahs,
              selected: selected,
              anchor: anchor,
              bookmarks: bookmarks,
              playingSurah: playingSurah,
              playingAyah: playingAyah,
              onSelect: onSelect,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: hasLeft
                ? _MushafPage(
                    page: leftPage,
                    mushaf: mushaf,
                    surahs: surahs,
                    selected: selected,
                    anchor: anchor,
                    bookmarks: bookmarks,
                    playingSurah: playingSurah,
                    playingAyah: playingAyah,
                    onSelect: onSelect,
                  )
                : const _SpineFiller(),
          ),
        ],
      ),
    );
  }
}

class _SpineFiller extends StatelessWidget {
  const _SpineFiller();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF10382A).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2E5D46).withValues(alpha: 0.4)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('﴿', style: TextStyle(fontSize: 26, color: Color(0xFFAE7C2D))),
          SizedBox(height: 6),
          Text(
            'القرآن الكريم',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFFD8CBA8),
            ),
          ),
          SizedBox(height: 6),
          Text('﴾', style: TextStyle(fontSize: 26, color: Color(0xFFAE7C2D))),
        ],
      ),
    );
  }
}

class _MushafPage extends StatefulWidget {
  const _MushafPage({
    required this.page,
    required this.mushaf,
    required this.surahs,
    required this.selected,
    required this.anchor,
    required this.bookmarks,
    required this.playingSurah,
    required this.playingAyah,
    required this.onSelect,
  });

  final int page;
  final MushafData mushaf;
  final List<QuranSurah> surahs;
  final MushafAyahRef? selected;
  final MushafAyahRef? anchor;
  final Set<MushafAyahRef> bookmarks;
  final int playingSurah;
  final int? playingAyah;
  final ValueChanged<MushafAyahRef> onSelect;

  @override
  State<_MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<_MushafPage> {
  final Map<int, TapGestureRecognizer> _recognizers = <int, TapGestureRecognizer>{};

  @override
  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  TapGestureRecognizer _recognizerFor(MushafAyahRef ref) {
    final key = ref.surah * 10000 + ref.ayah;
    final existing = _recognizers[key];
    if (existing != null) return existing;
    final recognizer = TapGestureRecognizer();
    recognizer.onTap = () => widget.onSelect(ref);
    _recognizers[key] = recognizer;
    return recognizer;
  }

  QuranSurah? _surahOf(int number) {
    if (number < 1 || number > widget.surahs.length) return null;
    return widget.surahs[number - 1];
  }

  String _verseText(MushafAyahRef ref) {
    final surah = _surahOf(ref.surah);
    if (surah == null || ref.ayah < 1 || ref.ayah > surah.verses.length) {
      return '';
    }
    return surah.verses[ref.ayah - 1].text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final refs = widget.mushaf.ayahsOnPage(widget.page);
    final firstRef = refs.isEmpty ? const MushafAyahRef(1, 1) : refs.first;
    final showBismillah =
        firstRef.ayah == 1 && firstRef.surah != 1 && firstRef.surah != 9;
    final isRightSide = widget.page.isOdd;
    return ClipRRect(
      borderRadius: BorderRadius.horizontal(
        left: isRightSide ? Radius.circular(10) : Radius.zero,
        right: isRightSide ? Radius.zero : Radius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final sidePad = 25.0;
          final headerLine = 10.0 + 40.0 + 6.0;
          final bismBlock = showBismillah ? 30.0 : 0.0;
          final footerBlock = 26.0;
          final textHeight = height - headerLine - bismBlock - footerBlock;
          final textWidth = width - sidePad * 2;
          final fontSize = _fitFontSize(textWidth, textHeight, showBismillah);
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_paper, _paper, _paperDeep],
                stops: [0.0, 0.72, 1.0],
              ),
            ),
            child: CustomPaint(
              foregroundPainter: const _MushafPagePainter(),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _PageHeader(surah: _surahOf(widget.mushaf.headerSurah(widget.page))),
                  const SizedBox(height: 6),
                  if (showBismillah)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        _bismillah,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.7,
                          color: _goldAccent,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Expanded(
                    child: _PageBody(
                      refs: refs,
                      surahs: widget.surahs,
                      selected: widget.selected,
                      anchor: widget.anchor,
                      bookmarks: widget.bookmarks,
                      playingSurah: widget.playingSurah,
                      playingAyah: widget.playingAyah,
                      fontSize: fontSize,
                      textWidth: textWidth,
                      textHeight: textHeight,
                      recognizerFor: _recognizerFor,
                      onSelect: widget.onSelect,
                    ),
                  ),
                  SizedBox(
                    height: footerBlock,
                    child: Center(
                      child: Text(
                        _arabicDigits(widget.page),
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: _inkSoft,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _fitFontSize(double textWidth, double textHeight, bool withBismillah) {
    if (textHeight <= 20 || textWidth <= 0) return 13;
    final refs = widget.mushaf.ayahsOnPage(widget.page);
    final builder = StringBuffer();
    for (final ref in refs) {
      final text = _verseText(ref);
      if (text.isEmpty) continue;
      builder
        ..write(text)
        ..write(' ');
    }
    final joined = builder.toString();
    if (joined.trim().isEmpty) return 13;
    const lineFactor = 1.95;
    for (var size = 21.0; size >= 10.5; size -= 0.25) {
      final painter = TextPainter(
        textDirection: TextDirection.rtl,
        maxLines: null,
        text: TextSpan(
          text: joined,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: size,
            height: lineFactor,
            color: _ink,
          ),
        ),
      )..layout(maxWidth: textWidth);
      final lineH = size * lineFactor;
      final lines = (painter.height / lineH).ceil();
      final badgeW = size <= 13.5 ? 15.0 : 17.0;
      final badgeOverhead = refs.length * (badgeW + size * 0.6);
      final extraLines = (badgeOverhead / textWidth).ceil();
      final measured = painter.height + extraLines * lineH + lines * 1.5;
      painter.dispose();
      if (measured <= textHeight) {
        return size;
      }
    }
    return 10.5;
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({
    required this.refs,
    required this.surahs,
    required this.selected,
    required this.anchor,
    required this.bookmarks,
    required this.playingSurah,
    required this.playingAyah,
    required this.fontSize,
    required this.textWidth,
    required this.textHeight,
    required this.recognizerFor,
    required this.onSelect,
  });

  final List<MushafAyahRef> refs;
  final List<QuranSurah> surahs;
  final MushafAyahRef? selected;
  final MushafAyahRef? anchor;
  final Set<MushafAyahRef> bookmarks;
  final int playingSurah;
  final int? playingAyah;
  final double fontSize;
  final double textWidth;
  final double textHeight;
  final TapGestureRecognizer Function(MushafAyahRef ref) recognizerFor;
  final ValueChanged<MushafAyahRef> onSelect;

  @override
  Widget build(BuildContext context) {
    if (refs.isEmpty || textHeight <= 20) {
      return const SizedBox.shrink();
    }
    final spans = _buildSpans();
    return RichText(
      maxLines: null,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      text: TextSpan(children: spans),
    );
  }

  List<InlineSpan> _buildSpans() {
    final spans = <InlineSpan>[];
    final badgeSize = fontSize <= 13.5 ? 15.0 : 17.0;
    for (final ref in refs) {
      final text = _verseText(ref);
      if (text.isEmpty) continue;
      final isPlaying = ref.surah == playingSurah && ref.ayah == (playingAyah ?? 0);
      final isSelected = selected == ref;
      final isAnchor = anchor == ref;
      final bookmarked = bookmarks.contains(ref);
      final backgroundColor = isSelected
          ? const Color(0x24113B2B)
          : isAnchor
              ? const Color(0x2EAE7C2D)
              : isPlaying
                  ? const Color(0x1CAE7C2D)
                  : null;
      spans.add(
        TextSpan(
          text: '$text ',
          recognizer: recognizerFor(ref),
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: fontSize,
            height: 1.95,
            color: _ink,
            backgroundColor: backgroundColor,
          ),
        ),
      );
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _AyahBadge(
            number: ref.ayah,
            size: badgeSize,
            filled: bookmarked,
            active: isPlaying || isSelected,
          ),
        ),
      );
      spans.add(
        TextSpan(
          text: ' ',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: fontSize,
            height: 1.95,
            color: _ink,
          ),
        ),
      );
    }
    return spans;
  }

  QuranSurah? _surahOf(int number) {
    if (number < 1 || number > surahs.length) return null;
    return surahs[number - 1];
  }

  String _verseText(MushafAyahRef ref) {
    final surah = _surahOf(ref.surah);
    if (surah == null || ref.ayah < 1 || ref.ayah > surah.verses.length) {
      return '';
    }
    return surah.verses[ref.ayah - 1].text.trim();
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.surah});

  final QuranSurah? surah;

  @override
  Widget build(BuildContext context) {
    final name = surah == null ? '' : 'سُورَةُ ${surah!.name}';
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          const _OrnamentChain(),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: _frame.withValues(alpha: 0.85)),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.25,
                      color: _ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const _OrnamentChain(),
        ],
      ),
    );
  }
}

class _OrnamentChain extends StatelessWidget {
  const _OrnamentChain();

  @override
  Widget build(BuildContext context) {
    const diamonds = [
      Text('❖', style: TextStyle(fontSize: 7.5, color: _goldAccent)),
      Text('❖', style: TextStyle(fontSize: 10, color: _goldAccent)),
      Text('❖', style: TextStyle(fontSize: 7.5, color: _goldAccent)),
    ];
    return SizedBox(
      width: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: diamonds,
      ),
    );
  }
}

class _AyahBadge extends StatelessWidget {
  const _AyahBadge({
    required this.number,
    required this.size,
    required this.filled,
    required this.active,
  });

  final int number;
  final double size;
  final bool filled;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? _goldAccent.withValues(alpha: 0.24) : _badgeWell,
        border: Border.all(
          color: active ? _goldAccent : _badgeRing,
          width: active ? 1.5 : 1.0,
        ),
      ),
      child: Text(
        _arabicDigits(number),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontWeight: FontWeight.w700,
          height: 1.0,
          fontSize: size * 0.44,
          color: active ? _goldAccent : _ink,
        ),
      ),
    );
  }
}

class _MushafPagePainter extends CustomPainter {
  const _MushafPagePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final frame1 = Rect.fromLTWH(5, 5, size.width - 10, size.height - 10);
    final frame2 = Rect.fromLTWH(10.5, 10.5, size.width - 21, size.height - 21);
    canvas.drawRect(
      frame1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _frame.withValues(alpha: 0.9),
    );
    canvas.drawRect(
      frame2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = _inkSoft.withValues(alpha: 0.5),
    );
    _paintCorner(canvas, Offset(frame2.left + 8, frame2.top + 8), const Radius.circular(12));
    _paintCorner(canvas, Offset(frame2.right - 8, frame2.top + 8), const Radius.circular(12));
    _paintCorner(canvas, Offset(frame2.left + 8, frame2.bottom - 8), const Radius.circular(12));
    _paintCorner(canvas, Offset(frame2.right - 8, frame2.bottom - 8), const Radius.circular(12));
  }

  void _paintCorner(Canvas canvas, Offset point, Radius radius) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _frame.withValues(alpha: 0.8);
    final arcRect = Rect.fromCircle(center: point, radius: 11);
    canvas.drawArc(arcRect, 0, 3.14159 * 2, false, ringPaint);
    final dotPaint = Paint()..color = _goldAccent.withValues(alpha: 0.8);
    canvas.drawCircle(point, 2.8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AyahActionSheet extends StatelessWidget {
  const _AyahActionSheet({
    required this.ref,
    required this.surahs,
    required this.palette,
    required this.isBookmarked,
    required this.onPlay,
    required this.onBookmark,
    required this.onClose,
  });

  final MushafAyahRef ref;
  final List<QuranSurah> surahs;
  final RafiqPalette palette;
  final bool isBookmarked;
  final VoidCallback onPlay;
  final VoidCallback onBookmark;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final surah = ref.surah <= surahs.length ? surahs[ref.surah - 1] : null;
    final text =
        surah == null || ref.ayah > surah.verses.length ? '' : surah.verses[ref.ayah - 1].text;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: palette.backgroundSecondary.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 2),
                  child: Text(
                    '${surah?.name ?? ''} • الآية ${_arabicDigits(ref.ayah)}',
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: palette.textDim),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 14,
                    height: 1.5,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          _SheetButton(
            palette: palette,
            icon: Icons.play_arrow,
            color: palette.goldBright,
            onTap: onPlay,
          ),
          _SheetButton(
            palette: palette,
            icon: isBookmarked ? Icons.bookmark : Icons.bookmark_add,
            color: palette.goldMuted,
            onTap: onBookmark,
          ),
          _SheetButton(
            palette: palette,
            icon: Icons.close,
            color: palette.textDim,
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.palette,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final RafiqPalette palette;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: Material(
        color: palette.surfaceHigh.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          child: SizedBox(
            width: 40,
            height: 38,
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}

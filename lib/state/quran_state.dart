import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../data/preferences.dart';
import '../data/repositories.dart';

enum QuranAudioPhase { idle, preparing, playing, paused }

class QuranBookmark {
  const QuranBookmark({
    required this.id,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.snippet,
    required this.createdAt,
  });

  factory QuranBookmark.fromJson(Map<String, dynamic> json) {
    return QuranBookmark(
      id: '${json['id'] ?? ''}',
      surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 0,
      ayahNumber: (json['ayahNumber'] as num?)?.toInt() ?? 0,
      surahName: (json['surahName'] as String?) ?? '',
      snippet: (json['snippet'] as String?) ?? '',
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String snippet;
  final int createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'surahName': surahName,
      'snippet': snippet,
      'createdAt': createdAt,
    };
  }
}

class QuranState extends ChangeNotifier {
  QuranState({required this.preferencesRepository, QuranRepository? repository})
    : _repository = repository ?? QuranRepository();

  static const String audioErrorMessage =
      'تعذّر تشغيل التلاوة، تحقق من اتصال الإنترنت';
  static const String loadErrorMessage = 'تعذّر تحميل المصحف من ملفات التطبيق';
  static const String bookmarkErrorMessage = 'تعذّر حفظ العلامة';

  final PreferencesRepository preferencesRepository;
  final QuranRepository _repository;
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<void>? _completeSubscription;

  bool isLoading = true;
  String? error;
  QuranData? data;
  int surahNumber = 1;
  int mode = 0;
  List<QuranBookmark> bookmarks = const <QuranBookmark>[];
  int currentAyah = 1;
  int? scrollRequest;
  QuranAudioPhase audioPhase = QuranAudioPhase.idle;
  int? playingAyah;
  String? audioMessage;
  String? message;

  int _lastSavedAt = 0;
  bool _disposed = false;

  QuranSurah? get surah {
    final current = data;
    if (current == null) return null;
    final index = surahNumber - 1;
    if (index < 0 || index >= current.surahs.length) return null;
    return current.surahs[index];
  }

  List<QuranSurah> get surahs => data?.surahs ?? const <QuranSurah>[];

  bool get showTranslation => mode == 1;

  bool get isAudioActive => audioPhase != QuranAudioPhase.idle;

  String get audioStatusText {
    switch (audioPhase) {
      case QuranAudioPhase.idle:
        return 'اختر آية للاستماع';
      case QuranAudioPhase.preparing:
        return 'جارٍ تجهيز التلاوة...';
      case QuranAudioPhase.playing:
        return 'تُتلى الآن الآية ${playingAyah ?? ''}';
      case QuranAudioPhase.paused:
        return 'تلاوة متوقفة مؤقتًا';
    }
  }

  QuranState init() {
    _loadBookmarks();
    _completeSubscription = _player.onPlayerComplete.listen((_) {
      unawaited(_advanceAfterCompletion());
    });
    _ignoreErrors(_player.setReleaseMode(ReleaseMode.stop));
    _ignoreErrors(
      _player.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      ),
    );
    unawaited(load());
    return this;
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    try {
      final loaded = await _repository.load();
      if (_disposed) return;
      final preferences = preferencesRepository.current();
      final maxSurah = loaded.surahs.isEmpty ? 1 : loaded.surahs.length;
      final initialSurah = preferences.quranSurah.clamp(1, maxSurah);
      final initialAyah = initialSurah == preferences.quranSurah
          ? preferences.quranAyah
          : 1;
      data = loaded;
      isLoading = false;
      surahNumber = initialSurah;
      currentAyah = initialAyah;
      scrollRequest = initialAyah;
    } catch (_) {
      if (_disposed) return;
      isLoading = false;
      error = loadErrorMessage;
    }
    _notify();
  }

  void retry() {
    unawaited(load());
  }

  void setMode(int index) {
    final value = index.clamp(0, 1);
    if (value == mode) return;
    mode = value;
    _notify();
  }

  void selectSurah(int number) {
    final current = data;
    if (current == null) return;
    final target = number.clamp(1, current.surahs.length);
    final preferences = preferencesRepository.current();
    final savedAyah = preferences.quranSurah == target
        ? preferences.quranAyah
        : 1;
    unawaited(_stopPlayerOnly());
    surahNumber = target;
    currentAyah = savedAyah;
    scrollRequest = savedAyah;
    _savePosition(target, savedAyah, immediate: true);
    _notify();
  }

  void consumeScrollRequest() {
    if (scrollRequest == null) return;
    scrollRequest = null;
  }

  void onAyahVisible(int surah, int ayah) {
    if (surahNumber != surah) return;
    currentAyah = ayah;
    _savePosition(surah, ayah);
  }

  bool isBookmarked(int surah, int ayah) {
    return bookmarks.any(
      (bookmark) =>
          bookmark.surahNumber == surah && bookmark.ayahNumber == ayah,
    );
  }

  Future<void> toggleBookmark(int surah, int ayah) async {
    final current = data;
    if (current == null) return;
    if (surah < 1 || surah > current.surahs.length) return;
    final targetSurah = current.surahs[surah - 1];
    if (ayah < 1 || ayah > targetSurah.verses.length) return;
    final verse = targetSurah.verses[ayah - 1];
    final exists = isBookmarked(surah, ayah);
    if (exists) {
      bookmarks = bookmarks
          .where(
            (bookmark) =>
                !(bookmark.surahNumber == surah && bookmark.ayahNumber == ayah),
          )
          .toList();
    } else {
      final now = DateTime.now();
      final snippet = verse.text.length > 120
          ? verse.text.substring(0, 120)
          : verse.text;
      final bookmark = QuranBookmark(
        id: '$surah-$ayah-${now.microsecondsSinceEpoch}',
        surahNumber: surah,
        ayahNumber: ayah,
        surahName: targetSurah.name,
        snippet: snippet,
        createdAt: now.millisecondsSinceEpoch,
      );
      bookmarks = <QuranBookmark>[bookmark, ...bookmarks];
    }
    try {
      await _persistBookmarks();
    } catch (_) {
      message = bookmarkErrorMessage;
    }
    _notify();
  }

  Future<void> deleteBookmark(QuranBookmark bookmark) async {
    bookmarks = bookmarks
        .where(
          (item) =>
              !(item.surahNumber == bookmark.surahNumber &&
                  item.ayahNumber == bookmark.ayahNumber),
        )
        .toList();
    try {
      await _persistBookmarks();
    } catch (_) {
      message = bookmarkErrorMessage;
    }
    _notify();
  }

  void openBookmark(QuranBookmark bookmark) {
    unawaited(_stopPlayerOnly());
    surahNumber = bookmark.surahNumber;
    currentAyah = bookmark.ayahNumber;
    scrollRequest = bookmark.ayahNumber;
    audioPhase = QuranAudioPhase.idle;
    playingAyah = null;
    _notify();
  }

  Future<void> togglePlayPause() async {
    switch (audioPhase) {
      case QuranAudioPhase.playing:
        await _player.pause();
        audioPhase = QuranAudioPhase.paused;
        _notify();
        break;
      case QuranAudioPhase.paused:
        await _player.resume();
        audioPhase = QuranAudioPhase.playing;
        _notify();
        break;
      case QuranAudioPhase.idle:
      case QuranAudioPhase.preparing:
        if (audioPhase == QuranAudioPhase.preparing) return;
        await playAyah(currentAyah);
        break;
    }
  }

  Future<void> playAyah(int ayah) async {
    final targetSurah = surah;
    if (targetSurah == null) return;
    if (targetSurah.verses.isEmpty) return;
    final target = ayah.clamp(1, targetSurah.verses.length);
    await _stopPlayerOnly();
    audioPhase = QuranAudioPhase.preparing;
    playingAyah = target;
    currentAyah = target;
    _notify();
    final url = _audioUrl(targetSurah, targetSurah.verses[target - 1].number);
    try {
      await _player.setSourceUrl(url);
      if (_disposed || playingAyah != target) return;
      await _player.resume();
      if (_disposed || playingAyah != target) return;
      audioPhase = QuranAudioPhase.playing;
    } catch (_) {
      if (_disposed) return;
      audioPhase = QuranAudioPhase.idle;
      playingAyah = null;
      audioMessage = audioErrorMessage;
    }
    _notify();
  }

  Future<void> skipNext() async {
    final targetSurah = surah;
    if (targetSurah == null) return;
    final from = playingAyah ?? currentAyah;
    if (from < targetSurah.verses.length) {
      await playAyah(from + 1);
    }
  }

  Future<void> skipPrevious() async {
    final targetSurah = surah;
    if (targetSurah == null) return;
    final from = playingAyah ?? currentAyah;
    if (from > 1) {
      await playAyah(from - 1);
    }
  }

  Future<void> stopAudio() async {
    await _stopPlayerOnly();
    audioPhase = QuranAudioPhase.idle;
    playingAyah = null;
    _notify();
  }

  void consumeAudioMessage() {
    if (audioMessage == null) return;
    audioMessage = null;
  }

  void consumeMessage() {
    if (message == null) return;
    message = null;
  }

  void consumeMessages() {
    consumeMessage();
    consumeAudioMessage();
  }

  static String _audioUrl(QuranSurah surah, int ayah) {
    final surahPart = surah.number.toString().padLeft(3, '0');
    final ayahPart = ayah.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/Alafasy_128kbps/$surahPart$ayahPart.mp3';
  }

  Future<void> _advanceAfterCompletion() async {
    final finished = playingAyah;
    final targetSurah = surah;
    if (finished == null || targetSurah == null) {
      audioPhase = QuranAudioPhase.idle;
      playingAyah = null;
      _notify();
      return;
    }
    if (finished >= targetSurah.verses.length) {
      audioPhase = QuranAudioPhase.idle;
      playingAyah = null;
      _notify();
      return;
    }
    await playAyah(finished + 1);
  }

  Future<void> _stopPlayerOnly() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  void _savePosition(int surah, int ayah, {bool immediate = false}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!immediate && now - _lastSavedAt < 2000) return;
    _lastSavedAt = now;
    _ignoreErrors(preferencesRepository.setQuranPosition(surah, ayah));
  }

  void _loadBookmarks() {
    final raw = preferencesRepository.bookmarksJson();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        bookmarks = const <QuranBookmark>[];
        return;
      }
      final loaded = <QuranBookmark>[];
      for (final entry in decoded) {
        if (entry is Map) {
          loaded.add(QuranBookmark.fromJson(Map<String, dynamic>.from(entry)));
        }
      }
      loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      bookmarks = loaded;
    } catch (_) {
      bookmarks = const <QuranBookmark>[];
    }
  }

  Future<void> _persistBookmarks() {
    final payload = jsonEncode(
      bookmarks.map((bookmark) => bookmark.toJson()).toList(),
    );
    return preferencesRepository.setBookmarksJson(payload);
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  void _ignoreErrors(Future<void> future) {
    future.then<void>((_) {}, onError: (Object error) {});
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_completeSubscription?.cancel());
    _ignoreErrors(_player.stop());
    _ignoreErrors(_player.release());
    super.dispose();
  }
}

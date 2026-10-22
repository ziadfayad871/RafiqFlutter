import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class MushafAyahRef {
  const MushafAyahRef(this.surah, this.ayah);

  final int surah;
  final int ayah;

  @override
  bool operator ==(Object other) =>
      other is MushafAyahRef &&
      other.surah == surah &&
      other.ayah == ayah;

  @override
  int get hashCode => surah * 10000 + ayah;

  @override
  String toString() => '$surah:$ayah';
}

class MushafData {
  MushafData._(
    this.pageCount,
    this.ayahCount,
    List<int> chapterFirstAyah,
    List<int> runs,
  ) : _chapterFirstAyah = chapterFirstAyah,
      _ayahPage = List<int>.filled(ayahCount + 1, -1, growable: false) {
    for (var i = 0; i < runs.length; i += 3) {
      final start = runs[i];
      final page = runs[i + 1];
      final length = runs[i + 2];
      for (var g = start; g < start + length && g <= ayahCount; g++) {
        _ayahPage[g] = page;
      }
    }
    for (var g = 1; g <= ayahCount; g++) {
      final page = _ayahPage[g];
      if (page <= 0) continue;
      final chapter = _chapterOfGlobal(g);
      final ref = MushafAyahRef(
        chapter,
        g - chapterFirstAyah[chapter - 1] + 1,
      );
      final existing = _ayahsOnPage[page];
      if (existing == null) {
        _firstAyahOfPage[page] = ref;
        _lastAyahOfPage[page] = ref;
        _ayahsOnPage[page] = <MushafAyahRef>[ref];
      } else {
        _lastAyahOfPage[page] = ref;
        existing.add(ref);
      }
    }
  }

  final int pageCount;
  final int ayahCount;
  final List<int> _chapterFirstAyah;
  final List<int> _ayahPage;
  final Map<int, MushafAyahRef> _firstAyahOfPage = <int, MushafAyahRef>{};
  final Map<int, MushafAyahRef> _lastAyahOfPage = <int, MushafAyahRef>{};
  final Map<int, List<MushafAyahRef>> _ayahsOnPage = <int, List<MushafAyahRef>>{};

  static MushafData? _cached;
  static Future<void>? _pending;

  static Future<MushafData> load() {
    final cached = _cached;
    if (cached != null) return Future<MushafData>.value(cached);
    final pending = _pending;
    if (pending != null) return pending.then((_) => _cached!);
    final completer = Completer<void>();
    _pending = completer.future;
    return _readAsset()
        .then((data) {
          _cached = data;
          completer.complete();
          return data;
        })
        .catchError((Object error) {
          completer.completeError(error);
          throw error;
        });
  }

  static Future<MushafData> _readAsset() async {
    final raw = await rootBundle.loadString('assets/mushaf_pages.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final count = (decoded['count'] as num).toInt();
    final ayahs = (decoded['ayahs'] as num).toInt();
    final chapterFirst = <int>[
      for (final value in (decoded['chapterFirstAyah'] as List))
        (value as num).toInt(),
    ];
    final runs = <int>[];
    for (final run in decoded['runs'] as List) {
      final parts = run as List<dynamic>;
      runs.add((parts[0] as num).toInt());
      runs.add((parts[1] as num).toInt());
      runs.add((parts[2] as num).toInt());
    }
    return MushafData._(count, ayahs, chapterFirst, runs);
  }

  int _chapterOfGlobal(int globalIndex) {
    var low = 0;
    var high = _chapterFirstAyah.length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (_chapterFirstAyah[mid] <= globalIndex) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low + 1;
  }

  int globalAyahIndex(int surah, int ayah) {
    if (surah < 1 || surah > _chapterFirstAyah.length) return 0;
    final global = _chapterFirstAyah[surah - 1] + ayah - 1;
    if (global < 1 || global > ayahCount) return 0;
    return global;
  }

  MushafAyahRef globalToRef(int globalIndex) {
    final clamped = globalIndex.clamp(1, ayahCount);
    final chapter = _chapterOfGlobal(clamped);
    return MushafAyahRef(chapter, clamped - _chapterFirstAyah[chapter - 1] + 1);
  }

  int pageOf(int surah, int ayah) {
    final global = globalAyahIndex(surah, ayah);
    if (global <= 0) return 1;
    final page = _ayahPage[global];
    return page <= 0 ? 1 : page;
  }

  List<MushafAyahRef> ayahsOnPage(int page) =>
      _ayahsOnPage[page.clamp(1, pageCount)] ?? const <MushafAyahRef>[];

  MushafAyahRef firstAyahOf(int page) =>
      _firstAyahOfPage[page.clamp(1, pageCount)] ??
      const MushafAyahRef(1, 1);

  MushafAyahRef lastAyahOf(int page) =>
      _lastAyahOfPage[page.clamp(1, pageCount)] ??
      const MushafAyahRef(114, 6);

  int headerSurah(int page) {
    final refs = _ayahsOnPage[page.clamp(1, pageCount)];
    if (refs == null || refs.isEmpty) return 1;
    for (final ref in refs) {
      if (ref.ayah == 1) return ref.surah;
    }
    return refs.last.surah;
  }
}

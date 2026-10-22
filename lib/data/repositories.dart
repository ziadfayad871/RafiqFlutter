import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class QuranVerse {
  const QuranVerse({required this.number, required this.text, required this.translation});

  final int number;
  final String text;
  final String translation;

  factory QuranVerse.fromJson(Map<String, dynamic> json) => QuranVerse(
        number: json['number'] as int,
        text: json['text'] as String,
        translation: (json['translation'] as String?) ?? '',
      );
}

class QuranSurah {
  const QuranSurah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.revelation,
    required this.versesCount,
    required this.bismillahBefore,
    required this.verses,
  });

  final int number;
  final String name;
  final String englishName;
  final String revelation;
  final int versesCount;
  final bool bismillahBefore;
  final List<QuranVerse> verses;

  factory QuranSurah.fromJson(Map<String, dynamic> json) => QuranSurah(
        number: json['number'] as int,
        name: json['name'] as String,
        englishName: (json['englishName'] as String?) ?? '',
        revelation: (json['revelation'] as String?) ?? 'مكية',
        versesCount: (json['versesCount'] as int?) ?? 0,
        bismillahBefore: (json['bismillahBefore'] as bool?) ?? true,
        verses: ((json['verses'] as List<dynamic>?) ?? const [])
            .map((v) => QuranVerse.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
}

class QuranData {
  const QuranData({required this.source, required this.translationSource, required this.surahs});

  final String source;
  final String translationSource;
  final List<QuranSurah> surahs;
}

class QuranRepository {
  QuranData? _cached;

  Future<QuranData> load() async {
    final cached = _cached;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/quran.json');
    final data = await compute(parseQuranData, raw);
    _cached = data;
    return data;
  }
}

QuranData parseQuranData(String raw) {
  final decoded = json.decode(raw) as Map<String, dynamic>;
  return QuranData(
    source: (decoded['source'] as String?) ?? '',
    translationSource: (decoded['translationSource'] as String?) ?? '',
    surahs: ((decoded['surahs'] as List<dynamic>?) ?? const [])
        .map((s) => QuranSurah.fromJson(s as Map<String, dynamic>))
        .toList(),
  );
}

class AdhkarItem {
  const AdhkarItem({
    required this.id,
    required this.title,
    required this.text,
    required this.count,
    required this.countText,
    required this.source,
    required this.benefit,
  });

  final String id;
  final String? title;
  final String text;
  final int count;
  final String countText;
  final String source;
  final String benefit;

  factory AdhkarItem.fromJson(Map<String, dynamic> json) => AdhkarItem(
        id: json['id'] as String,
        title: (json['title'] as String?)?.trim().isEmpty ?? true ? null : json['title'] as String,
        text: json['text'] as String,
        count: (json['count'] as int?) ?? 1,
        countText: (json['countText'] as String?) ?? '',
        source: (json['source'] as String?) ?? '',
        benefit: (json['benefit'] as String?) ?? '',
      );
}

class AdhkarCategory {
  const AdhkarCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
  });

  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final List<AdhkarItem> items;

  factory AdhkarCategory.fromJson(Map<String, dynamic> json) => AdhkarCategory(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: (json['subtitle'] as String?) ?? '',
        icon: (json['icon'] as String?) ?? 'star',
        items: ((json['items'] as List<dynamic>?) ?? const [])
            .map((i) => AdhkarItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class AdhkarData {
  const AdhkarData({required this.source, required this.categories});

  final String source;
  final List<AdhkarCategory> categories;
}

class AdhkarRepository {
  AdhkarData? _cached;

  Future<AdhkarData> load() async {
    final cached = _cached;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/adhkar.json');
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final data = AdhkarData(
      source: (decoded['source'] as String?) ?? '',
      categories: ((decoded['categories'] as List<dynamic>?) ?? const [])
          .map((c) => AdhkarCategory.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
    _cached = data;
    return data;
  }
}

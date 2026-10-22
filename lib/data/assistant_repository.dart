import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

const String defaultAssistantFallback =
    'لا أملك إجابة موثوقة لهذا السؤال ضمن المصادر المحفوظة داخل رفيق، ولا أنسب إلى الله أو رسوله ﷺ ما لم يثبت. اسألني عن الصلاة أو القرآن أو الأذكار.';

const List<String> defaultAssistantSuggestions = [
  'افتح القرآن',
  'ما هي الصلاة القادمة؟',
  'ابدأ جلسة تركيز ٢٥ دقيقة',
  'ذكرني بورد القرآن الساعة 8',
];

class AssistantAnswer {
  const AssistantAnswer({
    required this.id,
    required this.keywords,
    required this.answer,
    required this.source,
    this.action,
  });

  final String id;
  final List<String> keywords;
  final String answer;
  final String source;
  final String? action;

  factory AssistantAnswer.fromJson(Map<String, dynamic> json) {
    final rawKeywords = json['keywords'];
    final keywords = rawKeywords is List
        ? rawKeywords
              .map((value) => '$value'.trim())
              .where((value) => value.isNotEmpty)
              .toList()
        : const <String>[];
    return AssistantAnswer(
      id: json['id'] as String? ?? '',
      keywords: keywords,
      answer: (json['answer'] as String?) ?? (json['text'] as String?) ?? '',
      source: json['source'] as String? ?? '',
      action: json['action'] as String?,
    );
  }
}

class AssistantAnswers {
  const AssistantAnswers({
    required this.suggestions,
    required this.answers,
    required this.fallback,
  });

  final List<String> suggestions;
  final List<AssistantAnswer> answers;
  final String fallback;
}

class AssistantRepository {
  AssistantAnswers? _cached;

  Future<AssistantAnswers> load() async {
    final cached = _cached;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/assistant_answers.json');
    final data = parse(raw);
    _cached = data;
    return data;
  }

  static AssistantAnswers parse(String raw) {
    final decoded = json.decode(raw);
    if (decoded is! Map) {
      return const AssistantAnswers(
        suggestions: defaultAssistantSuggestions,
        answers: <AssistantAnswer>[],
        fallback: defaultAssistantFallback,
      );
    }
    final root = decoded.cast<dynamic, dynamic>();
    final rawSuggestions = root['suggestions'];
    final suggestions = rawSuggestions is List
        ? rawSuggestions
              .map((value) => '$value'.trim())
              .where((value) => value.isNotEmpty)
              .toList()
        : <String>[];
    final rawAnswers = root['answers'];
    final answers = rawAnswers is List
        ? rawAnswers
              .whereType<Map>()
              .map(
                (entry) =>
                    AssistantAnswer.fromJson(entry.cast<String, dynamic>()),
              )
              .toList()
        : <AssistantAnswer>[];
    final fallback = root['fallback'] is String
        ? root['fallback'] as String
        : defaultAssistantFallback;
    return AssistantAnswers(
      suggestions: suggestions.isEmpty
          ? defaultAssistantSuggestions
          : suggestions,
      answers: answers,
      fallback: fallback.isEmpty ? defaultAssistantFallback : fallback,
    );
  }
}

final RegExp _arabicDiacritics = RegExp('[\u064B-\u065F\u0670\u06D6-\u06ED]');

String normalizeArabicForSearch(String value) {
  final withoutDiacritics = value
      .replaceAll(_arabicDiacritics, '')
      .replaceAll('\u0640', '')
      .replaceAll('\u0623', '\u0627')
      .replaceAll('\u0625', '\u0627')
      .replaceAll('\u0622', '\u0627')
      .replaceAll('\u0649', '\u064A')
      .replaceAll('\u0629', '\u0647');
  return withoutDiacritics.toLowerCase().trim();
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/assistant_repository.dart';
import '../data/prayer_calculator.dart';
import '../data/repositories.dart';
import '../data/tasks_repository.dart';
import '../util/arabic_formatters.dart';
import 'app_state.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.fromUser,
    required this.text,
    this.source,
  });

  final int id;
  final bool fromUser;
  final String text;
  final String? source;
}

class AssistantReply {
  const AssistantReply(this.text, {this.source, this.route});

  final String text;
  final String? source;
  final String? route;
}

class AssistantState extends ChangeNotifier {
  AssistantState({
    required this.repository,
    required this.appState,
    required this.tasksRepository,
    QuranRepository? quranRepository,
    this.nextPrayerProvider,
    this.onNavigate,
  }) : _quranRepository = quranRepository ?? QuranRepository();

  final AssistantRepository repository;
  final AppState appState;
  final TasksRepository tasksRepository;
  final NextPrayerInfo? Function()? nextPrayerProvider;
  final void Function(String route)? onNavigate;
  final QuranRepository _quranRepository;

  final List<ChatMessage> _messages = <ChatMessage>[];
  List<String> _suggestions = defaultAssistantSuggestions;
  List<AssistantAnswer> _answers = const <AssistantAnswer>[];
  String _fallback = defaultAssistantFallback;
  bool _isThinking = false;
  QuranData? _quranData;
  bool _quranResolved = false;
  int _nextId = 1;
  Timer? _pendingTimer;

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);

  List<String> get suggestions => _suggestions;

  bool get isThinking => _isThinking;

  String get fallback => _fallback;

  @override
  void dispose() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
    super.dispose();
  }

  Future<void> load() async {
    try {
      final data = await repository.load();
      if (data.suggestions.isNotEmpty) _suggestions = data.suggestions;
      _answers = data.answers;
      _fallback = data.fallback;
    } catch (_) {}
    notifyListeners();
  }

  void send(String rawInput) {
    final input = rawInput.trim();
    if (input.isEmpty) return;
    _messages.add(ChatMessage(id: _nextId++, fromUser: true, text: input));
    _isThinking = true;
    notifyListeners();
    _pendingTimer?.cancel();
    _pendingTimer = Timer(const Duration(milliseconds: 420), () async {
      final reply = await _buildReply(input);
      _isThinking = false;
      _messages.add(
        ChatMessage(
          id: _nextId++,
          fromUser: false,
          text: reply.text,
          source: reply.source,
        ),
      );
      notifyListeners();
      final route = reply.route;
      if (route != null) onNavigate?.call(route);
    });
  }

  void clearConversation() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _messages.clear();
    notifyListeners();
  }

  Future<AssistantReply> _buildReply(String input) async {
    final normalized = normalizeArabicForSearch(input);

    final open = _openIntent(normalized);
    if (open != null) return open;

    final prayer = _prayerIntent(normalized);
    if (prayer != null) return prayer;

    final ayah = await _ayahIntent(normalized);
    if (ayah != null) return ayah;

    final focus = await _focusIntent(normalized);
    if (focus != null) return focus;

    final task = await _taskIntent(normalized);
    if (task != null) return task;

    for (final entry in _answers) {
      for (final keyword in entry.keywords) {
        if (normalized.contains(normalizeArabicForSearch(keyword))) {
          return AssistantReply(entry.answer, source: entry.source);
        }
      }
    }
    return AssistantReply(_fallback);
  }

  AssistantReply? _openIntent(String normalized) {
    if (!normalized.contains('افتح') && !normalized.contains('شغل')) {
      return null;
    }
    const destinations = <_Destination>[
      _Destination(['القران', 'المصحف'], 'quran', 'المصحف'),
      _Destination(['الاذكار', 'اذكار'], 'adhkar', 'الأذكار'),
      _Destination(['الصلاه', 'المواقيت', 'مواقيت'], 'prayer', 'مواقيت الصلاة'),
      _Destination(['المهام', 'مهامي'], 'tasks', 'المهام'),
      _Destination(['التركيز'], 'focus', 'التركيز'),
      _Destination(['الاعدادات', 'الاعداد'], 'settings', 'الإعدادات'),
      _Destination(['التطبيقات', 'التطبيقا'], 'apps', 'التطبيقات'),
    ];
    for (final destination in destinations) {
      for (final keyword in destination.keywords) {
        if (normalized.contains(keyword)) {
          return AssistantReply(
            'فتحت لك ${destination.label}.',
            route: destination.route,
          );
        }
      }
    }
    return null;
  }

  AssistantReply? _prayerIntent(String normalized) {
    final asksNext =
        normalized.contains('الصلاة القادمة') ||
        normalized.contains('الصلاه القادمه') ||
        normalized.contains('مواقيت') ||
        normalized.contains('متى الصلاة') ||
        (normalized.contains('وقت') && normalized.contains('الصلاه'));
    if (!asksNext) return null;
    final info = nextPrayerProvider?.call();
    if (info == null) return null;
    final preferences = appState.preferences;
    final method = CalculationMethod.fromId(preferences.calculationMethod);
    final timeLabel = formatTime12Hour(info.prayer.time);
    final remaining = formatCountdown(info.remaining);
    final notificationHint = preferences.prayerNotifications
        ? 'وتنبيهات الصلاة مفعّلة.'
        : 'ويمكنك تفعيل تنبيهات الصلاة من قسم الصلاة.';
    return AssistantReply(
      'الصلاة القادمة هي ${info.prayer.name} الساعة $timeLabel، $remaining. '
      'الحساب حسب ${preferences.locationLabel}. $notificationHint',
      source:
          'حساب فلكي حسب الإحداثيات والطريقة المختارة (${method.arabicName}).',
    );
  }

  Future<AssistantReply?> _ayahIntent(String normalized) async {
    final asksAyah =
        normalized.contains('ايه الكرسي') ||
        normalized.contains('اية الكرسي') ||
        normalized.contains('آية الكرسي');
    if (!asksAyah) return null;
    final data = await _loadQuran();
    if (data == null) {
      return const AssistantReply(
        'يمكنك قراءة آية الكرسي من سورة البقرة داخل المصحف في رفيق (الآية 255).',
        source: 'سورة البقرة، الآية 255.',
      );
    }
    QuranVerse? verse;
    for (final surah in data.surahs) {
      if (surah.number == 2) {
        for (final candidate in surah.verses) {
          if (candidate.number == 255) {
            verse = candidate;
            break;
          }
        }
        break;
      }
    }
    if (verse == null && data.surahs.length > 1) {
      final surah = data.surahs[1];
      if (surah.verses.length > 254) {
        verse = surah.verses[254];
      }
    }
    if (verse == null) {
      return const AssistantReply(
        'يمكنك قراءة آية الكرسي من سورة البقرة داخل المصحف (الآية 255).',
      );
    }
    return AssistantReply(
      verse.text,
      source: 'سورة البقرة، الآية 255 — النص العثماني الموثق.',
    );
  }

  Future<AssistantReply?> _focusIntent(String normalized) async {
    final asksFocus =
        normalized.contains('جلسة تركيز') ||
        normalized.contains('جلسه تركيز') ||
        normalized.contains('ابدأ التركيز') ||
        normalized.contains('شغل التركيز');
    if (!asksFocus) return null;
    final preferences = appState.preferences;
    final minutes =
        _parseMinutes(normalized) ?? preferences.focusDurationMinutes;
    await appState.setFocusDuration(minutes);
    return AssistantReply(
      'جهّزت لك جلسة تركيز لمدة $minutes دقيقة، وفتحت شاشة التركيز. اضغط ابدأ متى شئت.',
      route: 'focus',
    );
  }

  Future<AssistantReply?> _taskIntent(String normalized) async {
    final reminder = normalized.contains('ذكرني');
    final addTask =
        normalized.contains('اضف مهمه') ||
        normalized.contains('اضف مهمة') ||
        normalized.contains('ذكرني');
    if (!reminder && !addTask) return null;

    final keyword = reminder ? 'ذكرني' : 'اضف مهمه';
    var remainder = normalized.contains(keyword)
        ? normalized.substring(normalized.indexOf(keyword) + keyword.length)
        : normalized;
    remainder = remainder.trim();
    if (remainder.startsWith('ب')) {
      remainder = remainder.substring(1).trim();
    }

    final timeIndex = remainder.indexOf('الساعه');
    var title = remainder;
    String? timeLabel;
    if (timeIndex >= 0) {
      title = remainder.substring(0, timeIndex).trim();
      final timePart = _normalizeDigits(
        remainder.substring(timeIndex + 'الساعه'.length),
      ).trim();
      timeLabel = _parseTimeLabel(timePart);
    }
    title = title.replaceAll(RegExp(r'^[ .،!?؟]+|[ .،!?؟]+$'), '');
    if (title.isEmpty) {
      return const AssistantReply(
        'اكتب لي عنوان المهمة، مثل: «ذكرني بمراجعة الدرس الساعة 8».',
      );
    }
    try {
      await tasksRepository.add(title, timeLabel);
    } catch (_) {}
    final timeText = timeLabel != null ? ' الساعة $timeLabel' : '';
    return AssistantReply('أضفت مهمة: «$title»$timeText إلى قائمة مهام اليوم.');
  }

  Future<QuranData?> _loadQuran() async {
    if (_quranResolved) return _quranData;
    _quranResolved = true;
    try {
      _quranData = await _quranRepository.load();
    } catch (_) {
      _quranData = null;
    }
    return _quranData;
  }

  int? _parseMinutes(String normalized) {
    final digits = _normalizeDigits(normalized);
    final minuteMatch = RegExp(r'(\d{1,3})\s*(دقيق|دقيقه)').firstMatch(digits);
    if (minuteMatch != null) {
      final value = int.tryParse(minuteMatch.group(1) ?? '');
      if (value != null) return value.clamp(5, 180).toInt();
    }
    final hourMatch = RegExp(r'(\d{1,2})\s*(ساع|ساعه)').firstMatch(digits);
    if (hourMatch != null) {
      final value = int.tryParse(hourMatch.group(1) ?? '');
      if (value != null) return (value * 60).clamp(5, 180).toInt();
    }
    return null;
  }

  String? _parseTimeLabel(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;
    final match = RegExp(r'(\d{1,2})(?::(\d{2}))?').firstMatch(cleaned);
    if (match != null) {
      final hour = int.tryParse(match.group(1) ?? '');
      if (hour == null) return null;
      final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
    return cleaned.length > 12 ? cleaned.substring(0, 12) : cleaned;
  }

  String _normalizeDigits(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + (rune - 0x0660));
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + (rune - 0x06F0));
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }
}

class _Destination {
  const _Destination(this.keywords, this.route, this.label);

  final List<String> keywords;
  final String route;
  final String label;
}

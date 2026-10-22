import 'package:flutter/foundation.dart';

import '../platform/bridges.dart';
import '../widgets/rafiq_icons.dart';

class BuiltinApp {
  const BuiltinApp({
    required this.id,
    required this.label,
    required this.destination,
    required this.icon,
  });

  final String id;
  final String label;
  final String destination;
  final RafiqIconData icon;
}

class AppsState extends ChangeNotifier {
  static const List<BuiltinApp> builtinApps = <BuiltinApp>[
    BuiltinApp(
      id: 'quran',
      label: 'القرآن',
      destination: 'quran',
      icon: RafiqIcons.quranBook,
    ),
    BuiltinApp(
      id: 'adhkar',
      label: 'الأذكار',
      destination: 'adhkar',
      icon: RafiqIcons.prayerBeads,
    ),
    BuiltinApp(
      id: 'prayer',
      label: 'الصلاة',
      destination: 'prayer',
      icon: RafiqIcons.mosque,
    ),
    BuiltinApp(
      id: 'tasks',
      label: 'المهام',
      destination: 'tasks',
      icon: RafiqIcons.tasks,
    ),
    BuiltinApp(
      id: 'focus',
      label: 'التركيز',
      destination: 'focus',
      icon: RafiqIcons.focus,
    ),
    BuiltinApp(
      id: 'assistant',
      label: 'مساعد رفيق',
      destination: 'assistant',
      icon: RafiqIcons.sparkle,
    ),
    BuiltinApp(
      id: 'settings',
      label: 'الإعدادات',
      destination: 'settings',
      icon: RafiqIcons.settings,
    ),
  ];

  List<InstalledApp> installedApps = const <InstalledApp>[];
  bool isLoading = true;
  String? error;
  String? message;

  Future<void> refresh() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final apps = await LauncherBridge.listApps();
      installedApps = _sorted(apps);
      isLoading = false;
    } catch (_) {
      installedApps = const <InstalledApp>[];
      isLoading = false;
      error = 'تعذّر قراءة التطبيقات المثبتة';
    }
    notifyListeners();
  }

  Future<void> launch(InstalledApp app) async {
    var opened = false;
    try {
      opened = await LauncherBridge.launchApp(
        app.packageName,
        app.activityName,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      message = 'تعذّر فتح ${app.label}';
      notifyListeners();
    }
  }

  void consumeMessage() {
    if (message == null) return;
    message = null;
    notifyListeners();
  }

  List<InstalledApp> _sorted(List<InstalledApp> apps) {
    final seen = <String>{};
    final unique = <InstalledApp>[];
    for (final app in apps) {
      if (app.packageName.isEmpty) continue;
      if (!seen.add(app.packageName)) continue;
      unique.add(app);
    }
    unique.sort((a, b) => a.label.compareTo(b.label));
    return unique;
  }
}

String normalizeArabicForSearch(String value) {
  final withoutDiacritics = value
      .replaceAll(RegExp('[\\u064B-\\u065F\\u0670\\u06D6-\\u06ED]'), '')
      .replaceAll('\u0640', '');
  return withoutDiacritics
      .replaceAll('\u0623', '\u0627')
      .replaceAll('\u0625', '\u0627')
      .replaceAll('\u0622', '\u0627')
      .replaceAll('\u0649', '\u064A')
      .replaceAll('\u0629', '\u0647')
      .toLowerCase()
      .trim();
}

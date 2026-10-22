import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/preferences.dart';
import '../platform/bridges.dart';
import 'app_state.dart';

enum FocusPhase { idle, running, paused, completed }

class FocusState extends ChangeNotifier {
  FocusState({required this.appState});

  final AppState appState;

  FocusPhase phase = FocusPhase.idle;
  int remainingMs = 25 * 60 * 1000;
  int totalMs = 25 * 60 * 1000;
  int durationMinutes = 25;
  String sessionTitle = 'الدراسة';
  Set<String> allowedPackages = <String>{};
  List<InstalledApp> installedApps = const <InstalledApp>[];
  bool isLoadingApps = true;
  String? message;

  Timer? _ticker;
  int? _durationOverride;
  String? _titleOverride;

  double get progress {
    if (totalMs <= 0) return 0;
    final elapsed = (totalMs - remainingMs).clamp(0, totalMs);
    return elapsed / totalMs;
  }

  void init({int? initialDurationMinutes, String? initialSessionTitle}) {
    appState.addListener(_onPreferencesChanged);
    final prefs = appState.preferences;
    _applyPreferences(prefs);
    _reconcile(prefs);
    if (initialDurationMinutes != null) {
      final safe = initialDurationMinutes.clamp(5, 180);
      _durationOverride = safe;
      durationMinutes = safe;
      if (phase == FocusPhase.idle) {
        totalMs = safe * 60000;
        remainingMs = totalMs;
      }
      appState.setFocusDuration(safe);
    }
    if (initialSessionTitle != null && initialSessionTitle.trim().isNotEmpty) {
      setSessionTitle(initialSessionTitle);
    }
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) => _tick());
    loadInstalledApps();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    appState.removeListener(_onPreferencesChanged);
    super.dispose();
  }

  void start() {
    final minutes = durationMinutes;
    final endAt = DateTime.now().millisecondsSinceEpoch + minutes * 60000;
    phase = FocusPhase.running;
    remainingMs = minutes * 60000;
    totalMs = minutes * 60000;
    notifyListeners();
    appState.setFocusState(endAt, 0, sessionTitle);
    AlarmBridge.scheduleFocus(DateTime.fromMillisecondsSinceEpoch(endAt));
  }

  void pause() {
    if (phase != FocusPhase.running) return;
    final remaining = remainingMs < 0 ? 0 : remainingMs;
    phase = FocusPhase.paused;
    remainingMs = remaining;
    notifyListeners();
    appState.setFocusState(0, remaining, sessionTitle);
    AlarmBridge.cancelFocus();
  }

  void resume() {
    if (phase != FocusPhase.paused) return;
    final endAt = DateTime.now().millisecondsSinceEpoch + remainingMs;
    phase = FocusPhase.running;
    notifyListeners();
    appState.setFocusState(endAt, 0, sessionTitle);
    AlarmBridge.scheduleFocus(DateTime.fromMillisecondsSinceEpoch(endAt));
  }

  void reset() {
    final minutes = durationMinutes;
    phase = FocusPhase.idle;
    remainingMs = minutes * 60000;
    totalMs = minutes * 60000;
    notifyListeners();
    appState.clearFocusState();
    AlarmBridge.cancelFocus();
  }

  void setDuration(int minutes) {
    final safe = minutes.clamp(5, 180);
    _durationOverride = safe;
    durationMinutes = safe;
    if (phase == FocusPhase.idle) {
      totalMs = safe * 60000;
      remainingMs = totalMs;
    }
    notifyListeners();
    appState.setFocusDuration(safe);
  }

  void setSessionTitle(String title) {
    final clean = _cleanTitle(title);
    _titleOverride = clean;
    sessionTitle = clean;
    final endAt = phase == FocusPhase.running
        ? DateTime.now().millisecondsSinceEpoch + remainingMs
        : 0;
    final remaining = phase == FocusPhase.paused ? remainingMs : 0;
    notifyListeners();
    appState.setFocusState(endAt, remaining, clean);
  }

  void toggleAllowedPackage(String packageName) {
    final updated = Set<String>.from(allowedPackages);
    if (!updated.add(packageName)) {
      updated.remove(packageName);
    }
    allowedPackages = updated;
    notifyListeners();
    appState.setAllowedFocusPackages(updated);
  }

  Future<void> loadInstalledApps() async {
    isLoadingApps = true;
    notifyListeners();
    List<InstalledApp> apps = const <InstalledApp>[];
    try {
      apps = await LauncherBridge.listApps();
    } catch (_) {
      apps = const <InstalledApp>[];
    }
    installedApps = _sorted(apps);
    isLoadingApps = false;
    notifyListeners();
  }

  void consumeMessage() {
    if (message == null) return;
    message = null;
    notifyListeners();
  }

  void _onPreferencesChanged() {
    _applyPreferences(appState.preferences);
    notifyListeners();
  }

  void _applyPreferences(UserPreferences prefs) {
    if (_durationOverride == null ||
        prefs.focusDurationMinutes == _durationOverride) {
      _durationOverride = null;
      durationMinutes = prefs.focusDurationMinutes;
    }
    if (_titleOverride == null || prefs.focusSessionTitle == _titleOverride) {
      _titleOverride = null;
      sessionTitle = prefs.focusSessionTitle;
    }
    allowedPackages = prefs.allowedFocusPackages;
    if (phase == FocusPhase.idle) {
      totalMs = durationMinutes * 60000;
      remainingMs = totalMs;
    }
  }

  void _reconcile(UserPreferences prefs) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (prefs.focusEndAt > now) {
      phase = FocusPhase.running;
      remainingMs = prefs.focusEndAt - now;
      totalMs = durationMinutes * 60000;
    } else if (prefs.focusRemainingMs > 0) {
      phase = FocusPhase.paused;
      remainingMs = prefs.focusRemainingMs;
      totalMs = durationMinutes * 60000;
    } else {
      phase = FocusPhase.idle;
      totalMs = durationMinutes * 60000;
      remainingMs = totalMs;
      if (prefs.focusEndAt != 0) {
        appState.clearFocusState();
      }
    }
  }

  void _tick() {
    if (phase != FocusPhase.running) return;
    final endAt = appState.preferences.focusEndAt;
    final remaining = endAt - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) {
      _completeSession();
      return;
    }
    remainingMs = remaining;
    notifyListeners();
  }

  void _completeSession() {
    phase = FocusPhase.completed;
    remainingMs = 0;
    message = 'أُنجزت جلسة التركيز. أحسنت!';
    notifyListeners();
    appState.clearFocusState();
    AlarmBridge.cancelFocus();
  }

  static String _cleanTitle(String title) {
    final trimmed = title.trim();
    final cut = trimmed.length > 40 ? trimmed.substring(0, 40) : trimmed;
    return cut.isEmpty ? 'التركيز' : cut;
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

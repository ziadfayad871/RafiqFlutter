import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../data/preferences.dart';

class AppState extends ChangeNotifier {
  AppState(this.preferencesRepository);

  final PreferencesRepository preferencesRepository;
  UserPreferences preferences = const UserPreferences();
  bool _loaded = false;

  bool get isLoaded => _loaded;

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  Future<void> load() async {
    preferences = preferencesRepository.current();
    _loaded = true;
    notifyListeners();
  }

  String get themeId => preferences.theme;

  bool get hapticsEnabled => preferences.hapticsEnabled;

  bool get soundsEnabled => preferences.soundsEnabled;

  void click() {
    if (hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    if (soundsEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> setTheme(String theme) async {
    await preferencesRepository.setTheme(theme);
    preferences = preferencesRepository.current();
    notifyListeners();
  }

  Future<void> setDisplayName(String name) async {
    await preferencesRepository.setDisplayName(name);
    preferences = preferencesRepository.current();
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    await preferencesRepository.setLanguage(language);
    preferences = preferencesRepository.current();
    notifyListeners();
  }

  Future<void> setCalculationMethod(String method) async {
    await preferencesRepository.setCalculationMethod(method);
    preferences = preferencesRepository.current();
    notifyListeners();
  }

  Future<void> setPrayerNotifications(bool enabled) async {
    await preferencesRepository.setPrayerNotifications(enabled);
    preferences = preferencesRepository.current();
    notifyListeners();
  }

  Future<void> setSoundsEnabled(bool enabled) async {
    await preferencesRepository.setSoundsEnabled(enabled);
    preferences = preferencesRepository.current();
    notifyListeners();
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    await preferencesRepository.setHapticsEnabled(enabled);
    preferences = preferencesRepository.current();
    notifyListeners();
  }

  Future<void> setFocusDuration(int minutes) async {
    await preferencesRepository.setFocusDuration(minutes);
    preferences = preferencesRepository.current();
    notifyListeners();
  }

  Future<void> setAllowedFocusPackages(Set<String> packages) async {
    await preferencesRepository.setAllowedFocusPackages(packages);
    preferences = preferencesRepository.current();
    notifyListeners();
  }

  Future<void> setManualLocation(ManualCity city) async {
    await preferencesRepository.setManualLocation(city);
    preferences = preferencesRepository.current();
    notifyListeners();
  }

  Future<void> setDetectedLocation(double latitude, double longitude) async {
    await preferencesRepository.setDetectedLocation(latitude, longitude);
    preferences = preferencesRepository.current();
    notifyListeners();
  }

  Future<void> setQuranPosition(int surah, int ayah) async {
    await preferencesRepository.setQuranPosition(surah, ayah);
    preferences = preferencesRepository.current();
    notifyListeners();
  }

  Future<void> setTasksSeeded() async {
    await preferencesRepository.setTasksSeeded();
    preferences = preferencesRepository.current();
    notifyListeners();
  }

  Future<void> setFocusState(int endAt, int remainingMs, String title) async {
    await preferencesRepository.setFocusState(endAt, remainingMs, title);
    preferences = preferencesRepository.current();
    notifyListeners();
  }

  Future<void> clearFocusState() async {
    await preferencesRepository.clearFocusState();
    preferences = preferencesRepository.current();
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this context');
    return scope!.notifier!;
  }

  static AppState read(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<AppScope>();
    final scope = element?.widget as AppScope?;
    assert(scope != null, 'AppScope is missing above this context');
    return scope!.notifier!;
  }
}

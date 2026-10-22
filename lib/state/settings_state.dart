import 'package:flutter/foundation.dart';

import '../data/preferences.dart';
import '../data/prayer_calculator.dart';
import '../platform/bridges.dart';
import '../state/app_state.dart';
import '../util/arabic_formatters.dart';

const Map<String, String> manualCityCountries = <String, String>{
  'cairo': 'مصر',
  'alexandria': 'مصر',
  'giza': 'مصر',
  'mansoura': 'مصر',
  'luxor': 'مصر',
  'aswan': 'مصر',
  'portsaid': 'مصر',
  'suez': 'مصر',
  'riyadh': 'السعودية',
  'jeddah': 'السعودية',
  'makkah': 'السعودية',
  'madinah': 'السعودية',
  'doha': 'قطر',
  'dubai': 'الإمارات',
  'kuwait': 'الكويت',
  'amman': 'الأردن',
  'jerusalem': 'فلسطين',
  'istanbul': 'تركيا',
  'muscat': 'عمان',
  'casablanca': 'المغرب',
  'alger': 'الجزائر',
  'tunis': 'تونس',
  'tripoli': 'ليبيا',
  'khartoum': 'السودان',
  'london': 'المملكة المتحدة',
  'paris': 'فرنسا',
  'berlin': 'ألمانيا',
  'newyork': 'الولايات المتحدة',
  'toronto': 'كندا',
};

String manualCityCountry(String id) => manualCityCountries[id] ?? '';

class SettingsState extends ChangeNotifier {
  SettingsState(this.appState);

  final AppState appState;

  String? _message;
  bool _isClearing = false;
  bool _canScheduleExact = false;
  String? _scheduledAlarmKey;

  String? get message => _message;

  bool get isClearing => _isClearing;

  bool get canScheduleExact => _canScheduleExact;

  void consumeMessage() {
    if (_message == null) return;
    _message = null;
    notifyListeners();
  }

  void _show(String message) {
    _message = message;
    notifyListeners();
  }

  Future<void> setDisplayName(String name) async {
    await appState.setDisplayName(name);
  }

  Future<void> setTheme(String theme) async {
    await appState.setTheme(theme);
  }

  Future<void> setLanguage(String language) async {
    await appState.setLanguage(language);
  }

  Future<void> setSoundsEnabled(bool enabled) async {
    await appState.setSoundsEnabled(enabled);
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    await appState.setHapticsEnabled(enabled);
  }

  Future<void> setFocusDuration(int minutes) async {
    await appState.setFocusDuration(minutes);
  }

  Future<void> setCalculationMethod(CalculationMethod method) async {
    await appState.setCalculationMethod(method.id);
  }

  Future<void> setCity(ManualCity city) async {
    await appState.setManualLocation(city);
    _show('تم تحديث مدينة الحساب إلى ${city.name}');
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await appState.setPrayerNotifications(enabled);
    await _applyPrayerAlarm();
  }

  Future<void> syncPrayerAlarm() async {
    await _applyPrayerAlarm();
  }

  Future<void> _applyPrayerAlarm() async {
    final preferences = appState.preferences;
    final key = '${preferences.prayerNotifications}|'
        '${preferences.calculationMethod}|'
        '${preferences.latitude}|${preferences.longitude}';
    if (key == _scheduledAlarmKey) return;
    _scheduledAlarmKey = key;
    await AlarmBridge.configurePrayer(
      enabled: preferences.prayerNotifications,
      calculationMethod: preferences.calculationMethod,
      latitude: preferences.latitude,
      longitude: preferences.longitude,
    );
  }

  Future<void> showTestPrayerNotification() async {
    final triggerAt = DateTime.now().add(const Duration(seconds: 10));
    await AlarmBridge.schedulePrayer(
      triggerAt: triggerAt,
      prayerName: 'تجريبي',
      prayerTime: formatTime12Hour(triggerAt),
    );
    _show('تم إرسال تنبيه تجريبي');
  }

  Future<void> refreshExactAlarmPermission() async {
    _canScheduleExact = await AlarmBridge.canScheduleExact();
    notifyListeners();
  }

  Future<void> openExactAlarmSettings() async {
    await AlarmBridge.openExactAlarmSettings();
    await refreshExactAlarmPermission();
  }

  Future<void> openAppSettings() async {
    final opened = await LauncherBridge.openAppSettings();
    if (!opened) {
      _show('تعذّر فتح إعدادات النظام');
    }
  }

  Future<void> openHomeSettings() async {
    final opened = await LauncherBridge.openHomeSettings();
    if (!opened) {
      _show('تعذّر فتح إعدادات الشاشة الرئيسية');
    }
  }

  Future<void> openLanguageSettings() async {
    final opened = await LauncherBridge.openLanguageSettings();
    if (!opened) {
      await LauncherBridge.openAppSettings();
    }
  }

  Future<DetectedLocation?> detectLocation() async {
    var granted = await LocationBridge.hasPermission();
    if (!granted) {
      await LocationBridge.requestPermission();
      granted = await LocationBridge.hasPermission();
    }
    if (!granted) {
      _show('لم يُسمح بالوصول إلى الموقع، سنستخدم المدينة اليدوية');
      return null;
    }
    final detected = await LocationBridge.currentLocation();
    if (detected == null) {
      _show('تعذّر تحديد الموقع الآن، سنستخدم المدينة اليدوية');
      return null;
    }
    await appState.setDetectedLocation(detected.latitude, detected.longitude);
    _show('تم الاعتماد على ${detected.city ?? 'موقعك الحالي'}');
    return detected;
  }

  Future<void> resetPersonalData() async {
    _isClearing = true;
    notifyListeners();
    try {
      final repository = appState.preferencesRepository;
      await repository.setTasksJson('[]');
      await repository.setBookmarksJson('[]');
      await repository.clearPersonalizations();
      await repository.clearFocusState();
      await appState.load();
      await AlarmBridge.cancelFocus();
    } finally {
      _isClearing = false;
    }
    _show('تمت إعادة البيانات الشخصية إلى وضعها الافتراضي');
  }
}

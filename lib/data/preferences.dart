import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  const UserPreferences({
    this.displayName = 'رفيق',
    this.theme = 'emerald',
    this.language = 'ar',
    this.calculationMethod = 'egyptian',
    this.locationMode = 'manual',
    this.manualCityId = 'cairo',
    this.latitude = 30.0444,
    this.longitude = 31.2357,
    this.locationLabel = 'القاهرة',
    this.timeZoneId = '',
    this.prayerNotifications = false,
    this.soundsEnabled = true,
    this.hapticsEnabled = true,
    this.focusDurationMinutes = 25,
    this.allowedFocusPackages = const <String>{},
    this.quranSurah = 1,
    this.quranAyah = 1,
    this.tasksSeeded = false,
    this.focusEndAt = 0,
    this.focusRemainingMs = 0,
    this.focusSessionTitle = 'الدراسة',
  });

  final String displayName;
  final String theme;
  final String language;
  final String calculationMethod;
  final String locationMode;
  final String manualCityId;
  final double latitude;
  final double longitude;
  final String locationLabel;
  final String timeZoneId;
  final bool prayerNotifications;
  final bool soundsEnabled;
  final bool hapticsEnabled;
  final int focusDurationMinutes;
  final Set<String> allowedFocusPackages;
  final int quranSurah;
  final int quranAyah;
  final bool tasksSeeded;
  final int focusEndAt;
  final int focusRemainingMs;
  final String focusSessionTitle;

  UserPreferences copyWith({
    String? displayName,
    String? theme,
    String? language,
    String? calculationMethod,
    String? locationMode,
    String? manualCityId,
    double? latitude,
    double? longitude,
    String? locationLabel,
    String? timeZoneId,
    bool? prayerNotifications,
    bool? soundsEnabled,
    bool? hapticsEnabled,
    int? focusDurationMinutes,
    Set<String>? allowedFocusPackages,
    int? quranSurah,
    int? quranAyah,
    bool? tasksSeeded,
    int? focusEndAt,
    int? focusRemainingMs,
    String? focusSessionTitle,
  }) {
    return UserPreferences(
      displayName: displayName ?? this.displayName,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      locationMode: locationMode ?? this.locationMode,
      manualCityId: manualCityId ?? this.manualCityId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationLabel: locationLabel ?? this.locationLabel,
      timeZoneId: timeZoneId ?? this.timeZoneId,
      prayerNotifications: prayerNotifications ?? this.prayerNotifications,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      focusDurationMinutes: focusDurationMinutes ?? this.focusDurationMinutes,
      allowedFocusPackages: allowedFocusPackages ?? this.allowedFocusPackages,
      quranSurah: quranSurah ?? this.quranSurah,
      quranAyah: quranAyah ?? this.quranAyah,
      tasksSeeded: tasksSeeded ?? this.tasksSeeded,
      focusEndAt: focusEndAt ?? this.focusEndAt,
      focusRemainingMs: focusRemainingMs ?? this.focusRemainingMs,
      focusSessionTitle: focusSessionTitle ?? this.focusSessionTitle,
    );
  }
}

class ManualCity {
  const ManualCity({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timeZoneId,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String timeZoneId;
}

const manualCities = <ManualCity>[
  ManualCity(id: 'cairo', name: 'القاهرة', latitude: 30.0444, longitude: 31.2357, timeZoneId: 'Africa/Cairo'),
  ManualCity(id: 'alexandria', name: 'الإسكندرية', latitude: 31.2001, longitude: 29.9187, timeZoneId: 'Africa/Cairo'),
  ManualCity(id: 'giza', name: 'الجيزة', latitude: 30.0444, longitude: 31.2357, timeZoneId: 'Africa/Cairo'),
  ManualCity(id: 'mansoura', name: 'المنصورة', latitude: 31.0409, longitude: 31.3785, timeZoneId: 'Africa/Cairo'),
  ManualCity(id: 'luxor', name: 'الأقصر', latitude: 25.6872, longitude: 32.6396, timeZoneId: 'Africa/Cairo'),
  ManualCity(id: 'aswan', name: 'أسوان', latitude: 24.0889, longitude: 32.8998, timeZoneId: 'Africa/Cairo'),
  ManualCity(id: 'portsaid', name: 'بورسعيد', latitude: 31.2653, longitude: 32.3019, timeZoneId: 'Africa/Cairo'),
  ManualCity(id: 'suez', name: 'السويس', latitude: 29.9668, longitude: 32.5498, timeZoneId: 'Africa/Cairo'),
  ManualCity(id: 'riyadh', name: 'الرياض', latitude: 24.7136, longitude: 46.6753, timeZoneId: 'Asia/Riyadh'),
  ManualCity(id: 'jeddah', name: 'جدة', latitude: 21.4858, longitude: 39.1925, timeZoneId: 'Asia/Riyadh'),
  ManualCity(id: 'makkah', name: 'مكة المكرمة', latitude: 21.3891, longitude: 39.8579, timeZoneId: 'Asia/Riyadh'),
  ManualCity(id: 'madinah', name: 'المدينة المنورة', latitude: 24.5247, longitude: 39.5692, timeZoneId: 'Asia/Riyadh'),
  ManualCity(id: 'doha', name: 'الدوحة', latitude: 25.2854, longitude: 51.5310, timeZoneId: 'Asia/Qatar'),
  ManualCity(id: 'dubai', name: 'دبي', latitude: 25.2048, longitude: 55.2708, timeZoneId: 'Asia/Dubai'),
  ManualCity(id: 'kuwait', name: 'الكويت', latitude: 29.3759, longitude: 47.9774, timeZoneId: 'Asia/Kuwait'),
  ManualCity(id: 'amman', name: 'عمّان', latitude: 31.9539, longitude: 35.9106, timeZoneId: 'Asia/Amman'),
  ManualCity(id: 'jerusalem', name: 'القدس', latitude: 31.7683, longitude: 35.2137, timeZoneId: 'Asia/Hebron'),
  ManualCity(id: 'istanbul', name: 'إسطنبول', latitude: 41.0082, longitude: 28.9784, timeZoneId: 'Europe/Istanbul'),
  ManualCity(id: 'muscat', name: 'مسقط', latitude: 23.5880, longitude: 58.3829, timeZoneId: 'Asia/Muscat'),
  ManualCity(id: 'casablanca', name: 'الدار البيضاء', latitude: 33.5731, longitude: -7.5898, timeZoneId: 'Africa/Casablanca'),
  ManualCity(id: 'alger', name: 'الجزائر', latitude: 36.7538, longitude: 3.0588, timeZoneId: 'Africa/Algiers'),
  ManualCity(id: 'tunis', name: 'تونس', latitude: 36.8065, longitude: 10.1815, timeZoneId: 'Africa/Tunis'),
  ManualCity(id: 'tripoli', name: 'طرابلس', latitude: 32.8872, longitude: 13.1913, timeZoneId: 'Africa/Tripoli'),
  ManualCity(id: 'khartoum', name: 'الخرطوم', latitude: 15.5007, longitude: 32.5599, timeZoneId: 'Africa/Khartoum'),
  ManualCity(id: 'london', name: 'لندن', latitude: 51.5072, longitude: -0.1276, timeZoneId: 'Europe/London'),
  ManualCity(id: 'paris', name: 'باريس', latitude: 48.8566, longitude: 2.3522, timeZoneId: 'Europe/Paris'),
  ManualCity(id: 'berlin', name: 'برلين', latitude: 52.5200, longitude: 13.4050, timeZoneId: 'Europe/Berlin'),
  ManualCity(id: 'newyork', name: 'نيويورك', latitude: 40.7128, longitude: -74.0060, timeZoneId: 'America/New_York'),
  ManualCity(id: 'toronto', name: 'تورنتو', latitude: 43.6532, longitude: -79.3832, timeZoneId: 'America/Toronto'),
];

class PreferencesRepository {
  PreferencesRepository(this._prefs);

  static const _keyDisplayName = 'display_name';
  static const _keyTheme = 'theme';
  static const _keyLanguage = 'language';
  static const _keyCalculationMethod = 'calculation_method';
  static const _keyLocationMode = 'location_mode';
  static const _keyManualCityId = 'manual_city_id';
  static const _keyLatitude = 'latitude_float_bits';
  static const _keyLongitude = 'longitude_float_bits';
  static const _keyLocationLabel = 'location_label';
  static const _keyTimeZone = 'time_zone_id';
  static const _keyPrayerNotifications = 'prayer_notifications';
  static const _keySoundsEnabled = 'sounds_enabled';
  static const _keyHapticsEnabled = 'haptics_enabled';
  static const _keyFocusDuration = 'focus_duration';
  static const _keyAllowedFocusPackages = 'allowed_focus_packages';
  static const _keyQuranSurah = 'quran_surah';
  static const _keyQuranAyah = 'quran_ayah';
  static const _keyTasksSeeded = 'tasks_seeded';
  static const _keyFocusEndAt = 'focus_end_at';
  static const _keyFocusRemainingMs = 'focus_remaining_ms';
  static const _keyFocusSessionTitle = 'focus_session_title';

  final SharedPreferences _prefs;

  static Future<PreferencesRepository> create() async {
    return PreferencesRepository(await SharedPreferences.getInstance());
  }

  UserPreferences current() {
    final zone = DateTime.now().timeZoneName;
    return UserPreferences(
      displayName: _prefs.getString(_keyDisplayName) ?? 'رفيق',
      theme: _prefs.getString(_keyTheme) ?? 'emerald',
      language: _prefs.getString(_keyLanguage) ?? 'ar',
      calculationMethod: _prefs.getString(_keyCalculationMethod) ?? 'egyptian',
      locationMode: _prefs.getString(_keyLocationMode) ?? 'manual',
      manualCityId: _prefs.getString(_keyManualCityId) ?? 'cairo',
      latitude: _prefs.getDouble(_keyLatitude) ?? 30.0444,
      longitude: _prefs.getDouble(_keyLongitude) ?? 31.2357,
      locationLabel: _prefs.getString(_keyLocationLabel) ?? 'القاهرة',
      timeZoneId: _prefs.getString(_keyTimeZone) ?? zone,
      prayerNotifications: _prefs.getBool(_keyPrayerNotifications) ?? false,
      soundsEnabled: _prefs.getBool(_keySoundsEnabled) ?? true,
      hapticsEnabled: _prefs.getBool(_keyHapticsEnabled) ?? true,
      focusDurationMinutes: _prefs.getInt(_keyFocusDuration) ?? 25,
      allowedFocusPackages: (_prefs.getString(_keyAllowedFocusPackages) ?? '')
          .split(',')
          .where((value) => value.isNotEmpty)
          .toSet(),
      quranSurah: _prefs.getInt(_keyQuranSurah) ?? 1,
      quranAyah: _prefs.getInt(_keyQuranAyah) ?? 1,
      tasksSeeded: _prefs.getBool(_keyTasksSeeded) ?? false,
      focusEndAt: _prefs.getInt(_keyFocusEndAt) ?? 0,
      focusRemainingMs: _prefs.getInt(_keyFocusRemainingMs) ?? 0,
      focusSessionTitle: _prefs.getString(_keyFocusSessionTitle) ?? 'الدراسة',
    );
  }

  Future<void> setTheme(String theme) => _prefs.setString(_keyTheme, theme);

  Future<void> setDisplayName(String name) async {
    final trimmed = name.trim();
    await _prefs.setString(
      _keyDisplayName,
      trimmed.isEmpty ? 'رفيق' : trimmed.substring(0, trimmed.length > 40 ? 40 : trimmed.length),
    );
  }

  Future<void> setLanguage(String language) => _prefs.setString(_keyLanguage, language);

  Future<void> setCalculationMethod(String method) =>
      _prefs.setString(_keyCalculationMethod, method);

  Future<void> setPrayerNotifications(bool enabled) =>
      _prefs.setBool(_keyPrayerNotifications, enabled);

  Future<void> setSoundsEnabled(bool enabled) => _prefs.setBool(_keySoundsEnabled, enabled);

  Future<void> setHapticsEnabled(bool enabled) =>
      _prefs.setBool(_keyHapticsEnabled, enabled);

  Future<void> setFocusDuration(int minutes) =>
      _prefs.setInt(_keyFocusDuration, minutes.clamp(5, 180));

  Future<void> setAllowedFocusPackages(Set<String> packages) =>
      _prefs.setString(_keyAllowedFocusPackages, packages.join(','));

  Future<void> setManualLocation(ManualCity city) async {
    await _prefs.setString(_keyLocationMode, 'manual');
    await _prefs.setString(_keyManualCityId, city.id);
    await _prefs.setDouble(_keyLatitude, city.latitude);
    await _prefs.setDouble(_keyLongitude, city.longitude);
    await _prefs.setString(_keyLocationLabel, city.name);
    await _prefs.setString(_keyTimeZone, city.timeZoneId);
  }

  Future<void> setDetectedLocation(double latitude, double longitude) async {
    await _prefs.setString(_keyLocationMode, 'auto');
    await _prefs.setDouble(_keyLatitude, latitude);
    await _prefs.setDouble(_keyLongitude, longitude);
    await _prefs.setString(_keyLocationLabel, 'موقعك الحالي');
    await _prefs.setString(_keyTimeZone, DateTime.now().timeZoneName);
  }

  Future<void> setQuranPosition(int surah, int ayah) async {
    await _prefs.setInt(_keyQuranSurah, surah.clamp(1, 114));
    await _prefs.setInt(_keyQuranAyah, ayah < 1 ? 1 : ayah);
  }

  Future<void> setTasksSeeded() => _prefs.setBool(_keyTasksSeeded, true);

  Future<void> setFocusState(int endAt, int remainingMs, String title) async {
    await _prefs.setInt(_keyFocusEndAt, endAt);
    await _prefs.setInt(_keyFocusRemainingMs, remainingMs);
    await _prefs.setString(_keyFocusSessionTitle, title);
  }

  Future<void> clearFocusState() async {
    await _prefs.setInt(_keyFocusEndAt, 0);
    await _prefs.setInt(_keyFocusRemainingMs, 0);
  }

  Future<void> clearPersonalizations() async {
    await _prefs.remove(_keyDisplayName);
    await _prefs.remove(_keyQuranSurah);
    await _prefs.remove(_keyQuranAyah);
    await _prefs.remove(_keyFocusSessionTitle);
    await _prefs.setBool(_keyTasksSeeded, true);
  }

  Future<void> setTasksJson(String json) => _prefs.setString('tasks_json', json);

  String tasksJson() => _prefs.getString('tasks_json') ?? '[]';

  Future<void> setBookmarksJson(String json) => _prefs.setString('bookmarks_json', json);

  String bookmarksJson() => _prefs.getString('bookmarks_json') ?? '[]';

  static String encodeSet(Set<String> values) => jsonEncode(values.toList());

  static Set<String> decodeSet(String raw) {
    if (raw.isEmpty) return <String>{};
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded.map((e) => '$e').toSet();
    return <String>{};
  }
}

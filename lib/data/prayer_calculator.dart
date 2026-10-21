import 'dart:math' as math;

enum CalculationMethod {
  egyptian('egyptian', 'الهيئة المصرية العامة للمساحة', 19.5, 17.5),
  ummAlQura('umm_al_qura', 'أم القرى', 18.5, null, ishaIntervalMinutes: 90),
  mwl('mwl', 'رابطة العالم الإسلامي', 18.0, 17.0),
  karachi('karachi', 'جامعة العلوم الإسلامية بكراتشي', 18.0, 18.0),
  isna('isna', 'الجمعية الإسلامية لأمريكا الشمالية', 15.0, 15.0),
  dubai('dubai', 'دائرة الشؤون الإسلامية بدبي', 18.2, 18.2),
  kuwait('kuwait', 'وزارة الأوقاف الكويتية', 18.0, 17.5),
  qatar('qatar', 'وزارة الأوقاف القطرية', 18.0, null, ishaIntervalMinutes: 90),
  singapore('singapore', 'مجلس علماء سنغافورة', 20.0, 18.0),
  turkey('turkey', 'رئاسة الشؤون الدينية التركية', 18.0, 18.0),
  morocco('morocco', 'وزارة الأوقاف المغربية', 19.0, 17.0);

  const CalculationMethod(
    this.id,
    this.arabicName,
    this.fajrAngle,
    this.ishaAngle, {
    this.ishaIntervalMinutes,
  });

  final String id;
  final String arabicName;
  final double fajrAngle;
  final double? ishaAngle;
  final int? ishaIntervalMinutes;

  static CalculationMethod fromId(String id) =>
      values.firstWhere((m) => m.id == id, orElse: () => CalculationMethod.egyptian);
}

enum PrayerId {
  fajr('الفجر'),
  dhuhr('الظهر'),
  asr('العصر'),
  maghrib('المغرب'),
  isha('العشاء');

  const PrayerId(this.arabicName);

  final String arabicName;
}

class PrayerEntry {
  const PrayerEntry(this.id, this.time);

  final PrayerId id;
  final DateTime time;

  String get name => id.arabicName;

  String get formattedTime =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

class PrayerTimes {
  const PrayerTimes({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.highLatitudeApproximation = false,
  });

  final DateTime date;
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final bool highLatitudeApproximation;

  List<PrayerEntry> get prayers => [
        PrayerEntry(PrayerId.fajr, fajr),
        PrayerEntry(PrayerId.dhuhr, dhuhr),
        PrayerEntry(PrayerId.asr, asr),
        PrayerEntry(PrayerId.maghrib, maghrib),
        PrayerEntry(PrayerId.isha, isha),
      ];
}

class NextPrayerInfo {
  const NextPrayerInfo({
    required this.prayer,
    required this.previous,
    required this.tomorrow,
    required this.remaining,
    required this.progress,
  });

  final PrayerEntry prayer;
  final PrayerEntry previous;
  final bool tomorrow;
  final Duration remaining;
  final double progress;
}

class PrayerCalculator {
  static const double _sunriseAngle = 0.833;

  static PrayerTimes calculate({
    required DateTime date,
    required double latitude,
    required double longitude,
    required Duration offset,
    required CalculationMethod method,
  }) {
    final lat = latitude.clamp(-89.5, 89.5).toDouble();
    final lng = longitude.clamp(-180.0, 180.0).toDouble();
    final jd = _julianDate(date);
    final tzOffset = offset.inSeconds / 3600.0;
    final adjust = tzOffset - lng / 15.0;

    final dhuhrSolar = _midDay(jd);
    final sunriseSolar = _sunAngleTime(jd, lat, _sunriseAngle, 0.5, true);
    final sunsetSolar = _sunAngleTime(jd, lat, _sunriseAngle, 0.5, false);
    var fajrSolar = _sunAngleTime(jd, lat, method.fajrAngle, 0.5, true);
    var ishaSolar = method.ishaAngle != null
        ? _sunAngleTime(jd, lat, method.ishaAngle!, 0.5, false)
        : sunsetSolar + (method.ishaIntervalMinutes ?? 90) / 60.0;
    final asrSolar = _asrTime(jd, lat, 0.5, 1);

    var approximate = false;
    final nightLength = _fixHour(sunriseSolar - sunsetSolar + 24.0);
    if (fajrSolar.isNaN) {
      fajrSolar = sunriseSolar - nightLength / 2.0;
      approximate = true;
    }
    if (ishaSolar.isNaN) {
      ishaSolar = sunsetSolar + nightLength / 2.0;
      approximate = true;
    }
    if (lat.abs() >= 48.0) {
      final validFajr = _sunAngleTime(jd, lat, method.fajrAngle, 0.5, true);
      final validIsha = method.ishaAngle != null
          ? _sunAngleTime(jd, lat, method.ishaAngle!, 0.5, false)
          : double.nan;
      if (validFajr.isNaN || validIsha.isNaN) {
        approximate = true;
      }
    }

    return PrayerTimes(
      date: DateTime(date.year, date.month, date.day),
      fajr: _toLocal(date, fajrSolar + adjust),
      sunrise: _toLocal(date, sunriseSolar + adjust),
      dhuhr: _toLocal(date, dhuhrSolar + adjust),
      asr: _toLocal(date, asrSolar + adjust),
      maghrib: _toLocal(date, sunsetSolar + adjust),
      isha: _toLocal(date, ishaSolar + adjust),
      highLatitudeApproximation: approximate,
    );
  }

  static NextPrayerInfo nextPrayer({
    required PrayerTimes today,
    required DateTime now,
    required PrayerTimes tomorrow,
    PrayerTimes? yesterday,
  }) {
    PrayerEntry? todayNext;
    for (final entry in today.prayers) {
      if (entry.time.isAfter(now)) {
        todayNext = entry;
        break;
      }
    }
    final next = todayNext ?? tomorrow.prayers.first;
    PrayerEntry previous;
    if (todayNext != null) {
      PrayerEntry? candidate;
      for (final entry in today.prayers) {
        if (!entry.time.isAfter(now)) candidate = entry;
      }
      previous = candidate ?? yesterday?.prayers.last ?? today.prayers.first;
    } else {
      previous = today.prayers.last;
    }
    final intervalSeconds =
        math.max(1, next.time.difference(previous.time).inSeconds);
    var elapsed = now.difference(previous.time).inSeconds;
    if (elapsed < 0) elapsed = 0;
    if (elapsed > intervalSeconds) elapsed = intervalSeconds;
    var remaining = next.time.difference(now);
    if (remaining.isNegative) remaining = Duration.zero;
    return NextPrayerInfo(
      prayer: next,
      previous: previous,
      tomorrow: todayNext == null,
      remaining: remaining,
      progress: (elapsed / intervalSeconds).clamp(0.0, 1.0),
    );
  }

  static DateTime _toLocal(DateTime date, double solarTime) {
    final normalized = _fixHour(solarTime);
    final totalMinutes = (normalized * 60.0).round();
    return DateTime(date.year, date.month, date.day).add(Duration(minutes: totalMinutes));
  }

  static double _julianDate(DateTime date) {
    var year = date.year;
    var month = date.month;
    final day = date.day;
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final a = (year / 100.0).floor();
    final b = 2 - a + (a / 4.0).floor();
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524.5;
  }

  static double _midDay(double jd) {
    final position = _sunPosition(jd);
    return _fixHour(12.0 - position.equationOfTime);
  }

  static _SunPosition _sunPosition(double jd) {
    final d = jd - 2451545.0;
    final g = _fixAngle(357.529 + 0.98560028 * d);
    final q = _fixAngle(280.459 + 0.98564736 * d);
    final l = _fixAngle(
      q + 1.915 * math.sin(_rad(g)) + 0.020 * math.sin(_rad(2.0 * g)),
    );
    final e = 23.439 - 0.00000036 * d;
    final ra = _fixHour(
      math.atan2(
            math.cos(_rad(e)) * math.sin(_rad(l)),
            math.cos(_rad(l)),
          ) *
          180 /
          math.pi /
          15,
    );
    final eqt = q / 15.0 - ra;
    final decl = math.asin(math.sin(_rad(e)) * math.sin(_rad(l))) * 180 / math.pi;
    return _SunPosition(declination: decl, equationOfTime: eqt);
  }

  static double _sunAngleTime(
    double jd,
    double lat,
    double angle,
    double time,
    bool beforeNoon,
  ) {
    final declination = _sunPosition(jd + time).declination;
    final noon = _midDay(jd + time);
    final denominator = math.cos(_rad(declination)) * math.cos(_rad(lat));
    if (denominator.abs() < 1e-9) return double.nan;
    final raw = (-math.sin(_rad(angle)) -
            math.sin(_rad(declination)) * math.sin(_rad(lat))) /
        denominator;
    if (raw.isNaN || raw < -1.0 || raw > 1.0) return double.nan;
    final t = math.acos(raw) * 180 / math.pi / 15.0;
    return noon + (beforeNoon ? -t : t);
  }

  static double _asrTime(double jd, double lat, double time, int factor) {
    final declination = _sunPosition(jd + time).declination;
    final angle = -_arccot(factor + math.tan(_rad((lat - declination).abs())));
    return _sunAngleTime(jd, lat, angle, time, false);
  }

  static double _arccot(double x) => math.atan(1.0 / x) * 180 / math.pi;

  static double _fixAngle(double angle) => angle - 360.0 * (angle / 360.0).floor();

  static double _fixHour(double hour) => hour - 24.0 * (hour / 24.0).floor();

  static double _rad(double degrees) => degrees * math.pi / 180.0;
}

class _SunPosition {
  const _SunPosition({required this.declination, required this.equationOfTime});

  final double declination;
  final double equationOfTime;
}

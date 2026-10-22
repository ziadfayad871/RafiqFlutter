import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/prayer_calculator.dart';

class PrayerState extends ChangeNotifier {
  PrayerState({
    this.latitude = 30.0444,
    this.longitude = 31.2357,
    this.method = CalculationMethod.egyptian,
    this.locationLabel = 'القاهرة',
  });

  double latitude;
  double longitude;
  CalculationMethod method;
  String locationLabel;

  DateTime now = DateTime.now();
  PrayerTimes? today;
  PrayerTimes? tomorrow;
  PrayerTimes? yesterday;
  NextPrayerInfo? next;

  Timer? _timer;

  void start() {
    refresh();
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  void update({
    double? latitude,
    double? longitude,
    CalculationMethod? method,
    String? locationLabel,
  }) {
    this.latitude = latitude ?? this.latitude;
    this.longitude = longitude ?? this.longitude;
    this.method = method ?? this.method;
    this.locationLabel = locationLabel ?? this.locationLabel;
    refresh();
  }

  void refresh() {
    final current = DateTime.now();
    final offset = DateTime(current.year, current.month, current.day, 12).timeZoneOffset;
    final todayTimes = PrayerCalculator.calculate(
      date: current,
      latitude: latitude,
      longitude: longitude,
      offset: offset,
      method: method,
    );
    final tomorrowTimes = PrayerCalculator.calculate(
      date: current.add(const Duration(days: 1)),
      latitude: latitude,
      longitude: longitude,
      offset: offset,
      method: method,
    );
    final yesterdayTimes = PrayerCalculator.calculate(
      date: current.subtract(const Duration(days: 1)),
      latitude: latitude,
      longitude: longitude,
      offset: offset,
      method: method,
    );
    final info = PrayerCalculator.nextPrayer(
      today: todayTimes,
      now: current,
      tomorrow: tomorrowTimes,
      yesterday: yesterdayTimes,
    );
    now = current;
    today = todayTimes;
    tomorrow = tomorrowTimes;
    yesterday = yesterdayTimes;
    next = info;
    notifyListeners();
  }
}

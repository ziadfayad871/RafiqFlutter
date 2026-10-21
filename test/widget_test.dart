import 'package:flutter_test/flutter_test.dart';

import 'package:rafiqflutter/data/prayer_calculator.dart';
import 'package:rafiqflutter/main.dart';

void main() {
  test('cairo prayer times match reference values', () {
    final offset = const Duration(hours: 3);
    final times = PrayerCalculator.calculate(
      date: DateTime(2026, 10, 20),
      latitude: 30.0444,
      longitude: 31.2357,
      offset: offset,
      method: CalculationMethod.egyptian,
    );
    expect(times.fajr.hour, 5);
    expect(times.fajr.minute, 33);
    expect(times.dhuhr.hour, 12);
    expect(times.dhuhr.minute, 40);
    expect(times.maghrib.hour, 18);
    expect(times.isha.hour, 19);
  });

  test('next prayer before fajr is fajr with isha as previous', () {
    final offset = const Duration(hours: 3);
    final today = PrayerCalculator.calculate(
      date: DateTime(2026, 10, 19),
      latitude: 30.0444,
      longitude: 31.2357,
      offset: offset,
      method: CalculationMethod.egyptian,
    );
    final tomorrow = PrayerCalculator.calculate(
      date: DateTime(2026, 10, 20),
      latitude: 30.0444,
      longitude: 31.2357,
      offset: offset,
      method: CalculationMethod.egyptian,
    );
    final info = PrayerCalculator.nextPrayer(
      today: today,
      now: DateTime(2026, 10, 19, 0, 30),
      tomorrow: tomorrow,
      yesterday: today,
    );
    expect(info.prayer.id, PrayerId.fajr);
    expect(info.previous.id, PrayerId.isha);
    expect(info.tomorrow, isFalse);
  });

  testWidgets('app renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const RafiqApp());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('رفيق'), findsWidgets);
  });
}

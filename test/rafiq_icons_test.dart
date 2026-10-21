import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rafiqflutter/widgets/rafiq_icons.dart';

void main() {
  testWidgets('every RafiqIcon renders without exceptions', (
    WidgetTester tester,
  ) async {
    expect(RafiqIcons.values, isNotEmpty);

    for (final icon in RafiqIcons.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: RafiqIcon(icon))),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('every RafiqIcon renders at a custom size and color', (
    WidgetTester tester,
  ) async {
    for (final icon in RafiqIcons.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RafiqIcon(icon, size: 48, color: Colors.red),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });

  test('viewBox size is 24 for every icon', () {
    for (final icon in RafiqIcons.values) {
      expect(icon.viewBoxSize, 24);
      expect(icon.pathData, isNotEmpty);
    }
  });
}

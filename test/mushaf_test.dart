import 'package:flutter_test/flutter_test.dart';

import 'package:rafiqflutter/data/mushaf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mushaf page mapping matches standard 604-page layout', () async {
    final data = await MushafData.load();
    expect(data.pageCount, 604);
    expect(data.ayahCount, 6236);

    expect(data.pageOf(1, 1), 1);
    expect(data.pageOf(1, 7), 1);
    expect(data.pageOf(2, 1), 2);
    expect(data.pageOf(2, 5), 2);
    expect(data.pageOf(2, 6), 3);
    expect(data.pageOf(2, 282), 48);
    expect(data.pageOf(114, 6), 604);

    final fatihaPage = data.ayahsOnPage(1);
    expect(fatihaPage.length, 7);
    expect(fatihaPage.first.surah, 1);
    expect(fatihaPage.last.ayah, 7);

    expect(data.headerSurah(2), 2);
    expect(data.headerSurah(21), 2);
    expect(data.lastAyahOf(2).surah, 2);
    expect(data.lastAyahOf(2).ayah, 5);
  });
}

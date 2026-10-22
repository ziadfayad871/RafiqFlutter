# رفيق · RAFIQ — Flutter

النسخة **Flutter** من مشغّل رفيق الإسلامي: نفس التصميم ونفس المميزات، بكود واحد وواجهة سلسة.

> النسخة الأصلية بـ Kotlin + Compose: [ziadfayad871/Rafiq](https://github.com/ziadfayad871/Rafiq)

## التحميل والتثبيت

- **[رفيق v1.0.0 (Flutter)](https://github.com/ziadfayad871/RafiqFlutter/releases/tag/v1.0.0)** — `rafiq-flutter-v1.0.0.apk` (51 MB)

خطوات التثبيت:
1. نزّل الـ APK من صفحة الإصدار.
2. فعّل **تثبيت التطبيقات من مصادر غير معروفة**.
3. ثبّت الـ APK وافتح **رفيق**.
4. لتثبيته كشاشة بداية: إعدادات النظام ← الواجهة الافتراضية ← **رفيق**.

> موقّع بمفتاح تصحيح (debug key) لأنه إصدار تجريبي.

## المميزات

- **الرئيسية**: ساعة حيّة، تاريخ ميلادي/هجري، مشهد المسجد عند الفجر، بطاقة الصلاة القادمة مع العدّ التنازلي، اختصارات العبادات، والدوك السفلي.
- **الصلاة**: ١١ طريقة حساب و٣٠ مدينة يدوية وتحديد تلقائي للموقع، حلقة عدّ تنازلي، تنبيهات دقيقة مع إعادة جدولة بعد الريبوت.
- **القرآن**: ١١٤ سورة (٦٢٣٦ آية) بنص عثماني وترجمة، فهرس، علامات مرجعية، تلاوة مشاري العفاسي بانتقال تلقائي.
- **الأذكار**: الصباح والمساء والنوم والمتنوعة، بعدّاد لكل ذكر مع تصفير.
- **المهام** و**التركيز** (جلسات بعدّ تنازلي + تطبيقات مسموحة).
- **المساعد**: إجابات موثوقة محليًا، TTS، إدخال صوتي، وإنشاء مهام/جلسات بالأوامر.
- **الإعدادات**: ثلاث سمات، اسم، تنبيهات، صوت واهتزاز، لغة، إعادة ضبط.

## البنية

```
lib/
├── main.dart / app.dart        نقطة الدخول + التنقل + الشريط السفلي
├── data/                       quran · adhkar · prayer_calculator · preferences · tasks · assistant
├── platform/bridges.dart       MethodChannels للأندرويد
├── state/                      AppState · PrayerState · QuranState · AdhkarState · TasksState …
├── screens/                    home · prayer · quran · adhkar · focus · tasks · assistant · apps · settings
├── theme/                      palette · typography · rafiq_theme
└── widgets/                    background · bottom_bar · components · top_bar · rafiq_icons · dawn_mosque_scene

android/app/src/main/kotlin/    القنوات الأصلية: launcher · alarms · notifications · location · speech
```

## البناء

```bash
flutter pub get
flutter build apk --release
# الناتج: build/app/outputs/flutter-apk/app-release.apk
```

يتطلب: Flutter 3.47+ · JDK 17+ · Android SDK 36 · minSdk 26.

## ملاحظات

- **أندرويد ٧+** (API 26).
- الإشعارات الدقيقة تحتاج إذن «المنبّهات الدقيقة» من إعدادات النظام.
- iOS غير مدعوم كـ launcher (آبل لا تسمح باستبدال شاشة البداية) — الكود قابل للتوسّع لنسخة iOS مرافقة.

## الرخص

الكود مفتوح المصدر. الخطوط: [Amiri](https://fonts.google.com/specimen/Amiri) و[Tajawal](https://fonts.google.com/specimen/Tajawal) — رخصة SIL OFL. تسجيل الأذان: «The Adhan — Muslim Call to Prayer» بأداء Aaqib Azeez، مرفوع بواسطة Atcovi على [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:The_Adhan_-_Muslim_Call_to_Prayer_-_Aaqib_Azeez.mp3) تحت رخصة [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

String toArabicDigits(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final code = rune - 0x30;
    if (code >= 0 && code <= 9) {
      buffer.write(_arabicDigits[code]);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

const _dayNames = [
  'الأحد',
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
];

const _gregorianMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

const _hijriMonths = [
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الآخر',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];

String formatGregorianDate(DateTime date) {
  final day = _dayNames[date.weekday % 7];
  return '$day ${date.day} ${_gregorianMonths[date.month - 1]} ${date.year}';
}

String formatHijriDate(DateTime date) {
  final hijri = _toHijri(date);
  return '${hijri.day} ${_hijriMonths[hijri.month - 1]} ${hijri.year} هـ';
}

String formatTime12Hour(DateTime time) {
  final hour = time.hour == 0
      ? 12
      : (time.hour > 12 ? time.hour - 12 : time.hour);
  final suffix = time.hour < 12 ? 'ص' : 'م';
  return '$hour:${time.minute.toString().padLeft(2, '0')} $suffix';
}

String formatCountdown(Duration duration) {
  final totalMinutes = duration.inMinutes < 0 ? 0 : duration.inMinutes;
  if (totalMinutes < 1) return 'أقل من دقيقة';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours > 0 && minutes > 0) {
    return 'تبقى $hours ساعات و$minutes دقيقة';
  }
  if (hours > 0) return 'تبقى $hours ساعات';
  return 'تبقى $minutes دقيقة';
}

String formatCountdownShort(Duration duration) {
  final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

class _HijriDate {
  const _HijriDate(this.day, this.month, this.year);

  final int day;
  final int month;
  final int year;
}

_HijriDate _toHijri(DateTime date) {
  final gy = date.year;
  final gm = date.month;
  final gd = date.day;
  late int jd;
  if (gy > 1582 ||
      (gy == 1582 && gm > 10) ||
      (gy == 1582 && gm == 10 && gd > 14)) {
    jd = ((1461 * (gy + 4800 + ((gm - 14) ~/ 12)) ~/ 4) +
            ((367 * (gm - 2 - 12 * ((gm - 14) ~/ 12))) ~/ 12) -
            ((3 * ((gy + 4900 + ((gm - 14) ~/ 12)) ~/ 100)) ~/ 4) +
            gd -
            32075)
        .floor();
  } else {
    jd = (367 * gy -
            ((7 * (gy + 5001 + ((gm - 9) ~/ 7))) ~/ 4) +
            ((275 * gm) ~/ 9) +
            gd +
            1729777)
        .floor();
  }
  var l = jd - 1948440 + 10632;
  final n = ((l - 1) ~/ 10631);
  l = l - 10631 * n + 354;
  final j = (((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719)) +
      ((l ~/ 5670) * ((43 * l) ~/ 15238));
  l = l - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
      (j ~/ 16) * ((15238 * j) ~/ 43) +
      29;
  final month = ((24 * l) ~/ 709);
  final day = l - ((709 * month) ~/ 24);
  final year = 30 * n + j - 30;
  return _HijriDate(day, month, year);
}

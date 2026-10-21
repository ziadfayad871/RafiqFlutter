import 'dart:math' as math;

import 'package:flutter/material.dart';

class RafiqIconData {
  const RafiqIconData(this.pathData, this.viewBoxSize, {this.filled = false});

  final String pathData;
  final double viewBoxSize;
  final bool filled;
}

class RafiqIcons {
  static const home = RafiqIconData(
    'M3.2 10.7L12 3.5L20.8 10.7M5.5 9.1V20.2H18.5V9.1M9.6 20.2V14.3H14.4V20.2',
    24,
  );

  static const mosque = RafiqIconData(
    'M12 2.7C10.1 4.7 8.2 6 8.2 9.1H15.8C15.8 6 13.9 4.7 12 2.7Z'
    'M4.2 20.8V9.7C4.2 8.2 5 7.4 6 6.8'
    'M19.8 20.8V9.7C19.8 8.2 19 7.4 18 6.8'
    'M7.8 20.8V10.6H16.2V20.8'
    'M10.3 20.8V16.6C10.3 15.7 11.1 15 12 15C12.9 15 13.7 15.7 13.7 16.6V20.8'
    'M3 20.8H21',
    24,
  );

  static const bookOpen = RafiqIconData(
    'M3 5.3C5.6 4.1 9 4.2 12 6.1C15 4.2 18.4 4.1 21 5.3V18.7'
    'C18.4 17.5 15 17.7 12 19.7C9 17.7 5.6 17.5 3 18.7Z'
    'M12 6.1V19.7',
    24,
  );

  static const quranBook = RafiqIconData(
    'M4.2 4.3C6.3 3.4 9.2 3.6 12 5.3C14.8 3.6 17.7 3.4 19.8 4.3V18.7'
    'C17.7 17.9 14.8 18.1 12 20C9.2 18.1 6.3 17.9 4.2 18.7Z'
    'M12 5.3V20'
    'M12 8.4C10.7 8.4 9.7 9.3 9.5 10.5'
    'M12 13.3C13.6 12.2 15.4 10.8 15.2 9.5C15.1 8.7 14.4 8.2 13.7 8.4',
    24,
  );

  static const prayerBeads = RafiqIconData(
    'M12 2.7C7.2 2.7 3.4 6.5 3.4 11.2C3.4 14.6 5.5 17.4 8.6 18.7'
    'M15.4 18.7C18.4 17.3 20.6 14.5 20.6 11.2C20.6 6.5 16.8 2.7 12 2.7'
    'M9.2 20.4C10.3 19.5 11.1 19 12 19C12.9 19 13.7 19.5 14.8 20.4'
    'M12 20.2V22.3'
    'M9.1 3.8C10.5 5.9 12 6.9 12 9.4C12 6.9 13.5 5.9 14.9 3.8',
    24,
  );

  static const tasbih = prayerBeads;

  static const focus = RafiqIconData(
    'M12 3C7 3 3 7 3 12C3 17 7 21 12 21C17 21 21 17 21 12C21 7 17 3 12 3Z'
    'M12 7.3C9.4 7.3 7.3 9.4 7.3 12C7.3 14.6 9.4 16.7 12 16.7'
    'C14.6 16.7 16.7 14.6 16.7 12C16.7 9.4 14.6 7.3 12 7.3Z'
    'M12 10.2C11 10.2 10.2 11 10.2 12C10.2 13 11 13.8 12 13.8'
    'C13 13.8 13.8 13 13.8 12C13.8 11 13 10.2 12 10.2Z',
    24,
  );

  static const tasks = RafiqIconData(
    'M5 3.8H19C19.6 3.8 20 4.2 20 4.8V19.2C20 19.8 19.6 20.2 19 20.2H5'
    'C4.4 20.2 4 19.8 4 19.2V4.8C4 4.2 4.4 3.8 5 3.8Z'
    'M7.5 8.5L9.2 10.2L12 7.4'
    'M14.3 9H17'
    'M7.5 14.2L9.2 15.9L12 13.1'
    'M14.3 14.7H17',
    24,
  );

  static const sparkle = RafiqIconData(
    'M12 2.3L13.5 8.8L20 10.4L13.5 12L12 18.5L10.5 12L4 10.4L10.5 8.8Z'
    'M18.5 15.3L19.1 17.7L21.5 18.3L19.1 18.9L18.5 21.3L17.9 18.9L15.5 18.3L17.9 17.7Z'
    'M5.1 4.8L5.6 6.8L7.6 7.3L5.6 7.8L5.1 9.8L4.6 7.8L2.6 7.3L4.6 6.8Z',
    24,
    filled: true,
  );

  static const sun = RafiqIconData(
    'M12 7.2C9.4 7.2 7.2 9.4 7.2 12C7.2 14.6 9.4 16.8 12 16.8'
    'C14.6 16.8 16.8 14.6 16.8 12C16.8 9.4 14.6 7.2 12 7.2Z'
    'M12 2.2V4.3'
    'M12 19.7V21.8'
    'M2.2 12H4.3'
    'M19.7 12H21.8'
    'M5.1 5.1L6.6 6.6'
    'M17.4 17.4L18.9 18.9'
    'M18.9 5.1L17.4 6.6'
    'M6.6 17.4L5.1 18.9',
    24,
  );

  static const moon = RafiqIconData(
    'M20.2 15.2C18.9 15.8 17.4 16.1 15.8 16.1C10.4 16.1 6 11.7 6 6.3'
    'C6 5.4 6.1 4.5 6.4 3.6C3.8 5.2 2 8.1 2 11.4C2 16.7 6.3 21 11.6 21'
    'C15 21 17.9 19.1 19.5 16.4Z'
    'M18.7 5.1L19.4 7.2L21.5 7.9L19.4 8.6L18.7 10.7L18 8.6L15.9 7.9L18 7.2Z',
    24,
    filled: true,
  );

  static const bed = RafiqIconData(
    'M2.8 18.7V7.2'
    'M4.6 14H20V18.7'
    'M4.6 18.7V14'
    'M4.6 11.6C4.6 10.3 5.7 9.3 7 9.3H10.4C11.7 9.3 12.8 10.3 12.8 11.6V14'
    'M12.8 14V9.9C12.8 8.9 13.6 8.1 14.6 8.1H18.2C19.2 8.1 20 8.9 20 9.9V14'
    'M2.8 18.7H21.2',
    24,
  );

  static const mic = RafiqIconData(
    'M12 3C10.3 3 9 4.3 9 6V12C9 13.7 10.3 15 12 15C13.7 15 15 13.7 15 12V6'
    'C15 4.3 13.7 3 12 3Z'
    'M5.8 11.2C5.8 14.6 8.6 17.3 12 17.3C15.4 17.3 18.2 14.6 18.2 11.2'
    'M12 17.3V21'
    'M9 21H15',
    24,
  );

  static const play = RafiqIconData('M8 5.3L19 12L8 18.7Z', 24, filled: true);

  static const pause = RafiqIconData(
    'M7 5H9.7V19H7Z'
    'M14.3 5H17V19H14.3Z',
    24,
    filled: true,
  );

  static const next = RafiqIconData(
    'M4 5.5L11 12L4 18.5Z'
    'M12 5.5L19 12L12 18.5Z',
    24,
    filled: true,
  );

  static const previous = RafiqIconData(
    'M20 5.5L13 12L20 18.5Z'
    'M12 5.5L5 12L12 18.5Z',
    24,
    filled: true,
  );

  static const bookmark = RafiqIconData('M6 3.7H18V21L12 17.1L6 21Z', 24);

  static const bookmarkFilled = RafiqIconData(
    'M6 3.7H18V21L12 17.1L6 21Z',
    24,
    filled: true,
  );

  static const search = RafiqIconData(
    'M10.7 3.7C6.8 3.7 3.7 6.8 3.7 10.7C3.7 14.6 6.8 17.7 10.7 17.7'
    'C14.6 17.7 17.7 14.6 17.7 10.7C17.7 6.8 14.6 3.7 10.7 3.7Z'
    'M15.5 15.5L20.3 20.3',
    24,
  );

  static const arrowLeft = RafiqIconData(
    'M19.5 12H4.5'
    'M10.4 5.8L4.3 12L10.4 18.2',
    24,
  );

  static const chevronLeft = RafiqIconData('M14.8 5.3L8.2 12L14.8 18.7', 24);

  static const chevronDown = RafiqIconData('M5.3 9.2L12 15.8L18.7 9.2', 24);

  static const location = RafiqIconData(
    'M12 21C16 16.8 19 13.1 19 9.3C19 5.4 15.9 3 12 3C8.1 3 5 5.4 5 9.3'
    'C5 13.1 8 16.8 12 21Z'
    'M12 7C10.6 7 9.5 8.1 9.5 9.5C9.5 10.9 10.6 12 12 12C13.4 12 14.5 10.9 14.5 9.5'
    'C14.5 8.1 13.4 7 12 7Z',
    24,
  );

  static const settings = RafiqIconData(
    'M12 8.2C9.9 8.2 8.2 9.9 8.2 12C8.2 14.1 9.9 15.8 12 15.8'
    'C14.1 15.8 15.8 14.1 15.8 12C15.8 9.9 14.1 8.2 12 8.2Z'
    'M19.4 13.4C19.5 12.9 19.5 12.4 19.4 11.9L21.2 10.5L19.4 7.3L17.2 8'
    'C16.5 7.5 15.8 7.1 15 6.9L14.7 4.5H9.3L9 6.9C8.2 7.1 7.5 7.5 6.8 8'
    'L4.6 7.3L2.8 10.5L4.6 11.9C4.5 12.4 4.5 12.8 4.6 13.3L2.8 14.7L4.6 17.9'
    'L6.8 17.2C7.5 17.7 8.2 18.1 9 18.3L9.3 20.7H14.7L15 18.3'
    'C15.8 18.1 16.6 17.7 17.2 17.2L19.4 17.9L21.2 14.7Z',
    24,
  );

  static const bell = RafiqIconData(
    'M6.2 9.3C6.2 6.1 8.8 3.5 12 3.5C15.2 3.5 17.8 6.1 17.8 9.3V13.8L20 17.2H4'
    'L6.2 13.8Z'
    'M9.4 17.2C9.4 18.6 10.6 19.7 12 19.7C13.4 19.7 14.6 18.6 14.6 17.2',
    24,
  );

  static const palette = RafiqIconData(
    'M12 3C7 3 3 7 3 12C3 17 7 21 12 21H13.2C14.3 21 14.8 19.5 13.8 18.7'
    'C13.2 18.2 13.2 17.4 13.8 16.9H15.2C18.2 16.9 20.7 14.5 20.7 11.5'
    'C20.7 6.8 16.8 3 12 3Z'
    'M7.7 10.2C8.2 10.2 8.6 10.6 8.6 11.1C8.6 11.6 8.2 12 7.7 12'
    'C7.2 12 6.8 11.6 6.8 11.1C6.8 10.6 7.2 10.2 7.7 10.2Z'
    'M9.7 6.7C10.2 6.7 10.6 7.1 10.6 7.6C10.6 8.1 10.2 8.5 9.7 8.5'
    'C9.2 8.5 8.8 8.1 8.8 7.6C8.8 7.1 9.2 6.7 9.7 6.7Z'
    'M14.3 6.7C14.8 6.7 15.2 7.1 15.2 7.6C15.2 8.1 14.8 8.5 14.3 8.5'
    'C13.8 8.5 13.4 8.1 13.4 7.6C13.4 7.1 13.8 6.7 14.3 6.7Z'
    'M16.9 10.2C17.4 10.2 17.8 10.6 17.8 11.1C17.8 11.6 17.4 12 16.9 12'
    'C16.4 12 16 11.6 16 11.1C16 10.6 16.4 10.2 16.9 10.2Z',
    24,
  );

  static const volume = RafiqIconData(
    'M4 9.2H7.5L12.3 5.2V18.8L7.5 14.8H4Z'
    'M15.5 8.5C17.4 10.5 17.4 13.5 15.5 15.5'
    'M18.2 5.8C21.6 9.2 21.6 14.8 18.2 18.2',
    24,
  );

  static const shield = RafiqIconData(
    'M12 2.8L20 6V11.1C20 15.8 16.8 19.7 12 21.2C7.2 19.7 4 15.8 4 11.1V6Z'
    'M9.2 11.6L11.2 13.6L15.1 9.7',
    24,
  );

  static const clock = RafiqIconData(
    'M12 3C7 3 3 7 3 12C3 17 7 21 12 21C17 21 21 17 21 12C21 7 17 3 12 3Z'
    'M12 7V12.3L15.8 14.5',
    24,
  );

  static const info = RafiqIconData(
    'M12 3C7 3 3 7 3 12C3 17 7 21 12 21C17 21 21 17 21 12C21 7 17 3 12 3Z'
    'M12 10.8V16.6'
    'M12 7.3V7.7',
    24,
  );

  static const person = RafiqIconData(
    'M12 3.4C9.9 3.4 8.2 5.1 8.2 7.2C8.2 9.3 9.9 11 12 11'
    'C14.1 11 15.8 9.3 15.8 7.2C15.8 5.1 14.1 3.4 12 3.4Z'
    'M4.2 20.6C4.2 16.9 7.2 14.2 12 14.2C16.8 14.2 19.8 16.9 19.8 20.6',
    24,
  );

  static const menuLines = RafiqIconData(
    'M4 7H20'
    'M4 12H16'
    'M4 17H12',
    24,
  );

  static const plus = RafiqIconData('M12 4.5V19.5M4.5 12H19.5', 24);

  static const check = RafiqIconData('M4.5 12.4L9.5 17.3L19.5 6.7', 24);

  static const close = RafiqIconData(
    'M5.5 5.5L18.5 18.5M18.5 5.5L5.5 18.5',
    24,
  );

  static const send = RafiqIconData(
    'M3.5 4.2L21 12L3.5 19.8L6 12Z'
    'M6 12H21',
    24,
  );

  static const globe = RafiqIconData(
    'M12 3C7 3 3 7 3 12C3 17 7 21 12 21C17 21 21 17 21 12C21 7 17 3 12 3Z'
    'M3.5 9H20.5'
    'M3.5 15H20.5'
    'M12 3C9.8 5.2 8.6 8.4 8.6 12C8.6 15.6 9.8 18.8 12 21'
    'C14.2 18.8 15.4 15.6 15.4 12C15.4 8.4 14.2 5.2 12 3Z',
    24,
  );

  static const trash = RafiqIconData(
    'M4.5 6.5H19.5'
    'M9 3.5H15L15.8 6.5'
    'M6.5 6.5L7.5 20.5H16.5L17.5 6.5'
    'M10 10.5V16.5'
    'M14 10.5V16.5',
    24,
  );

  static const edit = RafiqIconData(
    'M4 20H8L19.2 8.8C19.9 8.1 19.9 7 19.2 6.3L17.7 4.8'
    'C17 4.1 15.9 4.1 15.2 4.8L4 16Z'
    'M13.8 6.2L17.8 10.2',
    24,
  );

  static const refresh = RafiqIconData(
    'M20 11.5C19.5 7.1 16.1 4 12 4C8.6 4 5.7 6 4.4 8.8'
    'M4 4.5V9H8.5'
    'M4 12.5C4.5 16.9 7.9 20 12 20C15.4 20 18.3 18 19.6 15.2'
    'M20 19.5V15H15.5',
    24,
  );

  static const phone = RafiqIconData(
    'M7.1 3.2C6.4 2.5 5.2 2.6 4.5 3.4L3.1 4.8C2.1 5.8 1.8 7.3 2.3 8.7'
    'C4.6 15.3 8.7 19.4 15.3 21.7C16.7 22.2 18.2 21.9 19.2 20.9L20.6 19.5'
    'C21.4 18.8 21.5 17.6 20.8 16.9L17.8 14.1C17.1 13.5 16.1 13.5 15.4 14.1L14 15.3'
    'C11.6 14 10 12.4 8.7 10L9.9 8.6C10.5 7.9 10.5 6.9 9.9 6.2Z',
    24,
    filled: true,
  );

  static const message = RafiqIconData(
    'M4 4H20C20.8 4 21.5 4.7 21.5 5.5V16C21.5 16.8 20.8 17.5 20 17.5H9'
    'L4.5 21V17.5H3C2.2 17.5 1.5 16.8 1.5 16V5.5C1.5 4.7 2.2 4 3 4Z',
    24,
    filled: true,
  );

  static const browser = RafiqIconData(
    'M12 2.8C7 2.8 3 6.8 3 11.8C3 16.8 7 20.8 12 20.8C17 20.8 21 16.8 21 11.8'
    'C21 6.8 17 2.8 12 2.8Z'
    'M3.4 8.8H20.6'
    'M9 4C6.5 8 6.5 15.6 9 19.6'
    'M15 4C17.5 8 17.5 15.6 15 19.6',
    24,
  );

  static const camera = RafiqIconData(
    'M3 7.5H7L8.7 5H15.3L17 7.5H21V19H3Z'
    'M12 9.2C9.9 9.2 8.2 10.9 8.2 13C8.2 15.1 9.9 16.8 12 16.8'
    'C14.1 16.8 15.8 15.1 15.8 13C15.8 10.9 14.1 9.2 12 9.2Z',
    24,
  );

  static const List<RafiqIconData> values = <RafiqIconData>[
    home,
    mosque,
    bookOpen,
    quranBook,
    prayerBeads,
    tasbih,
    focus,
    tasks,
    sparkle,
    sun,
    moon,
    bed,
    mic,
    play,
    pause,
    next,
    previous,
    bookmark,
    bookmarkFilled,
    search,
    arrowLeft,
    chevronLeft,
    chevronDown,
    location,
    settings,
    bell,
    palette,
    volume,
    shield,
    clock,
    info,
    person,
    menuLines,
    plus,
    check,
    close,
    send,
    globe,
    trash,
    edit,
    refresh,
    phone,
    message,
    browser,
    camera,
  ];
}

class RafiqIcon extends StatelessWidget {
  const RafiqIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth,
  });

  final RafiqIconData icon;
  final double size;
  final Color? color;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _RafiqIconPainter(
        icon,
        color ?? Theme.of(context).colorScheme.onSurface,
        strokeWidth,
      ),
    ),
  );
}

class _RafiqIconPainter extends CustomPainter {
  const _RafiqIconPainter(this.icon, this.color, this.strokeWidth);

  final RafiqIconData icon;
  final Color color;
  final double? strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    final path = _parseSvgPath(icon.pathData);
    final scale = size.width / icon.viewBoxSize;
    final paint = Paint()
      ..color = color
      ..style = icon.filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = icon.filled ? 0 : (strokeWidth ?? 1.65)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.save();
    canvas.scale(scale);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RafiqIconPainter oldDelegate) {
    return oldDelegate.icon != icon ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

final Map<String, Path> _svgPathCache = <String, Path>{};

Path _parseSvgPath(String d) {
  return _svgPathCache.putIfAbsent(d, () => _SvgPathParser(d).parse());
}

class _SvgPathParser {
  _SvgPathParser(this.source);

  final String source;
  int _pos = 0;

  static const String _commandLetters = 'MmLlHhVvCcSsQqTtAaZz';

  Path parse() {
    final path = Path();
    double cx = 0;
    double cy = 0;
    double sx = 0;
    double sy = 0;
    double cubicCtrlX = 0;
    double cubicCtrlY = 0;
    bool hasCubicCtrl = false;
    double quadCtrlX = 0;
    double quadCtrlY = 0;
    bool hasQuadCtrl = false;
    String command = '';

    _skipSeparators();
    while (_pos < source.length) {
      final char = source[_pos];
      if (_commandLetters.contains(char)) {
        command = char;
        _pos++;
      } else {
        if (command.isEmpty) {
          throw FormatException('Invalid SVG path data: $source');
        }
        if (command == 'M') {
          command = 'L';
        } else if (command == 'm') {
          command = 'l';
        }
      }

      final relative = command != command.toUpperCase();
      final type = command.toUpperCase();

      switch (type) {
        case 'M':
          final x = _readNumber();
          final y = _readNumber();
          cx = relative ? cx + x : x;
          cy = relative ? cy + y : y;
          path.moveTo(cx, cy);
          sx = cx;
          sy = cy;
          command = relative ? 'l' : 'L';
          hasCubicCtrl = false;
          hasQuadCtrl = false;
          break;
        case 'L':
          final x = _readNumber();
          final y = _readNumber();
          cx = relative ? cx + x : x;
          cy = relative ? cy + y : y;
          path.lineTo(cx, cy);
          hasCubicCtrl = false;
          hasQuadCtrl = false;
          break;
        case 'H':
          final x = _readNumber();
          cx = relative ? cx + x : x;
          path.lineTo(cx, cy);
          hasCubicCtrl = false;
          hasQuadCtrl = false;
          break;
        case 'V':
          final y = _readNumber();
          cy = relative ? cy + y : y;
          path.lineTo(cx, cy);
          hasCubicCtrl = false;
          hasQuadCtrl = false;
          break;
        case 'C':
          final x1 = _readNumber();
          final y1 = _readNumber();
          final x2 = _readNumber();
          final y2 = _readNumber();
          final x = _readNumber();
          final y = _readNumber();
          final c1x = relative ? cx + x1 : x1;
          final c1y = relative ? cy + y1 : y1;
          final c2x = relative ? cx + x2 : x2;
          final c2y = relative ? cy + y2 : y2;
          final ex = relative ? cx + x : x;
          final ey = relative ? cy + y : y;
          path.cubicTo(c1x, c1y, c2x, c2y, ex, ey);
          cubicCtrlX = c2x;
          cubicCtrlY = c2y;
          hasCubicCtrl = true;
          cx = ex;
          cy = ey;
          hasQuadCtrl = false;
          break;
        case 'S':
          final x2 = _readNumber();
          final y2 = _readNumber();
          final x = _readNumber();
          final y = _readNumber();
          final c1x = hasCubicCtrl ? 2 * cx - cubicCtrlX : cx;
          final c1y = hasCubicCtrl ? 2 * cy - cubicCtrlY : cy;
          final c2x = relative ? cx + x2 : x2;
          final c2y = relative ? cy + y2 : y2;
          final ex = relative ? cx + x : x;
          final ey = relative ? cy + y : y;
          path.cubicTo(c1x, c1y, c2x, c2y, ex, ey);
          cubicCtrlX = c2x;
          cubicCtrlY = c2y;
          hasCubicCtrl = true;
          cx = ex;
          cy = ey;
          hasQuadCtrl = false;
          break;
        case 'Q':
          final x1 = _readNumber();
          final y1 = _readNumber();
          final x = _readNumber();
          final y = _readNumber();
          final qx = relative ? cx + x1 : x1;
          final qy = relative ? cy + y1 : y1;
          final ex = relative ? cx + x : x;
          final ey = relative ? cy + y : y;
          path.quadraticBezierTo(qx, qy, ex, ey);
          quadCtrlX = qx;
          quadCtrlY = qy;
          hasQuadCtrl = true;
          cx = ex;
          cy = ey;
          hasCubicCtrl = false;
          break;
        case 'T':
          final x = _readNumber();
          final y = _readNumber();
          final qx = hasQuadCtrl ? 2 * cx - quadCtrlX : cx;
          final qy = hasQuadCtrl ? 2 * cy - quadCtrlY : cy;
          final ex = relative ? cx + x : x;
          final ey = relative ? cy + y : y;
          path.quadraticBezierTo(qx, qy, ex, ey);
          quadCtrlX = qx;
          quadCtrlY = qy;
          hasQuadCtrl = true;
          cx = ex;
          cy = ey;
          hasCubicCtrl = false;
          break;
        case 'A':
          final rx = _readNumber();
          final ry = _readNumber();
          final rotation = _readNumber();
          final largeArc = _readFlag();
          final sweep = _readFlag();
          final x = _readNumber();
          final y = _readNumber();
          final ex = relative ? cx + x : x;
          final ey = relative ? cy + y : y;
          _arcTo(path, rx, ry, rotation, largeArc, sweep, ex, ey, cx, cy);
          cx = ex;
          cy = ey;
          hasCubicCtrl = false;
          hasQuadCtrl = false;
          break;
        case 'Z':
          path.close();
          cx = sx;
          cy = sy;
          hasCubicCtrl = false;
          hasQuadCtrl = false;
          break;
        default:
          throw FormatException('Unsupported SVG path command: $command');
      }

      _skipSeparators();
    }

    return path;
  }

  void _arcTo(
    Path path,
    double rx,
    double ry,
    double rotation,
    bool largeArc,
    bool sweep,
    double endX,
    double endY,
    double startX,
    double startY,
  ) {
    if (rx == 0 || ry == 0) {
      path.lineTo(endX, endY);
      return;
    }
    rx = rx.abs();
    ry = ry.abs();
    final phi = rotation * math.pi / 180;
    final cosPhi = math.cos(phi);
    final sinPhi = math.sin(phi);
    final dx = (startX - endX) / 2;
    final dy = (startY - endY) / 2;
    final x1 = cosPhi * dx + sinPhi * dy;
    final y1 = -sinPhi * dx + cosPhi * dy;

    var lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry);
    if (lambda > 1) {
      final scale = math.sqrt(lambda);
      rx *= scale;
      ry *= scale;
    }

    final numerator = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1;
    final denominator = rx * rx * y1 * y1 + ry * ry * x1 * x1;
    final coefficient =
        (largeArc != sweep ? 1.0 : -1.0) *
        math.sqrt(math.max(0.0, numerator / denominator));
    final cxp = coefficient * rx * y1 / ry;
    final cyp = -coefficient * ry * x1 / rx;
    final centerX = cosPhi * cxp - sinPhi * cyp + (startX + endX) / 2;
    final centerY = sinPhi * cxp + cosPhi * cyp + (startY + endY) / 2;

    final ux = (x1 - cxp) / rx;
    final uy = (y1 - cyp) / ry;
    final vx = (-x1 - cxp) / rx;
    final vy = (-y1 - cyp) / ry;

    var theta = _vectorAngle(1, 0, ux, uy);
    var delta = _vectorAngle(ux, uy, vx, vy);
    if (!sweep && delta > 0) {
      delta -= 2 * math.pi;
    } else if (sweep && delta < 0) {
      delta += 2 * math.pi;
    }

    final segmentCount = math.max(1, (delta.abs() / (math.pi / 2)).ceil());
    final segmentDelta = delta / segmentCount;
    final alpha = 4 / 3 * math.tan(segmentDelta / 4);

    for (var i = 0; i < segmentCount; i++) {
      final cosStart = math.cos(theta);
      final sinStart = math.sin(theta);
      final cosEnd = math.cos(theta + segmentDelta);
      final sinEnd = math.sin(theta + segmentDelta);

      final startPointX =
          centerX + rx * cosPhi * cosStart - ry * sinPhi * sinStart;
      final startPointY =
          centerY + rx * sinPhi * cosStart + ry * cosPhi * sinStart;
      final endPointX = centerX + rx * cosPhi * cosEnd - ry * sinPhi * sinEnd;
      final endPointY = centerY + rx * sinPhi * cosEnd + ry * cosPhi * sinEnd;

      final startTangentX = -rx * cosPhi * sinStart - ry * sinPhi * cosStart;
      final startTangentY = -rx * sinPhi * sinStart + ry * cosPhi * cosStart;
      final endTangentX = -rx * cosPhi * sinEnd - ry * sinPhi * cosEnd;
      final endTangentY = -rx * sinPhi * sinEnd + ry * cosPhi * cosEnd;

      path.cubicTo(
        startPointX + alpha * startTangentX,
        startPointY + alpha * startTangentY,
        endPointX - alpha * endTangentX,
        endPointY - alpha * endTangentY,
        endPointX,
        endPointY,
      );

      theta += segmentDelta;
    }
  }

  double _vectorAngle(double ux, double uy, double vx, double vy) {
    final dot = ux * vx + uy * vy;
    final lengths = math.sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy));
    var angle = math.acos((dot / lengths).clamp(-1.0, 1.0).toDouble());
    if (ux * vy - uy * vx < 0) {
      angle = -angle;
    }
    return angle;
  }

  bool _readFlag() {
    _skipSeparators();
    if (_pos >= source.length) {
      throw FormatException('Invalid SVG arc flag in path: $source');
    }
    final char = source[_pos];
    if (char == '0') {
      _pos++;
      return false;
    }
    if (char == '1') {
      _pos++;
      return true;
    }
    throw FormatException('Invalid SVG arc flag in path: $source');
  }

  double _readNumber() {
    _skipSeparators();
    final start = _pos;
    if (_pos < source.length && (source[_pos] == '+' || source[_pos] == '-')) {
      _pos++;
    }
    while (_pos < source.length && _isDigit(source[_pos])) {
      _pos++;
    }
    if (_pos < source.length && source[_pos] == '.') {
      _pos++;
      while (_pos < source.length && _isDigit(source[_pos])) {
        _pos++;
      }
    }
    if (_pos < source.length && (source[_pos] == 'e' || source[_pos] == 'E')) {
      final mark = _pos;
      _pos++;
      if (_pos < source.length &&
          (source[_pos] == '+' || source[_pos] == '-')) {
        _pos++;
      }
      if (_pos < source.length && _isDigit(source[_pos])) {
        while (_pos < source.length && _isDigit(source[_pos])) {
          _pos++;
        }
      } else {
        _pos = mark;
      }
    }
    if (_pos == start) {
      throw FormatException('Invalid SVG path data: $source');
    }
    return double.parse(source.substring(start, _pos));
  }

  void _skipSeparators() {
    while (_pos < source.length) {
      final char = source[_pos];
      if (char == ' ' ||
          char == ',' ||
          char == '\t' ||
          char == '\n' ||
          char == '\r') {
        _pos++;
      } else {
        break;
      }
    }
  }

  static bool _isDigit(String char) {
    final code = char.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }
}

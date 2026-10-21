import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/adhkar_screen.dart';
import 'screens/home_screen.dart';
import 'screens/prayer_screen.dart';
import 'screens/quran_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/palette.dart';
import 'theme/rafiq_theme.dart';
import 'widgets/background.dart';
import 'widgets/bottom_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RafiqApp());
}

class RafiqApp extends StatefulWidget {
  const RafiqApp({super.key});

  @override
  State<RafiqApp> createState() => _RafiqAppState();
}

class _RafiqAppState extends State<RafiqApp> {
  String _themeId = 'emerald';
  String _route = 'home';

  void _navigate(String route) {
    setState(() => _route = route);
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteFor(_themeId);
    return MaterialApp(
      title: 'رفيق',
      debugShowCheckedModeBanner: false,
      theme: buildRafiqTheme(palette),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: RafiqThemeScope(
        palette: palette,
        themeId: _themeId,
        child: _Shell(
          route: _route,
          themeId: _themeId,
          onNavigate: _navigate,
          onThemeChanged: (value) => setState(() => _themeId = value),
        ),
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({
    required this.route,
    required this.themeId,
    required this.onNavigate,
    required this.onThemeChanged,
  });

  final String route;
  final String themeId;
  final ValueChanged<String> onNavigate;
  final ValueChanged<String> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final showBottomBar = const ['home', 'prayer', 'quran', 'adhkar', 'settings']
        .contains(route);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const RafiqBackground(),
          Padding(
            padding: EdgeInsets.only(
              top: media.padding.top,
              bottom: media.padding.bottom,
            ),
            child: Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: const ['home', 'prayer', 'quran', 'adhkar', 'settings']
                        .indexOf(route),
                    children: [
                      HomeScreen(onNavigate: onNavigate),
                      const PrayerScreen(),
                      const QuranScreen(),
                      const AdhkarScreen(),
                      SettingsScreen(
                        themeId: themeId,
                        onThemeChanged: onThemeChanged,
                      ),
                    ],
                  ),
                ),
                if (showBottomBar)
                  RafiqBottomBar(
                    selectedRoute: route,
                    onNavigate: onNavigate,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

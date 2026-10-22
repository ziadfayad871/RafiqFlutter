import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/preferences.dart';
import 'data/prayer_calculator.dart';
import 'screens/adhkar_screen.dart';
import 'screens/assistant_screen.dart';
import 'screens/apps_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/home_screen.dart';
import 'screens/prayer_screen.dart';
import 'screens/quran_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tasks_screen.dart';
import 'state/app_state.dart';
import 'state/prayer_state.dart';
import 'theme/palette.dart';
import 'theme/rafiq_theme.dart';
import 'widgets/background.dart';
import 'widgets/bottom_bar.dart';

class PrayerScope extends InheritedNotifier<PrayerState> {
  const PrayerScope({
    super.key,
    required PrayerState state,
    required super.child,
  }) : super(notifier: state);

  static PrayerState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PrayerScope>();
    assert(scope != null, 'PrayerScope is missing above this context');
    return scope!.notifier!;
  }
}

class RafiqApp extends StatefulWidget {
  const RafiqApp({super.key});

  @override
  State<RafiqApp> createState() => _RafiqAppState();
}

class _RafiqAppState extends State<RafiqApp> {
  late final AppState _appState;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final repository = await PreferencesRepository.create();
    _appState = AppState(repository);
    await _appState.load();
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: SizedBox.shrink()),
      );
    }
    return AppScope(
      state: _appState,
      child: AnimatedBuilder(
        animation: _appState,
        builder: (context, _) {
          final palette = paletteFor(_appState.themeId);
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
              themeId: _appState.themeId,
              child: const RafiqShell(),
            ),
          );
        },
      ),
    );
  }
}

const tabRoutes = ['home', 'prayer', 'quran', 'adhkar', 'settings'];

class _FullScreen extends StatelessWidget {
  const _FullScreen({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final palette = paletteFor(AppScope.of(context).themeId);
    return RafiqThemeScope(
      palette: palette,
      themeId: AppScope.of(context).themeId,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const RafiqBackground(),
            Padding(
              padding: EdgeInsets.only(
                top: media.padding.top,
                bottom: media.padding.bottom,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class RafiqShell extends StatefulWidget {
  const RafiqShell({super.key});

  @override
  State<RafiqShell> createState() => _RafiqShellState();
}

class _RafiqShellState extends State<RafiqShell> {
  final PrayerState _prayer = PrayerState();
  final Set<String> _visited = {'home'};
  String _route = 'home';

  @override
  void initState() {
    super.initState();
    _prayer.start();
  }

  @override
  void dispose() {
    _prayer.dispose();
    super.dispose();
  }

  void _syncPrayer(UserPreferences preferences) {
    final method = CalculationMethod.fromId(preferences.calculationMethod);
    if (_prayer.latitude != preferences.latitude ||
        _prayer.longitude != preferences.longitude ||
        _prayer.method != method ||
        _prayer.locationLabel != preferences.locationLabel) {
      _prayer.update(
        latitude: preferences.latitude,
        longitude: preferences.longitude,
        method: method,
        locationLabel: preferences.locationLabel,
      );
    }
  }

  void _select(String route) {
    if (_route == route) return;
    setState(() {
      _visited.add(route);
      _route = route;
    });
  }

  void _navigate(String route, {bool fromPushedRoute = false}) {
    if (tabRoutes.contains(route)) {
      if (fromPushedRoute) Navigator.of(context).pop();
      setState(() {
        _visited.add(route);
        _route = route;
      });
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => _fullScreenRoute(route)),
    );
  }

  Widget _buildTab(String route) {
    switch (route) {
      case 'home':
        return HomeScreen(onNavigate: _navigate);
      case 'prayer':
        return const PrayerScreen();
      case 'quran':
        return const QuranScreen();
      case 'adhkar':
        return const AdhkarScreen();
      case 'settings':
        return SettingsScreen(
          themeId: AppScope.of(context).themeId,
          onThemeChanged: AppScope.of(context).setTheme,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _fullScreenRoute(String route) {
    switch (route) {
      case 'apps':
        return _FullScreen(
          child: AppsScreen(
            onBack: () => Navigator.of(context).pop(),
            onOpenDestination: (target) =>
                _navigate(target, fromPushedRoute: true),
          ),
        );
      case 'focus':
        return _FullScreen(
          child: FocusScreen(onBack: () => Navigator.of(context).pop()),
        );
      case 'tasks':
        return _FullScreen(
          child: TasksScreen(onBack: () => Navigator.of(context).pop()),
        );
      case 'assistant':
        return _FullScreen(
          child: AssistantScreen(
            onBack: () => Navigator.of(context).pop(),
            onNavigate: (target) =>
                _navigate(target, fromPushedRoute: true),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final appState = AppScope.of(context);
    _syncPrayer(appState.preferences);
    final visibleTabs =
        tabRoutes.where((route) => _visited.contains(route)).toList();
    return PrayerScope(
      state: _prayer,
      child: Scaffold(
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
                    index: visibleTabs.indexOf(_route),
                    children: [
                      for (final route in visibleTabs) _buildTab(route),
                    ],
                  ),
                ),
                  RafiqBottomBar(
                    selectedRoute: _route,
                    onNavigate: _select,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

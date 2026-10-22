import 'package:flutter/services.dart';

class InstalledApp {
  const InstalledApp({
    required this.label,
    required this.packageName,
    required this.activityName,
    this.icon,
  });

  final String label;
  final String packageName;
  final String activityName;
  final Uint8List? icon;
}

class DockApp {
  const DockApp({
    required this.kind,
    required this.label,
    this.packageName,
    this.icon,
  });

  final String kind;
  final String label;
  final String? packageName;
  final Uint8List? icon;
}

class LauncherBridge {
  static const MethodChannel _channel = MethodChannel('rafiq/launcher');

  static Future<List<InstalledApp>> listApps() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('listApps') ?? const [];
    return raw.map((entry) {
      final map = (entry as Map).cast<dynamic, dynamic>();
      return InstalledApp(
        label: map['label'] as String? ?? '',
        packageName: map['packageName'] as String? ?? '',
        activityName: map['activityName'] as String? ?? '',
        icon: map['icon'] as Uint8List?,
      );
    }).toList();
  }

  static Future<List<DockApp>> dockApps() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('dockApps') ?? const [];
    return raw.map((entry) {
      final map = (entry as Map).cast<dynamic, dynamic>();
      return DockApp(
        kind: map['kind'] as String? ?? '',
        label: map['label'] as String? ?? '',
        packageName: map['packageName'] as String?,
        icon: map['icon'] as Uint8List?,
      );
    }).toList();
  }

  static Future<bool> launchApp(String packageName, String activityName) async {
    return await _channel.invokeMethod<bool>('launchApp', {
          'packageName': packageName,
          'activityName': activityName,
        }) ??
        false;
  }

  static Future<bool> launchDock(String kind) async {
    return await _channel.invokeMethod<bool>('launchDock', {'kind': kind}) ?? false;
  }

  static Future<bool> openAppSettings() async {
    return await _channel.invokeMethod<bool>('openAppSettings') ?? false;
  }

  static Future<bool> openLanguageSettings() async {
    return await _channel.invokeMethod<bool>('openLanguageSettings') ?? false;
  }

  static Future<bool> openHomeSettings() async {
    return await _channel.invokeMethod<bool>('openHomeSettings') ?? false;
  }

  static Future<bool> isDefaultLauncher() async {
    return await _channel.invokeMethod<bool>('isDefaultLauncher') ?? false;
  }
}

class AlarmBridge {
  static const MethodChannel _channel = MethodChannel('rafiq/alarms');

  static Future<void> schedulePrayer({
    required DateTime triggerAt,
    required String prayerName,
    required String prayerTime,
  }) async {
    await _channel.invokeMethod<bool>('schedulePrayer', {
      'triggerAt': triggerAt.millisecondsSinceEpoch,
      'prayerName': prayerName,
      'prayerTime': prayerTime,
    });
  }

  static Future<void> configurePrayer({
    required bool enabled,
    required String calculationMethod,
    required double latitude,
    required double longitude,
  }) async {
    await _channel.invokeMethod<bool>('configurePrayer', {
      'enabled': enabled,
      'method': calculationMethod,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  static Future<void> cancelPrayer() async {
    await _channel.invokeMethod<bool>('cancelPrayer');
  }

  static Future<void> scheduleFocus(DateTime endAt) async {
    await _channel.invokeMethod<bool>('scheduleFocus', {
      'endAt': endAt.millisecondsSinceEpoch,
    });
  }

  static Future<void> cancelFocus() async {
    await _channel.invokeMethod<bool>('cancelFocus');
  }

  static Future<bool> canScheduleExact() async {
    return await _channel.invokeMethod<bool>('canScheduleExact') ?? false;
  }

  static Future<void> openExactAlarmSettings() async {
    await _channel.invokeMethod<bool>('openExactAlarmSettings');
  }
}

class DetectedLocation {
  const DetectedLocation({
    required this.latitude,
    required this.longitude,
    this.city,
  });

  final double latitude;
  final double longitude;
  final String? city;
}

class LocationBridge {
  static const MethodChannel _channel = MethodChannel('rafiq/location');

  static Future<bool> hasPermission() async {
    return await _channel.invokeMethod<bool>('hasPermission') ?? false;
  }

  static Future<void> requestPermission() async {
    await _channel.invokeMethod<bool>('requestPermission');
  }

  static Future<DetectedLocation?> currentLocation() async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>?>('getCurrentLocation');
    if (raw == null) return null;
    return DetectedLocation(
      latitude: (raw['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (raw['longitude'] as num?)?.toDouble() ?? 0,
      city: raw['city'] as String?,
    );
  }
}

class SpeechBridge {
  static const MethodChannel _channel = MethodChannel('rafiq/speech');
  static const EventChannel _events = EventChannel('rafiq/speech/events');

  static Stream<String> get results => _events
      .receiveBroadcastStream()
      .map((event) {
        final map = (event as Map).cast<dynamic, dynamic>();
        if (map['type'] == 'result') return map['text'] as String? ?? '';
        return '';
      })
      .where((text) => text.isNotEmpty);

  static Future<bool> speak(String text, {String locale = 'ar'}) async {
    return await _channel.invokeMethod<bool>('speak', {
          'text': text,
          'locale': locale,
        }) ??
        false;
  }

  static Future<void> stopSpeaking() async {
    await _channel.invokeMethod<bool>('stopSpeaking');
  }

  static Future<bool> startListening({String locale = 'ar'}) async {
    return await _channel.invokeMethod<bool>('startListening', {
          'locale': locale,
        }) ??
        false;
  }

  static Future<void> stopListening() async {
    await _channel.invokeMethod<bool>('stopListening');
  }
}

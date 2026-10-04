import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the rest-timer alerts as OS notifications so they fire even
/// when the phone is locked between sets.
class RestNotifications {
  RestNotifications._();
  static final instance = RestNotifications._();

  static const _shortId = 1;
  static const _longId = 2;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Whether notifications can be shown; when false the in-app timer vibrates.
  bool enabled = false;

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      enabled = await android?.requestNotificationsPermission() ?? false;
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  static AndroidNotificationDetails _details(
          String id, String name, List<int> pattern) =>
      AndroidNotificationDetails(
        id,
        name,
        channelDescription: 'Alerts while resting between sets',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(pattern),
        timeoutAfter: 60 * 1000,
      );

  static final _shortDetails = NotificationDetails(
      android: _details('rest_short', 'Rest: short', [0, 300, 150, 300]));
  static final _longDetails = NotificationDetails(
      android: _details(
          'rest_long', 'Rest: long', [0, 700, 200, 700, 200, 700]));

  /// [short] and [long] are the time left until each alert; zero skips it.
  Future<void> schedule({
    required Duration short,
    required Duration long,
    required Duration shortLabel,
    required Duration longLabel,
    required bool lastSetFailed,
  }) async {
    if (!_ready) return;
    await cancel();
    final now = tz.TZDateTime.now(tz.UTC);
    try {
      if (!lastSetFailed && short > Duration.zero) {
        await _plugin.zonedSchedule(
          id: _shortId,
          scheduledDate: now.add(short),
          notificationDetails: _shortDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          title: 'Rest ${_fmt(shortLabel)}',
          body: 'Go now if the last set was easy.',
        );
      }
      if (long <= Duration.zero) return;
      await _plugin.zonedSchedule(
        id: _longId,
        scheduledDate: now.add(long),
        notificationDetails: _longDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: 'Rest ${_fmt(longLabel)}',
        body: lastSetFailed
            ? 'Failed set. Rest up to 5:00, then go.'
            : 'Go time. Last set was hard.',
      );
    } catch (e) {
      debugPrint('Failed to schedule rest alert: $e');
    }
  }

  Future<void> cancel() async {
    if (!_ready) return;
    await _plugin.cancel(id: _shortId);
    await _plugin.cancel(id: _longId);
  }

  static String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

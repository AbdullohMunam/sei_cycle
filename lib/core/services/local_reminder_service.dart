import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalReminderService {
  LocalReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final macGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return androidGranted ?? iosGranted ?? macGranted ?? true;
  }

  Future<void> scheduleScheduleReminder({
    required String scheduleId,
    required String title,
    required DateTime scheduledAt,
    String? body,
  }) async {
    if (!scheduledAt.isAfter(DateTime.now())) return;
    await initialize();

    await _plugin.zonedSchedule(
      id: _stableId(scheduleId),
      title: title,
      body: body ?? 'Pengingat jadwal operasional SeiCycle.',
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'seicycle_schedule_reminders',
          'Pengingat Jadwal',
          channelDescription: 'Pengingat lokal untuk jadwal operasional.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'schedule:$scheduleId',
    );
  }

  Future<void> cancelScheduleReminder(String scheduleId) async {
    await initialize();
    await _plugin.cancel(id: _stableId(scheduleId));
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }
}

int _stableId(String value) => value.hashCode & 0x7fffffff;

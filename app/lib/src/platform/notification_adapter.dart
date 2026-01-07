import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

class LocalNotificationAdapter {
  LocalNotificationAdapter(
    this._plugin, {
    this.channelId = 'flickmemo_reminder',
    this.channelName = 'FlickMemo Reminders',
    this.channelDescription = 'Reminder notifications for FlickMemo',
  });

  final FlutterLocalNotificationsPlugin _plugin;
  final String channelId;
  final String channelName;
  final String channelDescription;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
      ),
    );
  }

  Future<void> scheduleExact({
    required int id,
    required DateTime at,
    String? title,
    String? body,
    String? payload,
  }) async {
    final scheduled = tz.TZDateTime.from(at, tz.local);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
      payload: payload,
      matchDateTimeComponents: null,
    );
  }
}

class WorkManagerAdapter {
  WorkManagerAdapter(
    this._workmanager, {
    DateTime Function()? nowProvider,
  }) : _now = nowProvider ?? DateTime.now;

  final Workmanager _workmanager;
  final DateTime Function() _now;

  Future<void> scheduleReschedule({
    required int noteId,
    required DateTime at,
  }) async {
    final now = _now();
    final delay = at.isAfter(now) ? at.difference(now) : Duration.zero;
    final noteIdStr = noteId.toString();

    await _workmanager.registerOneOffTask(
      'reschedule-' + noteIdStr,
      'reminder_reschedule',
      inputData: {
        'noteId': noteIdStr,
        'scheduledAt': at.millisecondsSinceEpoch,
      },
      initialDelay: delay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }
}


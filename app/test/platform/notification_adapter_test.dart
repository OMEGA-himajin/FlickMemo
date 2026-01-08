import 'package:app/src/platform/notification_adapter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockAndroidPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class _MockWorkmanager extends Mock implements Workmanager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    registerFallbackValue(
      AndroidNotificationChannel('id', 'name', description: 'desc'),
    );
    registerFallbackValue(const Duration());
    registerFallbackValue(
      tz.TZDateTime.from(DateTime.utc(2000, 1, 1), tz.getLocation('UTC')),
    );
    registerFallbackValue(ExistingWorkPolicy.keep);
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
  });

  group('LocalNotificationAdapter', () {
    late _MockPlugin plugin;
    late _MockAndroidPlugin androidPlugin;
    late LocalNotificationAdapter adapter;

    setUp(() {
      plugin = _MockPlugin();
      androidPlugin = _MockAndroidPlugin();
      adapter = LocalNotificationAdapter(
        plugin,
        channelId: 'reminders',
        channelName: 'Reminders',
        channelDescription: 'desc',
      );
      when(() => plugin.initialize(any())).thenAnswer((_) async => true);
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(androidPlugin);
      when(
        () => androidPlugin.createNotificationChannel(any()),
      ).thenAnswer((_) async {});
      when(
        () => plugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: any(named: 'payload'),
          matchDateTimeComponents: null,
        ),
      ).thenAnswer((_) async {});
    });

    test('initializes channel and schedules exact notification', () async {
      final at = DateTime.utc(2025, 1, 1, 12, 0);

      await adapter.initialize();
      await adapter.scheduleExact(
        id: 1,
        at: at,
        title: 't',
        body: 'b',
        payload: 'p',
      );

      verify(() => plugin.initialize(any())).called(1);
      verify(() => androidPlugin.createNotificationChannel(any())).called(1);
      final captured = verify(
        () => plugin.zonedSchedule(
          1,
          't',
          'b',
          captureAny(),
          any(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'p',
          matchDateTimeComponents: null,
        ),
      ).captured;
      final scheduled = captured.single as tz.TZDateTime;
      expect(scheduled.toUtc(), tz.TZDateTime.from(at, tz.local).toUtc());
    });
  });

  group('WorkManagerAdapter', () {
    late _MockWorkmanager workmanager;
    late WorkManagerAdapter adapter;

    setUp(() {
      workmanager = _MockWorkmanager();
      adapter = WorkManagerAdapter(
        workmanager,
        nowProvider: () => DateTime.utc(2025, 1, 1, 7, 0),
      );
      when(
        () => workmanager.registerOneOffTask(
          any(),
          any(),
          inputData: any(named: 'inputData'),
          initialDelay: any(named: 'initialDelay'),
          existingWorkPolicy: any(named: 'existingWorkPolicy'),
        ),
      ).thenAnswer((_) async => true);
    });

    test('schedules reschedule task with delay and payload', () async {
      final at = DateTime.utc(2025, 1, 1, 7, 30);

      await adapter.scheduleReschedule(noteId: 42, at: at);

      verify(
        () => workmanager.registerOneOffTask(
          'reschedule-42',
          'reminder_reschedule',
          inputData: {'noteId': '42', 'scheduledAt': at.millisecondsSinceEpoch},
          initialDelay: const Duration(minutes: 30),
          existingWorkPolicy: ExistingWorkPolicy.replace,
        ),
      ).called(1);
    });

    test('respects past times by using zero delay', () async {
      final at = DateTime.utc(2025, 1, 1, 6, 45);

      await adapter.scheduleReschedule(noteId: 7, at: at);

      verify(
        () => workmanager.registerOneOffTask(
          'reschedule-7',
          'reminder_reschedule',
          inputData: {'noteId': '7', 'scheduledAt': at.millisecondsSinceEpoch},
          initialDelay: Duration.zero,
          existingWorkPolicy: ExistingWorkPolicy.replace,
        ),
      ).called(1);
    });
  });
}

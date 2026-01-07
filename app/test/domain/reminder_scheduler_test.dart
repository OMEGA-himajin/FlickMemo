import 'package:app/src/data/database.dart';
import 'package:app/src/data/repositories.dart';
import 'package:app/src/domain/reminder_scheduler.dart';
import 'package:app/src/platform/local_notification_adapter.dart';
import 'package:app/src/platform/workmanager_adapter.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FlickMemoDatabase db;
  late NoteRepository noteRepository;
  late ReminderRepository reminderRepository;
  late ReminderScheduler scheduler;
  late _LocalAdapterSpy localSpy;
  late _WorkManagerSpy workSpy;

  setUp(() {
    db = FlickMemoDatabase(NativeDatabase.memory());
    noteRepository = NoteRepository(db);
    reminderRepository = ReminderRepository(db);
    localSpy = _LocalAdapterSpy();
    workSpy = _WorkManagerSpy();
    scheduler = ReminderScheduler(
      reminderRepository,
      nowProvider: () => _fixedNow,
      localNotificationAdapter: localSpy,
      workManagerAdapter: workSpy,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('schedules absolute trigger at given time', () async {
    final noteId = await _createNote(noteRepository);
    final target = DateTime(2025, 1, 1, 12, 0);

    final result = await scheduler.schedule(noteId, AbsoluteTrigger(target));

    expect(result.scheduledAt, target);
    final reminders = await reminderRepository.forNote(noteId);
    expect(reminders.length, 1);
    expect(reminders.first.triggerType, 'absolute');
    expect(
      reminders.first.triggerValue,
      target.millisecondsSinceEpoch.toString(),
    );
    expect(reminders.first.scheduledAt, target);
    expect(localSpy.lastReminder?.id, reminders.first.id);
    expect(workSpy.lastReminder?.id, reminders.first.id);
  });

  test('schedules relative trigger minutes from now', () async {
    final noteId = await _createNote(noteRepository);
    final result = await scheduler.schedule(noteId, const RelativeTrigger(30));

    expect(result.scheduledAt, _fixedNow.add(const Duration(minutes: 30)));
    final stored = (await reminderRepository.forNote(noteId)).first;
    expect(stored.triggerType, 'relative');
    expect(stored.triggerValue, '30');
  });

  test('schedules bucket trigger and rolls over past slot', () async {
    final noteId = await _createNote(noteRepository);
    final morningResult = await scheduler.schedule(
      noteId,
      const BucketTrigger('morning'),
    );
    expect(morningResult.scheduledAt, DateTime(2025, 1, 1, 8));

    // after 09:00, expect next day morning
    scheduler = ReminderScheduler(
      reminderRepository,
      nowProvider: () => DateTime(2025, 1, 1, 9),
    );
    final noteId2 = await _createNote(noteRepository);
    final nextDay = await scheduler.schedule(
      noteId2,
      const BucketTrigger('morning'),
    );
    expect(nextDay.scheduledAt, DateTime(2025, 1, 2, 8));
  });
}

final DateTime _fixedNow = DateTime(2025, 1, 1, 7, 0);

Future<int> _createNote(NoteRepository repo) async {
  final now = DateTime(2025, 1, 1, 7, 0);
  return repo.create(
    NotesCompanion.insert(title: 'note', createdAt: now, updatedAt: now),
  );
}

class _LocalAdapterSpy extends LocalNotificationAdapter {
  Reminder? lastReminder;

  @override
  Future<void> schedule(Reminder reminder) async {
    lastReminder = reminder;
  }
}

class _WorkManagerSpy extends WorkManagerAdapter {
  Reminder? lastReminder;

  @override
  Future<void> enqueueRetry(Reminder reminder) async {
    lastReminder = reminder;
  }
}

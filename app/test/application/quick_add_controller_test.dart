import 'package:app/src/application/quick_add_controller.dart';
import 'package:app/src/data/database.dart';
import 'package:app/src/data/repositories.dart';
import 'package:app/src/domain/note_service.dart';
import 'package:app/src/domain/preset_service.dart' as preset;
import 'package:app/src/domain/reminder_scheduler.dart' as reminder;
import 'package:app/src/platform/local_notification_adapter.dart';
import 'package:app/src/platform/workmanager_adapter.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FlickMemoDatabase db;
  late NoteRepository noteRepository;
  late PresetRepository presetRepository;
  late ReminderRepository reminderRepository;
  late NoteService noteService;
  late preset.PresetService presetService;
  late _LocalAdapterSpy localSpy;
  late _WorkManagerSpy workSpy;
  late reminder.ReminderScheduler scheduler;
  late QuickAddController controller;

  setUp(() {
    db = FlickMemoDatabase(NativeDatabase.memory());
    noteRepository = NoteRepository(db);
    presetRepository = PresetRepository(db);
    reminderRepository = ReminderRepository(db);
    noteService = NoteService(noteRepository, nowProvider: () => _fixedNow);
    presetService = preset.PresetService(presetRepository);
    localSpy = _LocalAdapterSpy();
    workSpy = _WorkManagerSpy();
    scheduler = reminder.ReminderScheduler(
      reminderRepository,
      nowProvider: () => _fixedNow,
      localNotificationAdapter: localSpy,
      workManagerAdapter: workSpy,
    );
    controller = QuickAddController(
      noteService,
      scheduler,
      presetService: presetService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('saves note and schedules reminder', () async {
    controller.updateTitle('memo');
    controller.setBody('text');
    controller.setColor('red');
    controller.setTrigger(const reminder.RelativeTrigger(15));

    final result = await controller.save();

    final stored = await noteRepository.find(result.noteId);
    expect(stored, isNotNull);
    expect(stored!.title, 'memo');
    expect(stored.body, 'text');
    expect(stored.color, 'red');

    final reminders = await reminderRepository.forNote(result.noteId);
    expect(reminders.single.triggerType, 'relative');
    expect(reminders.single.triggerValue, '15');
    expect(
      reminders.single.scheduledAt,
      _fixedNow.add(const Duration(minutes: 15)),
    );
    expect(localSpy.lastReminder?.id, reminders.single.id);
    expect(workSpy.lastReminder?.id, reminders.single.id);
  });

  test('throws when title is empty', () {
    controller.updateTitle('   ');

    expect(() => controller.save(), throwsA(isA<ArgumentError>()));
  });

  test('applies preset to state', () async {
    final presetId = await presetService.save(
      const preset.PresetInput(
        name: 'night quick',
        trigger: preset.BucketTrigger('night'),
        inputMode: 'voice',
        color: 'green',
      ),
    );
    final presetItem = (await presetRepository.findById(presetId))!;

    controller.applyPreset(presetItem);

    expect(controller.snapshot.inputMode, 'voice');
    expect(controller.snapshot.color, 'green');
    expect(controller.snapshot.trigger, isA<reminder.BucketTrigger>());
    expect(
      (controller.snapshot.trigger as reminder.BucketTrigger).bucket,
      'night',
    );
  });
}

final DateTime _fixedNow = DateTime(2025, 1, 1, 7, 0);

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

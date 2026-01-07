import 'package:app/src/application/entry_dispatcher.dart';
import 'package:app/src/application/quick_add_controller.dart';
import 'package:app/src/application/widget_shortcut_entry.dart';
import 'package:app/src/data/database.dart';
import 'package:app/src/data/repositories.dart';
import 'package:app/src/domain/note_service.dart';
import 'package:app/src/domain/preset_service.dart';
import 'package:app/src/domain/reminder_scheduler.dart';
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
  late PresetService presetService;
  late _LocalAdapterSpy localSpy;
  late _WorkManagerSpy workSpy;
  late ReminderScheduler scheduler;
  late QuickAddController controller;
  late EntryDispatcher dispatcher;
  late WidgetEntry widgetEntry;
  late ShortcutEntry shortcutEntry;

  setUp(() {
    db = FlickMemoDatabase(NativeDatabase.memory());
    noteRepository = NoteRepository(db);
    presetRepository = PresetRepository(db);
    reminderRepository = ReminderRepository(db);
    noteService = NoteService(noteRepository, nowProvider: () => _fixedNow);
    presetService = PresetService(presetRepository);
    localSpy = _LocalAdapterSpy();
    workSpy = _WorkManagerSpy();
    scheduler = ReminderScheduler(
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
    dispatcher = EntryDispatcher(presetService: presetService);
    widgetEntry = WidgetEntry(dispatcher);
    shortcutEntry = ShortcutEntry(dispatcher);
  });

  tearDown(() async {
    await db.close();
  });

  test('shortcut applies preset and default trigger then saves', () async {
    final presetId = await presetService.save(
      const PresetInput(
        name: 'night voice',
        trigger: BucketTrigger('night'),
        inputMode: 'voice',
        color: 'blue',
      ),
    );

    final request = shortcutEntry.onShortcut(
      presetId: presetId.toString(),
      trigger: DefaultTrigger.relative(15),
    );

    await controller.initializeFromEntry(request);
    controller.updateTitle('from shortcut');

    final result = await controller.save();

    final note = await noteRepository.find(result.noteId);
    expect(note?.color, 'blue');
    expect(controller.state.inputMode, 'voice');

    final reminder = (await reminderRepository.forNote(result.noteId)).single;
    expect(reminder.triggerType, 'relative');
    expect(reminder.triggerValue, '15');
    expect(reminder.scheduledAt, _fixedNow.add(const Duration(minutes: 15)));
    expect(localSpy.lastReminder?.id, reminder.id);
    expect(workSpy.lastReminder?.id, reminder.id);
  });

  test('widget entry without preset still saves with manual trigger', () async {
    final request = widgetEntry.onQuickAdd();
    await controller.initializeFromEntry(request);
    controller.updateTitle('widget note');
    controller.setTrigger(const BucketTrigger('morning'));

    final result = await controller.save();

    final reminder = (await reminderRepository.forNote(result.noteId)).single;
    expect(reminder.triggerType, 'bucket');
    expect(reminder.triggerValue, 'morning');
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

import 'package:app/src/application/input_mode_controller.dart';
import 'package:app/src/application/quick_add_controller.dart';
import 'package:app/src/data/database.dart';
import 'package:app/src/data/repositories.dart';
import 'package:app/src/domain/note_service.dart';
import 'package:app/src/domain/reminder_scheduler.dart';
import 'package:app/src/ui/circular_scheduler.dart';
import 'package:app/src/ui/quick_add_ui.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FlickMemoDatabase db;
  late NoteRepository noteRepository;
  late ReminderRepository reminderRepository;
  late NoteService noteService;
  late ReminderScheduler scheduler;
  late QuickAddController controller;
  late InputModeController modeController;
  late CircularSchedulerUI schedulerUI;
  late QuickAddUI ui;

  setUp(() {
    db = FlickMemoDatabase(NativeDatabase.memory());
    noteRepository = NoteRepository(db);
    reminderRepository = ReminderRepository(db);
    noteService = NoteService(noteRepository, nowProvider: () => _fixedNow);
    scheduler = ReminderScheduler(
      reminderRepository,
      nowProvider: () => _fixedNow,
    );
    controller = QuickAddController(noteService, scheduler);
    modeController = InputModeController();
    schedulerUI = CircularSchedulerUI();
    ui = QuickAddUI(controller, modeController, schedulerUI);
  });

  tearDown(() async {
    await db.close();
  });

  test('warns on exit when dirty and resets after save', () async {
    ui.editTitle('memo');
    expect(ui.shouldWarnOnExit(), isTrue);

    schedulerUI.selectBucket('morning');
    final result = await ui.save();

    expect(result.noteId, greaterThan(0));
    expect(ui.shouldWarnOnExit(), isFalse);

    final saved = await noteRepository.find(result.noteId);
    expect(saved?.title, 'memo');
  });
}

final DateTime _fixedNow = DateTime(2025, 1, 1, 7, 0);

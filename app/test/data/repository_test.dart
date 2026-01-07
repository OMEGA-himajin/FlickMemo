import 'package:app/src/data/database.dart';
import 'package:app/src/data/repositories.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late FlickMemoDatabase db;
  late NoteRepository noteRepository;
  late ReminderRepository reminderRepository;
  late PresetRepository presetRepository;

  setUp(() {
    db = FlickMemoDatabase(NativeDatabase.memory());
    noteRepository = NoteRepository(db);
    reminderRepository = ReminderRepository(db);
    presetRepository = PresetRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('note repository creates and fetches a note', () async {
    final now = DateTime.utc(2025, 1, 1, 9, 0, 0);
    final noteId = await noteRepository.create(
      NotesCompanion.insert(
        title: 'memo',
        body: const Value('body'),
        color: const Value('red'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final stored = await noteRepository.find(noteId);

    expect(stored, isNotNull);
    expect(stored!.title, 'memo');
    expect(stored.body, 'body');
    expect(stored.color, 'red');
  });

  test('reminder is removed when its note is deleted', () async {
    final now = DateTime.utc(2025, 1, 1, 9, 0, 0);
    final noteId = await noteRepository.create(
      NotesCompanion.insert(title: 'memo', createdAt: now, updatedAt: now),
    );

    await reminderRepository.create(
      RemindersCompanion.insert(
        noteId: noteId,
        triggerType: 'absolute',
        triggerValue: const Value('2025-01-02T00:00:00Z'),
        scheduledAt: now.add(const Duration(hours: 1)),
        status: 'scheduled',
      ),
    );

    await noteRepository.delete(noteId);

    final reminders = await reminderRepository.forNote(noteId);
    expect(reminders, isEmpty);
  });

  test('preset repository rejects duplicate names', () async {
    await presetRepository.create(
      PresetsCompanion.insert(
        name: 'morning',
        triggerType: 'bucket',
        triggerValue: 'morning',
        inputMode: const Value('text'),
        color: const Value('yellow'),
      ),
    );

    expect(
      () => presetRepository.create(
        PresetsCompanion.insert(
          name: 'morning',
          triggerType: 'bucket',
          triggerValue: 'morning',
        ),
      ),
      throwsA(isA<SqliteException>()),
    );
  });
}

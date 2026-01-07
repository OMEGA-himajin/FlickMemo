import 'package:app/src/data/database.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late FlickMemoDatabase db;

  setUp(() {
    db = FlickMemoDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('notes can be inserted and read back', () async {
    final now = DateTime.utc(2025, 1, 1, 12, 0, 0);
    final noteId = await db.noteDao.insertNote(
      NotesCompanion.insert(
        title: 'title',
        body: const Value('body'),
        color: const Value('blue'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final fetched = await db.noteDao.getNote(noteId);

    expect(fetched, isNotNull);
    expect(fetched!.title, 'title');
    expect(fetched.body, 'body');
    expect(fetched.color, 'blue');
  });

  test('reminders are cascaded when a note is deleted', () async {
    final now = DateTime.utc(2025, 1, 1, 12, 0, 0);
    final noteId = await db.noteDao.insertNote(
      NotesCompanion.insert(title: 'note', createdAt: now, updatedAt: now),
    );

    await db.reminderDao.insertReminder(
      RemindersCompanion.insert(
        noteId: noteId,
        triggerType: 'absolute',
        triggerValue: const Value('2025-01-02T00:00:00Z'),
        scheduledAt: now.add(const Duration(hours: 1)),
        status: 'scheduled',
      ),
    );

    await db.noteDao.deleteNote(noteId);

    final reminders = await db.reminderDao.remindersForNote(noteId);
    expect(reminders, isEmpty);
  });

  test('preset names must be unique', () async {
    const presetName = 'morning';
    await db.presetDao.insertPreset(
      PresetsCompanion.insert(
        name: presetName,
        triggerType: 'bucket',
        triggerValue: 'morning',
        inputMode: const Value('text'),
        color: const Value('yellow'),
      ),
    );

    expect(
      () => db.presetDao.insertPreset(
        PresetsCompanion.insert(
          name: presetName,
          triggerType: 'bucket',
          triggerValue: 'morning',
        ),
      ),
      throwsA(isA<SqliteException>()),
    );
  });
}

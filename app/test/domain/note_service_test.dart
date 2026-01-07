import 'package:app/src/data/database.dart';
import 'package:app/src/data/repositories.dart';
import 'package:app/src/domain/note_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FlickMemoDatabase db;
  late NoteRepository noteRepository;
  late NoteService noteService;

  setUp(() {
    db = FlickMemoDatabase(NativeDatabase.memory());
    noteRepository = NoteRepository(db);
    noteService = NoteService(noteRepository, nowProvider: () => _fixedNow);
  });

  tearDown(() async {
    await db.close();
  });

  test('creates note with timestamps and color', () async {
    final id = await noteService.create(
      const NoteInput(title: 'memo', body: 'text', color: 'red'),
    );

    final stored = await noteRepository.find(id);

    expect(stored, isNotNull);
    expect(stored!.title, 'memo');
    expect(stored.body, 'text');
    expect(stored.color, 'red');
    expect(stored.createdAt, _fixedNow);
    expect(stored.updatedAt, _fixedNow);
  });

  test('throws when title is empty', () async {
    expect(
      () => noteService.create(const NoteInput(title: '')),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('throws when color is not in allowed palette', () async {
    expect(
      () =>
          noteService.create(const NoteInput(title: 'memo', color: 'unknown')),
      throwsA(isA<ArgumentError>()),
    );
  });
}

final DateTime _fixedNow = DateTime(2025, 1, 1, 10, 0, 0);

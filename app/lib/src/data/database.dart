import 'package:drift/drift.dart';

part 'database.g.dart';

class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  TextColumn get color => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteId =>
      integer().references(Notes, #id, onDelete: KeyAction.cascade)();
  TextColumn get triggerType => text()();
  TextColumn get triggerValue => text().nullable()();
  DateTimeColumn get scheduledAt => dateTime()();
  TextColumn get status => text()();

  @override
  List<Index> get indexes => [
    Index(
      'idx_reminders_scheduled_at',
      'CREATE INDEX idx_reminders_scheduled_at ON reminders (scheduled_at)',
    ),
  ];
}

class Presets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get triggerType => text()();
  TextColumn get triggerValue => text()();
  TextColumn get inputMode => text().nullable()();
  TextColumn get color => text().nullable()();
}

@DriftDatabase(
  tables: [Notes, Reminders, Presets],
  daos: [NoteDao, ReminderDao, PresetDao],
)
class FlickMemoDatabase extends _$FlickMemoDatabase {
  FlickMemoDatabase(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

@DriftAccessor(tables: [Notes])
class NoteDao extends DatabaseAccessor<FlickMemoDatabase> with _$NoteDaoMixin {
  NoteDao(FlickMemoDatabase db) : super(db);

  Future<int> insertNote(NotesCompanion data) => into(notes).insert(data);

  Future<Note?> getNote(int id) =>
      (select(notes)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<List<Note>> allNotes() => select(notes).get();

  Future<int> deleteNote(int id) =>
      (delete(notes)..where((tbl) => tbl.id.equals(id))).go();
}

@DriftAccessor(tables: [Reminders])
class ReminderDao extends DatabaseAccessor<FlickMemoDatabase>
    with _$ReminderDaoMixin {
  ReminderDao(FlickMemoDatabase db) : super(db);

  Future<int> insertReminder(RemindersCompanion data) =>
      into(reminders).insert(data);

  Future<List<Reminder>> remindersForNote(int noteId) =>
      (select(reminders)..where((tbl) => tbl.noteId.equals(noteId))).get();

  Future<Reminder?> findById(int id) =>
      (select(reminders)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
}

@DriftAccessor(tables: [Presets])
class PresetDao extends DatabaseAccessor<FlickMemoDatabase>
    with _$PresetDaoMixin {
  PresetDao(FlickMemoDatabase db) : super(db);

  Future<int> insertPreset(PresetsCompanion data) => into(presets).insert(data);

  Future<Preset?> findByName(String name) => (select(
    presets,
  )..where((tbl) => tbl.name.equals(name))).getSingleOrNull();

  Future<List<Preset>> allPresets() => select(presets).get();

  Future<Preset?> findById(int id) =>
      (select(presets)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<int> updatePreset(int id, PresetsCompanion data) =>
      (update(presets)..where((tbl) => tbl.id.equals(id))).write(data);
}

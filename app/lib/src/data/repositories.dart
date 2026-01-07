import 'package:app/src/data/database.dart';
import 'package:drift/drift.dart';

class NoteRepository {
  NoteRepository(this._db);

  final FlickMemoDatabase _db;

  Future<int> create(NotesCompanion note) => _db.noteDao.insertNote(note);

  Future<Note?> find(int id) => _db.noteDao.getNote(id);

  Future<List<Note>> all() => _db.noteDao.allNotes();

  Future<int> delete(int id) => _db.noteDao.deleteNote(id);
}

class ReminderRepository {
  ReminderRepository(this._db);

  final FlickMemoDatabase _db;

  Future<int> create(RemindersCompanion reminder) =>
      _db.reminderDao.insertReminder(reminder);

  Future<List<Reminder>> forNote(int noteId) =>
      _db.reminderDao.remindersForNote(noteId);
}

class PresetRepository {
  PresetRepository(this._db);

  final FlickMemoDatabase _db;

  Future<int> create(PresetsCompanion preset) =>
      _db.presetDao.insertPreset(preset);

  Future<Preset?> findByName(String name) => _db.presetDao.findByName(name);

  Future<List<Preset>> all() => _db.presetDao.allPresets();
}

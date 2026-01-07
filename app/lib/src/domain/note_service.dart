import 'package:app/src/data/database.dart';
import 'package:app/src/data/repositories.dart';
import 'package:drift/drift.dart';

class NoteInput {
  const NoteInput({required this.title, this.body, this.color});

  final String title;
  final String? body;
  final String? color;
}

class NoteService {
  NoteService(
    this._noteRepository, {
    DateTime Function()? nowProvider,
    Set<String>? allowedColors,
  }) : _now = nowProvider ?? DateTime.now,
       _allowedColors =
           allowedColors ?? const {'red', 'blue', 'yellow', 'green'};

  final NoteRepository _noteRepository;
  final DateTime Function() _now;
  final Set<String> _allowedColors;

  Future<int> create(NoteInput input) async {
    final title = input.title.trim();
    if (title.isEmpty) {
      throw ArgumentError('title must not be empty');
    }
    if (input.color != null && !_allowedColors.contains(input.color)) {
      throw ArgumentError('color must be one of $_allowedColors');
    }

    final now = _now();
    final companion = NotesCompanion.insert(
      title: title,
      body: Value(input.body),
      color: Value(input.color),
      createdAt: now,
      updatedAt: now,
    );

    return _noteRepository.create(companion);
  }
}

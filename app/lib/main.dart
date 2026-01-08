import 'package:flutter/material.dart';
import 'package:drift/native.dart';
import 'package:app/src/data/database.dart';
import 'package:app/src/data/repositories.dart';
import 'package:app/src/domain/note_service.dart';
import 'package:app/src/domain/reminder_scheduler.dart';
import 'package:app/src/application/quick_add_controller.dart';
import 'package:app/src/domain/reminder_scheduler.dart' as reminder;

void main() {
  runApp(const FlickMemoApp());
}

class FlickMemoApp extends StatelessWidget {
  const FlickMemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlickMemo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const QuickAddScreen(),
    );
  }
}

class QuickAddScreen extends StatefulWidget {
  const QuickAddScreen({super.key});

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  late final QuickAddController _controller;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _selectedColor;
  reminder.ReminderTrigger? _selectedTrigger;

  @override
  void initState() {
    super.initState();
    // Initialize database and services
    final db = FlickMemoDatabase(NativeDatabase.memory());
    final noteRepo = NoteRepository(db);
    final reminderRepo = ReminderRepository(db);
    final noteService = NoteService(noteRepo);
    final scheduler = ReminderScheduler(reminderRepo);

    _controller = QuickAddController(noteService, scheduler);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    _controller.updateTitle(_titleController.text);
    _controller.setBody(_bodyController.text);
    if (_selectedColor != null) {
      _controller.setColor(_selectedColor);
    }
    if (_selectedTrigger != null) {
      _controller.setTrigger(_selectedTrigger);
    }

    final result = await _controller.save();
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('メモを保存しました (ID: ${result.noteId})')));
    _titleController.clear();
    _bodyController.clear();
    setState(() {
      _selectedColor = null;
      _selectedTrigger = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlickMemo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル（必須）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: '本文（任意）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _colorChip('red', Colors.red),
                _colorChip('blue', Colors.blue),
                _colorChip('yellow', Colors.yellow),
                _colorChip('green', Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _triggerChip('30分後', reminder.RelativeTrigger(30)),
                _triggerChip('1時間後', reminder.RelativeTrigger(60)),
                _triggerChip('朝', reminder.BucketTrigger('朝')),
                _triggerChip('昼', reminder.BucketTrigger('昼')),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('保存', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorChip(String colorName, Color color) {
    final isSelected = _selectedColor == colorName;
    return FilterChip(
      label: Text(colorName),
      selected: isSelected,
      backgroundColor: color.withOpacity(0.3),
      selectedColor: color.withOpacity(0.6),
      onSelected: (selected) {
        setState(() {
          _selectedColor = selected ? colorName : null;
        });
      },
    );
  }

  Widget _triggerChip(String label, reminder.ReminderTrigger trigger) {
    final isSelected = _selectedTrigger == trigger;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTrigger = selected ? trigger : null;
        });
      },
    );
  }
}

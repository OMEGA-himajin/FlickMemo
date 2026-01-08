import 'package:app/src/application/entry_dispatcher.dart';
import 'package:app/src/data/database.dart';
import 'package:app/src/domain/note_service.dart';
import 'package:app/src/domain/preset_service.dart' as preset;
import 'package:app/src/domain/reminder_scheduler.dart' as reminder;

class QuickAddState {
  const QuickAddState({
    this.title = '',
    this.body,
    this.color,
    this.inputMode = 'text',
    this.trigger,
    this.entryType = EntryType.app,
    this.openNoteId,
    this.hasChanges = false,
  });

  final String title;
  final String? body;
  final String? color;
  final String inputMode;
  final reminder.ReminderTrigger? trigger;
  final EntryType entryType;
  final int? openNoteId;
  final bool hasChanges;

  QuickAddState copyWith({
    String? title,
    String? body,
    String? color,
    String? inputMode,
    reminder.ReminderTrigger? trigger,
    bool overrideTrigger = false,
    EntryType? entryType,
    int? openNoteId,
    bool? hasChanges,
  }) {
    return QuickAddState(
      title: title ?? this.title,
      body: body ?? this.body,
      color: color ?? this.color,
      inputMode: inputMode ?? this.inputMode,
      trigger: overrideTrigger ? trigger : (trigger ?? this.trigger),
      entryType: entryType ?? this.entryType,
      openNoteId: openNoteId ?? this.openNoteId,
      hasChanges: hasChanges ?? this.hasChanges,
    );
  }
}

class SaveResult {
  const SaveResult({required this.noteId, this.scheduledAt});
  final int noteId;
  final DateTime? scheduledAt;
}

class QuickAddController {
  QuickAddController(
    this._noteService,
    this._scheduler, {
    preset.PresetService? presetService,
  }) : _presetService = presetService;

  final NoteService _noteService;
  final reminder.ReminderScheduler _scheduler;
  final preset.PresetService? _presetService;

  QuickAddState _state = const QuickAddState();
  QuickAddState get snapshot => _state;
  QuickAddState get state => _state;
  bool get hasUnsavedChanges => _state.hasChanges;

  void updateTitle(String title) {
    _state = _state.copyWith(title: title, hasChanges: true);
  }

  void setBody(String? body) {
    _state = _state.copyWith(body: body, hasChanges: true);
  }

  void setColor(String? color) {
    _state = _state.copyWith(color: color, hasChanges: true);
  }

  void setInputMode(String inputMode) {
    _state = _state.copyWith(inputMode: inputMode, hasChanges: true);
  }

  void setTrigger(reminder.ReminderTrigger? trigger) {
    _state = _state.copyWith(
      trigger: trigger,
      hasChanges: true,
      overrideTrigger: true,
    );
  }

  Future<void> initializeFromEntry(QuickAddRequest request) async {
    _state = _state.copyWith(
      entryType: request.entryType,
      openNoteId: request.openNoteId,
      inputMode: request.inputMode ?? _state.inputMode,
      color: request.color ?? _state.color,
      hasChanges: true,
    );

    if (request.presetId != null && _presetService != null) {
      final presetId = int.tryParse(request.presetId!);
      if (presetId != null) {
        final presetItem = await _presetService.get(presetId);
        if (presetItem != null) {
          applyPreset(presetItem);
        }
      }
    }

    if (request.defaultTrigger != null) {
      setTrigger(_mapDefaultTrigger(request.defaultTrigger!));
    }
  }

  void applyPreset(Preset preset) {
    final trigger = _mapPresetTrigger(preset);
    _state = _state.copyWith(
      inputMode: preset.inputMode ?? _state.inputMode,
      color: preset.color ?? _state.color,
      trigger: trigger ?? _state.trigger,
      hasChanges: true,
    );
  }

  Future<SaveResult> save() async {
    final trimmedTitle = _state.title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('title must not be empty');
    }

    final noteId = await _noteService.create(
      NoteInput(title: trimmedTitle, body: _state.body, color: _state.color),
    );

    DateTime? scheduledAt;
    final reminderTrigger = _state.trigger;
    if (reminderTrigger != null) {
      final result = await _scheduler.schedule(noteId, reminderTrigger);
      scheduledAt = result.scheduledAt;
    }

    _state = _state.copyWith(hasChanges: false);
    return SaveResult(noteId: noteId, scheduledAt: scheduledAt);
  }

  reminder.ReminderTrigger _mapDefaultTrigger(DefaultTrigger trigger) {
    switch (trigger.type) {
      case TriggerType.absolute:
        return reminder.AbsoluteTrigger(
          DateTime.fromMillisecondsSinceEpoch(int.parse(trigger.value)),
        );
      case TriggerType.relative:
        return reminder.RelativeTrigger(int.parse(trigger.value));
      case TriggerType.bucket:
        return reminder.BucketTrigger(trigger.value);
    }
  }

  reminder.ReminderTrigger? _mapPresetTrigger(Preset preset) {
    switch (preset.triggerType) {
      case 'absolute':
        final millis = int.tryParse(preset.triggerValue);
        if (millis == null) return null;
        return reminder.AbsoluteTrigger(
          DateTime.fromMillisecondsSinceEpoch(millis),
        );
      case 'relative':
        final minutes = int.tryParse(preset.triggerValue);
        if (minutes == null) return null;
        return reminder.RelativeTrigger(minutes);
      case 'bucket':
        return reminder.BucketTrigger(preset.triggerValue);
      default:
        return null;
    }
  }
}

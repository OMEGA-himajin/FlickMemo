import 'package:app/src/domain/preset_service.dart';

enum EntryType { app, widget, shortcut, notification }

enum TriggerType { absolute, relative, bucket }

class DefaultTrigger {
  const DefaultTrigger._(this.type, this.value);
  final TriggerType type;
  final String value;

  DefaultTrigger.absolute(int epochMillis)
    : this._(TriggerType.absolute, epochMillis.toString());

  DefaultTrigger.relative(int minutes)
    : this._(TriggerType.relative, minutes.toString());

  DefaultTrigger.bucket(String bucket) : this._(TriggerType.bucket, bucket);
}

class EntryInput {
  const EntryInput({
    required this.entryType,
    this.presetId,
    this.openNoteId,
    this.defaultTrigger,
    this.inputMode,
    this.color,
  });

  final EntryType entryType;
  final String? presetId;
  final int? openNoteId;
  final DefaultTrigger? defaultTrigger;
  final String? inputMode;
  final String? color;
}

class QuickAddRequest {
  QuickAddRequest({
    required this.entryType,
    this.presetId,
    this.openNoteId,
    this.defaultTrigger,
    this.inputMode,
    this.color,
  });

  final EntryType entryType;
  final String? presetId;
  final int? openNoteId;
  final DefaultTrigger? defaultTrigger;
  final String? inputMode;
  final String? color;
}

class EntryDispatcher {
  EntryDispatcher({PresetService? presetService})
    : _presetService = presetService;

  final PresetService? _presetService;

  QuickAddRequest dispatch(EntryInput input) {
    // In future, preset loading and validation can be added here.
    return QuickAddRequest(
      entryType: input.entryType,
      presetId: input.presetId,
      openNoteId: input.openNoteId,
      defaultTrigger: input.defaultTrigger,
      inputMode: input.inputMode,
      color: input.color,
    );
  }
}

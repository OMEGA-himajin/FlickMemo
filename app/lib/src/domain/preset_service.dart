import 'package:app/src/data/database.dart';
import 'package:app/src/data/repositories.dart';
import 'package:drift/drift.dart';

abstract class PresetTrigger {
  const PresetTrigger();
}

class BucketTrigger extends PresetTrigger {
  const BucketTrigger(this.bucket);
  final String bucket;
}

class RelativeTrigger extends PresetTrigger {
  const RelativeTrigger(this.minutes);
  final int minutes;
}

class AbsoluteTrigger extends PresetTrigger {
  const AbsoluteTrigger(this.at);
  final DateTime at;
}

class UnsupportedTrigger extends PresetTrigger {
  const UnsupportedTrigger(this.kind);
  final String kind;
}

class PresetInput {
  const PresetInput({
    required this.name,
    required this.trigger,
    this.inputMode,
    this.color,
  });

  final String name;
  final PresetTrigger trigger;
  final String? inputMode;
  final String? color;
}

class PresetService {
  PresetService(
    this._presetRepository, {
    Set<String>? allowedBuckets,
    Set<String>? allowedInputModes,
    Set<String>? allowedColors,
  }) : _allowedBuckets =
           allowedBuckets ?? const {'morning', 'noon', 'evening', 'night'},
       _allowedInputModes = allowedInputModes ?? const {'text', 'voice'},
       _allowedColors =
           allowedColors ?? const {'red', 'blue', 'yellow', 'green'};

  final PresetRepository _presetRepository;
  final Set<String> _allowedBuckets;
  final Set<String> _allowedInputModes;
  final Set<String> _allowedColors;

  Future<int> save(PresetInput input) async {
    final companion = _toCompanion(input);
    return _presetRepository.create(companion);
  }

  Future<Preset?> get(int id) => _presetRepository.findById(id);

  Future<void> update(int id, PresetInput input) async {
    final companion = _toCompanion(input, allowNameOverride: true);
    await _presetRepository.update(id, companion);
  }

  PresetsCompanion _toCompanion(
    PresetInput input, {
    bool allowNameOverride = false,
  }) {
    final name = input.name.trim();
    if (name.isEmpty) {
      throw ArgumentError('name must not be empty');
    }

    final trigger = _mapTrigger(input.trigger);

    if (input.inputMode != null &&
        !_allowedInputModes.contains(input.inputMode)) {
      throw ArgumentError('inputMode must be one of $_allowedInputModes');
    }

    if (input.color != null && !_allowedColors.contains(input.color)) {
      throw ArgumentError('color must be one of $_allowedColors');
    }

    return PresetsCompanion.insert(
      name: name,
      triggerType: trigger.type,
      triggerValue: trigger.value,
      inputMode: Value(input.inputMode),
      color: Value(input.color),
    );
  }

  _MappedTrigger _mapTrigger(PresetTrigger trigger) {
    if (trigger is BucketTrigger) {
      if (!_allowedBuckets.contains(trigger.bucket)) {
        throw ArgumentError('bucket must be one of $_allowedBuckets');
      }
      return _MappedTrigger('bucket', trigger.bucket);
    }
    if (trigger is RelativeTrigger) {
      if (trigger.minutes <= 0) {
        throw ArgumentError('relative minutes must be positive');
      }
      return _MappedTrigger('relative', trigger.minutes.toString());
    }
    if (trigger is AbsoluteTrigger) {
      return _MappedTrigger(
        'absolute',
        trigger.at.millisecondsSinceEpoch.toString(),
      );
    }
    throw ArgumentError('unsupported trigger');
  }
}

class _MappedTrigger {
  const _MappedTrigger(this.type, this.value);
  final String type;
  final String value;
}

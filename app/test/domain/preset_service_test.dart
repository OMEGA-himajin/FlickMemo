import 'package:app/src/data/database.dart';
import 'package:app/src/data/repositories.dart';
import 'package:app/src/domain/preset_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FlickMemoDatabase db;
  late PresetRepository presetRepository;
  late PresetService presetService;

  setUp(() {
    db = FlickMemoDatabase(NativeDatabase.memory());
    presetRepository = PresetRepository(db);
    presetService = PresetService(presetRepository);
  });

  tearDown(() async {
    await db.close();
  });

  test('saves bucket preset with input mode and color', () async {
    final id = await presetService.save(
      const PresetInput(
        name: 'morning quick',
        trigger: BucketTrigger('morning'),
        inputMode: 'text',
        color: 'red',
      ),
    );

    final stored = await presetRepository.findById(id);

    expect(stored, isNotNull);
    expect(stored!.name, 'morning quick');
    expect(stored.triggerType, 'bucket');
    expect(stored.triggerValue, 'morning');
    expect(stored.inputMode, 'text');
    expect(stored.color, 'red');
  });

  test('updates an existing preset', () async {
    final id = await presetService.save(
      const PresetInput(
        name: 'morning quick',
        trigger: BucketTrigger('morning'),
        inputMode: 'text',
        color: 'red',
      ),
    );

    await presetService.update(
      id,
      const PresetInput(
        name: 'morning quick',
        trigger: RelativeTrigger(30),
        inputMode: 'voice',
        color: 'blue',
      ),
    );

    final stored = await presetRepository.findById(id);
    expect(stored, isNotNull);
    expect(stored!.triggerType, 'relative');
    expect(stored.triggerValue, '30');
    expect(stored.inputMode, 'voice');
    expect(stored.color, 'blue');
  });

  test('rejects invalid trigger type', () async {
    expect(
      () => presetService.save(
        const PresetInput(name: 'bad', trigger: UnsupportedTrigger('x')),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects negative relative minutes', () async {
    expect(
      () => presetService.save(
        const PresetInput(name: 'rel', trigger: RelativeTrigger(-5)),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects unknown bucket value', () async {
    expect(
      () => presetService.save(
        const PresetInput(name: 'bucket', trigger: BucketTrigger('dawn')),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects unknown input mode', () async {
    expect(
      () => presetService.save(
        const PresetInput(
          name: 'mode',
          trigger: BucketTrigger('morning'),
          inputMode: 'handwriting',
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects unknown color', () async {
    expect(
      () => presetService.save(
        const PresetInput(
          name: 'color',
          trigger: BucketTrigger('morning'),
          color: 'pink',
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}

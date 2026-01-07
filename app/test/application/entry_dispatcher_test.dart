import 'package:app/src/application/entry_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps app entry to quick add request without preset', () {
    final dispatcher = EntryDispatcher();

    final request = dispatcher.dispatch(
      const EntryInput(entryType: EntryType.app),
    );

    expect(request.entryType, EntryType.app);
    expect(request.presetId, isNull);
    expect(request.defaultTrigger?.type, isNull);
  });

  test('applies preset id and trigger', () {
    final dispatcher = EntryDispatcher();

    final request = dispatcher.dispatch(
      EntryInput(
        entryType: EntryType.shortcut,
        presetId: 'p1',
        defaultTrigger: DefaultTrigger.relative(30),
        inputMode: 'voice',
        color: 'red',
      ),
    );

    expect(request.entryType, EntryType.shortcut);
    expect(request.presetId, 'p1');
    expect(request.defaultTrigger?.type, TriggerType.relative);
    expect(request.defaultTrigger?.value, '30');
    expect(request.inputMode, 'voice');
    expect(request.color, 'red');
  });
}

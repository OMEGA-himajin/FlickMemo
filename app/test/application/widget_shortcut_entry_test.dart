import 'package:app/src/application/entry_dispatcher.dart';
import 'package:app/src/application/widget_shortcut_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('widget entry forwards to dispatcher with widget type', () {
    final calls = <EntryInput>[];
    final dispatcher = _DispatcherSpy((input) {
      calls.add(input);
      return QuickAddRequest(entryType: input.entryType);
    });
    final widgetEntry = WidgetEntry(dispatcher);

    widgetEntry.onQuickAdd();

    expect(calls.single.entryType, EntryType.widget);
  });

  test('shortcut entry forwards to dispatcher with shortcut type', () {
    final calls = <EntryInput>[];
    final dispatcher = _DispatcherSpy((input) {
      calls.add(input);
      return QuickAddRequest(
        entryType: input.entryType,
        presetId: input.presetId,
      );
    });
    final shortcutEntry = ShortcutEntry(dispatcher);

    shortcutEntry.onShortcut(presetId: 'p1');

    expect(calls.single.entryType, EntryType.shortcut);
    expect(calls.single.presetId, 'p1');
  });
}

class _DispatcherSpy implements EntryDispatcher {
  _DispatcherSpy(this._fn);
  final QuickAddRequest Function(EntryInput) _fn;

  @override
  QuickAddRequest dispatch(EntryInput input) => _fn(input);
}

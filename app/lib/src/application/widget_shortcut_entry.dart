import 'package:app/src/application/entry_dispatcher.dart';

class WidgetEntry {
  WidgetEntry(this._dispatcher);
  final EntryDispatcher _dispatcher;

  QuickAddRequest onQuickAdd() {
    return _dispatcher.dispatch(const EntryInput(entryType: EntryType.widget));
  }
}

class ShortcutEntry {
  ShortcutEntry(this._dispatcher);
  final EntryDispatcher _dispatcher;

  QuickAddRequest onShortcut({String? presetId, DefaultTrigger? trigger}) {
    return _dispatcher.dispatch(
      EntryInput(
        entryType: EntryType.shortcut,
        presetId: presetId,
        defaultTrigger: trigger,
      ),
    );
  }
}

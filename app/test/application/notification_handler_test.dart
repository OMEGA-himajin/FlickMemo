import 'package:app/src/application/entry_dispatcher.dart';
import 'package:app/src/application/notification_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts tap into entry input', () {
    final handler = NotificationHandler();

    final input = handler.handleTap(const NotificationTap(noteId: 42));

    expect(input.entryType, EntryType.notification);
    expect(input.openNoteId, 42);
  });
}

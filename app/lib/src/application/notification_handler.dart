import 'package:app/src/application/entry_dispatcher.dart';

class NotificationTap {
  const NotificationTap({required this.noteId});
  final int noteId;
}

class NotificationHandler {
  EntryInput handleTap(NotificationTap tap) {
    return EntryInput(
      entryType: EntryType.notification,
      openNoteId: tap.noteId,
    );
  }
}

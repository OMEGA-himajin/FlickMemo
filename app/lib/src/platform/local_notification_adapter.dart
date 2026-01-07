import 'package:app/src/data/database.dart';

abstract class LocalNotificationAdapter {
  const LocalNotificationAdapter();
  Future<void> schedule(Reminder reminder);
}

class NoopLocalNotificationAdapter extends LocalNotificationAdapter {
  const NoopLocalNotificationAdapter();

  @override
  Future<void> schedule(Reminder reminder) async {}
}

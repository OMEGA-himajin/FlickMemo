import 'package:app/src/data/database.dart';

abstract class WorkManagerAdapter {
  const WorkManagerAdapter();
  Future<void> enqueueRetry(Reminder reminder);
}

class NoopWorkManagerAdapter extends WorkManagerAdapter {
  const NoopWorkManagerAdapter();

  @override
  Future<void> enqueueRetry(Reminder reminder) async {}
}

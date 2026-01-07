import 'package:app/src/domain/reminder_scheduler.dart';

enum SchedulerMode { detailed, simple }

class CircularSchedulerUI {
  CircularSchedulerUI({SchedulerMode initialMode = SchedulerMode.simple})
    : _mode = initialMode;

  SchedulerMode _mode;
  DateTime? _exactTime;
  String? _bucket;

  SchedulerMode get mode => _mode;

  void switchMode(SchedulerMode mode) {
    _mode = mode;
  }

  void selectExactTime(DateTime time) {
    _exactTime = time;
    _mode = SchedulerMode.detailed;
  }

  void selectBucket(String bucket) {
    _bucket = bucket;
    _mode = SchedulerMode.simple;
  }

  ReminderTrigger? get currentTrigger {
    if (_mode == SchedulerMode.detailed && _exactTime != null) {
      return AbsoluteTrigger(_exactTime!);
    }
    if (_mode == SchedulerMode.simple && _bucket != null) {
      return BucketTrigger(_bucket!);
    }
    return null;
  }
}

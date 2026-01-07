import 'package:app/src/data/database.dart';
import 'package:app/src/data/repositories.dart';
import 'package:app/src/platform/local_notification_adapter.dart';
import 'package:app/src/platform/workmanager_adapter.dart';
import 'package:drift/drift.dart';

class ReminderTrigger {
  const ReminderTrigger();
}

class AbsoluteTrigger extends ReminderTrigger {
  const AbsoluteTrigger(this.at);
  final DateTime at;
}

class RelativeTrigger extends ReminderTrigger {
  const RelativeTrigger(this.minutes);
  final int minutes;
}

class BucketTrigger extends ReminderTrigger {
  const BucketTrigger(this.bucket);
  final String bucket;
}

class ScheduleResult {
  const ScheduleResult(this.scheduledAt);
  final DateTime scheduledAt;
}

class ReminderScheduler {
  ReminderScheduler(
    this._reminderRepository, {
    DateTime Function()? nowProvider,
    Map<String, _BucketSlot>? bucketSlots,
    LocalNotificationAdapter? localNotificationAdapter,
    WorkManagerAdapter? workManagerAdapter,
  }) : _now = nowProvider ?? DateTime.now,
       _bucketSlots = bucketSlots ?? _defaultBuckets,
       _localNotificationAdapter =
           localNotificationAdapter ?? const NoopLocalNotificationAdapter(),
       _workManagerAdapter =
           workManagerAdapter ?? const NoopWorkManagerAdapter();

  final ReminderRepository _reminderRepository;
  final DateTime Function() _now;
  final Map<String, _BucketSlot> _bucketSlots;
  final LocalNotificationAdapter _localNotificationAdapter;
  final WorkManagerAdapter _workManagerAdapter;

  Future<ScheduleResult> schedule(int noteId, ReminderTrigger trigger) async {
    final now = _now();
    final _Computed computed = _compute(trigger, now);

    final reminderId = await _reminderRepository.create(
      RemindersCompanion.insert(
        noteId: noteId,
        triggerType: computed.type,
        triggerValue: Value(computed.value),
        scheduledAt: computed.scheduledAt,
        status: 'scheduled',
      ),
    );

    final reminder = await _reminderRepository.findById(reminderId);
    if (reminder != null) {
      await _localNotificationAdapter.schedule(reminder);
      await _workManagerAdapter.enqueueRetry(reminder);
    }

    return ScheduleResult(computed.scheduledAt);
  }

  _Computed _compute(ReminderTrigger trigger, DateTime now) {
    if (trigger is AbsoluteTrigger) {
      return _Computed(
        type: 'absolute',
        value: trigger.at.millisecondsSinceEpoch.toString(),
        scheduledAt: trigger.at,
      );
    }

    if (trigger is RelativeTrigger) {
      if (trigger.minutes <= 0) {
        throw ArgumentError('relative minutes must be positive');
      }
      final scheduledAt = now.add(Duration(minutes: trigger.minutes));
      return _Computed(
        type: 'relative',
        value: trigger.minutes.toString(),
        scheduledAt: scheduledAt,
      );
    }

    if (trigger is BucketTrigger) {
      final slot = _bucketSlots[trigger.bucket];
      if (slot == null) {
        throw ArgumentError(
          'bucket must be one of ${_bucketSlots.keys.toList()}',
        );
      }
      final todaySlot = DateTime(
        now.year,
        now.month,
        now.day,
        slot.hour,
        slot.minute,
      );
      final isPast = now.isAfter(todaySlot);
      final scheduledAt = isPast
          ? todaySlot.add(const Duration(days: 1))
          : todaySlot;
      return _Computed(
        type: 'bucket',
        value: trigger.bucket,
        scheduledAt: scheduledAt,
      );
    }

    throw ArgumentError('unsupported trigger');
  }
}

class _Computed {
  const _Computed({
    required this.type,
    required this.value,
    required this.scheduledAt,
  });
  final String type;
  final String value;
  final DateTime scheduledAt;
}

class _BucketSlot {
  const _BucketSlot(this.hour, this.minute);
  final int hour;
  final int minute;
}

const Map<String, _BucketSlot> _defaultBuckets = {
  'morning': _BucketSlot(8, 0),
  'noon': _BucketSlot(12, 0),
  'evening': _BucketSlot(17, 0),
  'night': _BucketSlot(21, 0),
};

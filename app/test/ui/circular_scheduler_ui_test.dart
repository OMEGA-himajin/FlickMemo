import 'package:app/src/ui/circular_scheduler.dart';
import 'package:app/src/domain/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detailed mode returns absolute trigger', () {
    final ui = CircularSchedulerUI();

    ui.selectExactTime(DateTime(2025, 1, 1, 10, 30));

    expect(ui.currentTrigger, isA<AbsoluteTrigger>());
    final trigger = ui.currentTrigger as AbsoluteTrigger;
    expect(trigger.at, DateTime(2025, 1, 1, 10, 30));
  });

  test('simple mode returns bucket and is preserved after mode toggles', () {
    final ui = CircularSchedulerUI();

    ui.selectBucket('evening');
    ui.switchMode(SchedulerMode.detailed);
    ui.switchMode(SchedulerMode.simple);

    expect(ui.currentTrigger, isA<BucketTrigger>());
    expect((ui.currentTrigger as BucketTrigger).bucket, 'evening');
  });

  test(
    'switching from detailed to simple keeps last selections for each mode',
    () {
      final ui = CircularSchedulerUI();

      ui.selectExactTime(DateTime(2025, 1, 1, 9));
      ui.selectBucket('night');
      ui.switchMode(SchedulerMode.detailed);

      expect(ui.currentTrigger, isA<AbsoluteTrigger>());
      final trigger = ui.currentTrigger as AbsoluteTrigger;
      expect(trigger.at, DateTime(2025, 1, 1, 9));
    },
  );
}

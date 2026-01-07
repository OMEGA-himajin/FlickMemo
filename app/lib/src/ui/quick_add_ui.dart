import 'package:app/src/application/input_mode_controller.dart';
import 'package:app/src/application/quick_add_controller.dart';
import 'package:app/src/ui/circular_scheduler.dart';

class QuickAddUI {
  QuickAddUI(this._controller, this._modeController, this._schedulerUI);

  final QuickAddController _controller;
  final InputModeController _modeController;
  final CircularSchedulerUI _schedulerUI;
  bool _dirty = false;

  void editTitle(String title) {
    _dirty = true;
    _controller.updateTitle(title);
    _modeController.updateTitle(title);
  }

  bool shouldWarnOnExit() => _dirty && _controller.hasUnsavedChanges;

  Future<SaveResult> save() async {
    final trigger = _schedulerUI.currentTrigger;
    if (trigger != null) {
      _controller.setTrigger(trigger);
    }
    final result = await _controller.save();
    _dirty = false;
    return result;
  }
}

import 'package:app/src/application/input_mode_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InputModeController controller;

  setUp(() {
    controller = InputModeController();
  });

  test('switching mode preserves text and color', () {
    controller.updateTitle('hello');
    controller.updateBody('world');
    controller.setColor('red');

    controller.switchMode('voice');

    expect(controller.state.inputMode, 'voice');
    expect(controller.state.title, 'hello');
    expect(controller.state.body, 'world');
    expect(controller.state.color, 'red');
  });

  test('starts voice only when permission granted', () {
    final started = controller.startVoice(permissionGranted: true);
    expect(started, isTrue);
    expect(controller.state.isListening, isTrue);

    final denied = controller.startVoice(permissionGranted: false);
    expect(denied, isFalse);
    expect(controller.state.isListening, isFalse);
  });
}

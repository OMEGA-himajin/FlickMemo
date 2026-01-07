import 'package:flutter_riverpod/flutter_riverpod.dart';

class InputModeState {
  const InputModeState({
    this.title = '',
    this.body,
    this.color,
    this.inputMode = 'text',
    this.isListening = false,
  });

  final String title;
  final String? body;
  final String? color;
  final String inputMode;
  final bool isListening;

  InputModeState copyWith({
    String? title,
    String? body,
    String? color,
    String? inputMode,
    bool? isListening,
  }) {
    return InputModeState(
      title: title ?? this.title,
      body: body ?? this.body,
      color: color ?? this.color,
      inputMode: inputMode ?? this.inputMode,
      isListening: isListening ?? this.isListening,
    );
  }
}

class InputModeController extends StateNotifier<InputModeState> {
  InputModeController() : super(const InputModeState());

  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  void updateBody(String? body) {
    state = state.copyWith(body: body);
  }

  void setColor(String? color) {
    state = state.copyWith(color: color);
  }

  void switchMode(String inputMode) {
    state = state.copyWith(inputMode: inputMode, isListening: false);
  }

  bool startVoice({required bool permissionGranted}) {
    if (!permissionGranted) {
      state = state.copyWith(isListening: false);
      return false;
    }
    state = state.copyWith(inputMode: 'voice', isListening: true);
    return true;
  }
}

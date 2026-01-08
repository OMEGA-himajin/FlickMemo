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

class InputModeController {
  InputModeController();

  InputModeState _state = const InputModeState();
  InputModeState get state => _state;

  void updateTitle(String title) {
    _state = _state.copyWith(title: title);
  }

  void updateBody(String? body) {
    _state = _state.copyWith(body: body);
  }

  void setColor(String? color) {
    _state = _state.copyWith(color: color);
  }

  void switchMode(String inputMode) {
    _state = _state.copyWith(inputMode: inputMode, isListening: false);
  }

  bool startVoice({required bool permissionGranted}) {
    if (!permissionGranted) {
      _state = _state.copyWith(isListening: false);
      return false;
    }
    _state = _state.copyWith(inputMode: 'voice', isListening: true);
    return true;
  }
}

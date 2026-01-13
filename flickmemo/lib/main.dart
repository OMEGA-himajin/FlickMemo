import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const FlickMemoApp());
}

class FlickMemoApp extends StatelessWidget {
  const FlickMemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlickMemo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF8C3C)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: '-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif',
      ),
      home: const RingGestureScreen(),
    );
  }
}

class RingGestureScreen extends StatefulWidget {
  const RingGestureScreen({super.key});

  @override
  State<RingGestureScreen> createState() => _RingGestureScreenState();
}

class _RingGestureScreenState extends State<RingGestureScreen> {
  final List<String> _options = const [
    '15分後',
    '1時間後',
    '明日',
    '来週',
    '1ヶ月後',
    'カスタム',
  ];

  bool _expanded = false;
  bool _isDragging = false;
  bool _isLongPress = false;
  bool _cancelActive = false;
  int _activeSegment = -1;
  String? _feedback;

  Timer? _longPressTimer;
  Timer? _feedbackTimer;
  final GlobalKey _stackKey = GlobalKey();

  double get _segmentAngle => 360 / _options.length;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _startLongPress(Offset globalPosition) {
    _isLongPress = false;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(milliseconds: 500), () {
      _isLongPress = true;
      _expand();
      _beginDrag(globalPosition);
    });
  }

  void _cancelLongPress() {
    _longPressTimer?.cancel();
  }

  void _expand() {
    setState(() {
      _expanded = true;
      _cancelActive = false;
    });
  }

  void _collapse() {
    setState(() {
      _expanded = false;
      _isDragging = false;
      _activeSegment = -1;
      _cancelActive = false;
    });
  }

  void _beginDrag(Offset globalPosition) {
    _isDragging = true;
    _updateActiveFromGlobal(globalPosition);
  }

  void _updateActiveFromGlobal(Offset globalPosition) {
    final center = _globalCenter();
    if (center == null) return;
    final dx = globalPosition.dx - center.dx;
    final dy = globalPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final cancelRadius = _currentInnerRadius();

    if (distance < cancelRadius) {
      setState(() {
        _cancelActive = true;
        _activeSegment = -1;
      });
      return;
    }

    var angle = math.atan2(dy, dx) * 180 / math.pi + 90;
    if (angle < 0) angle += 360;

    setState(() {
      _cancelActive = false;
      _activeSegment = (angle ~/ _segmentAngle) % _options.length;
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_expanded) {
      _beginDrag(event.position);
      return;
    }
    _startLongPress(event.position);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_isDragging && _expanded) {
      _updateActiveFromGlobal(event.position);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _cancelLongPress();
    if (_isDragging && _expanded) {
      _finishSelection();
    }
    _isDragging = false;
  }

  void _finishSelection() {
    if (_cancelActive) {
      _collapse();
      return;
    }
    if (_activeSegment >= 0) {
      final text = '選択: ${_options[_activeSegment]}';
      _showFeedback(text);
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _collapse();
      });
    }
  }

  void _showFeedback(String text) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedback = text;
    });
    _feedbackTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _feedback = null;
        });
      }
    });
  }

  Offset? _globalCenter() {
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final size = box.size;
    return box.localToGlobal(Offset(size.width / 2, size.height / 2));
  }

  double _currentOuterDiameter(double base) => _expanded ? base * 1.12 : base;

  double _currentInnerDiameter(double outer) => outer * 0.79;

  double _currentInnerRadius() {
    final size = MediaQuery.of(context).size;
    final minSide = math.min(size.width, size.height);
    final base = (minSide * 0.8).clamp(300.0, 420.0);
    final outer = _currentOuterDiameter(base);
    return _currentInnerDiameter(outer) / 2;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final minSide = math.min(size.width, size.height);
    final base = (minSide * 0.8).clamp(300.0, 420.0);
    final outerDiameter = _currentOuterDiameter(base);
    final innerDiameter = _currentInnerDiameter(outerDiameter);

    return Scaffold(
      body: SafeArea(
        child: Listener(
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          onPointerCancel: (_) => _cancelLongPress(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(color: Colors.white),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _expanded
                        ? '指を動かして選択 → 離して確定（中央でキャンセル）'
                        : '中央を長押しでプリセットを展開',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    key: _stackKey,
                    width: base + 40,
                    height: base + 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          width: outerDiameter,
                          height: outerDiameter,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(
                              _expanded ? 0.98 : 0.95,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  _expanded ? 0.12 : 0.08,
                                ),
                                blurRadius: _expanded ? 48 : 32,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _expanded ? 1 : 0,
                          child: Transform.scale(
                            scale: _expanded ? 1 : 0.95,
                            child: CustomPaint(
                              size: Size(outerDiameter, outerDiameter),
                              painter: _RingPainter(
                                options: _options,
                                activeIndex: _activeSegment,
                                outerDiameter: outerDiameter,
                                innerDiameter: innerDiameter,
                              ),
                            ),
                          ),
                        ),
                        ...List.generate(_options.length, (index) {
                          final angle =
                              -90 + _segmentAngle * index + _segmentAngle / 2;
                          final labelRadius =
                              ((outerDiameter / 2) + (innerDiameter / 2)) / 2;
                          final offset = Offset(
                            labelRadius * math.cos(angle * math.pi / 180),
                            labelRadius * math.sin(angle * math.pi / 180),
                          );
                          final selected = index == _activeSegment;
                          return AnimatedOpacity(
                            duration: const Duration(milliseconds: 250),
                            opacity: _expanded ? 1 : 0,
                            child: Transform.translate(
                              offset: offset,
                              child: Transform.scale(
                                scale: selected ? 1.08 : 1.0,
                                child: Text(
                                  _options[index],
                                  style: TextStyle(
                                    color: selected
                                        ? const Color(0xFFFF6B1A)
                                        : const Color(0xFFFF8C3C),
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                    fontSize: selected ? 16 : 15,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        _CenterButton(
                          expanded: _expanded,
                          cancelActive: _cancelActive,
                          onTapDown: (details) =>
                              _startLongPress(details.globalPosition),
                          onTapUp: () {
                            if (_expanded && !_isLongPress) {
                              _collapse();
                            }
                            _cancelLongPress();
                          },
                          onTapCancel: _cancelLongPress,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_feedback != null)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _feedback != null ? 1 : 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8C3C), Color(0xFFFF6B1A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x4DFF6B1A),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          _feedback ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({
    required this.expanded,
    required this.cancelActive,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  final bool expanded;
  final bool cancelActive;
  final void Function(TapDownDetails) onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: onTapDown,
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: expanded ? 150 : 140,
        height: expanded ? 150 : 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: cancelActive
                ? const [Color(0xFFFFB8B8), Color(0xFFFF8888)]
                : expanded
                    ? const [Color(0xFFE8E8E8), Color(0xFFD0D0D0)]
                    : const [Color(0xFFFF8C3C), Color(0xFFFF6B1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: cancelActive
                  ? Colors.red.withOpacity(0.35)
                  : Colors.orange.withOpacity(expanded ? 0.2 : 0.3),
              blurRadius: expanded ? 16 : 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            expanded ? '×' : '+',
            style: TextStyle(
              color: cancelActive
                  ? Colors.white
                  : expanded
                      ? const Color(0xFF666666)
                      : Colors.white,
              fontSize: expanded ? 48 : 56,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.options,
    required this.activeIndex,
    required this.outerDiameter,
    required this.innerDiameter,
  });

  final List<String> options;
  final int activeIndex;
  final double outerDiameter;
  final double innerDiameter;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRect = Rect.fromCircle(
      center: center,
      radius: outerDiameter / 2,
    );
    final innerRect = Rect.fromCircle(
      center: center,
      radius: innerDiameter / 2,
    );
    final sweep = 2 * math.pi / options.length;

    for (var i = 0; i < options.length; i++) {
      final start = -math.pi / 2 + i * sweep;
      final path = Path()
        ..addArc(outerRect, start, sweep)
        ..arcTo(innerRect, start + sweep, -sweep, false)
        ..close();

      final bool isActive = i == activeIndex;
      final Paint fill = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFFF8C3C).withOpacity(isActive ? 0.35 : 0.15);
      final Paint stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 3 : 2
        ..color = isActive
            ? const Color(0xFFFF8C3C)
            : const Color(0xFFFF8C3C).withOpacity(0.4);

      if (isActive) {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.scale(1.08);
        canvas.translate(-center.dx, -center.dy);
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        canvas.restore();
      } else {
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.activeIndex != activeIndex ||
        oldDelegate.outerDiameter != outerDiameter ||
        oldDelegate.innerDiameter != innerDiameter ||
        oldDelegate.options.length != options.length;
  }
}

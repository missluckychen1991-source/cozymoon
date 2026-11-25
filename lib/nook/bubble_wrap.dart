import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/ambient_service.dart';

/// Bubble Wrap Pop: tap or swipe across soft bubbles to pop them. When the
/// sheet is all popped, a fresh one rolls in. No timer, no score, no losing.
class BubbleWrapGame extends StatefulWidget {
  const BubbleWrapGame({super.key, this.sfx});
  final Sfx? sfx;

  static const cols = 6;

  @override
  State<BubbleWrapGame> createState() => _BubbleWrapGameState();
}

class _BubbleWrapGameState extends State<BubbleWrapGame> {
  static const _sheetColors = [
    Color(0xFFA8D5E2),
    Color(0xFFF4B6C2),
    Color(0xFFB8D8BA),
    Color(0xFFC9B6E4),
    Color(0xFFF7D9A8),
  ];

  late final Sfx _sfx = widget.sfx ?? Sfx();
  List<bool> _popped = [];
  int _rows = 0;
  double _cell = 0;
  int _total = 0;
  int _sheet = 0;
  bool _refilling = false;
  Timer? _refill;

  @override
  void dispose() {
    _refill?.cancel();
    if (widget.sfx == null) _sfx.dispose();
    super.dispose();
  }

  void _layout(Size size) {
    final cell = size.width / BubbleWrapGame.cols;
    final rows = (size.height / cell).floor().clamp(1, 40);
    if (rows != _rows || cell != _cell) {
      _rows = rows;
      _cell = cell;
      _popped = List.filled(rows * BubbleWrapGame.cols, false);
    }
  }

  Offset? _lastPointer;

  /// Pops every bubble along the finger's path, even on a fast swipe.
  void _swipeTo(Offset p) {
    final from = _lastPointer ?? p;
    _lastPointer = p;
    final steps = max(1, ((p - from).distance / (_cell / 4)).ceil());
    for (var i = 1; i <= steps; i++) {
      _popAt(Offset.lerp(from, p, i / steps)!);
    }
  }

  void _popAt(Offset p) {
    if (_refilling || _cell == 0) return;
    final c = (p.dx / _cell).floor();
    final r = (p.dy / _cell).floor();
    if (c < 0 || c >= BubbleWrapGame.cols || r < 0 || r >= _rows) return;
    final center = Offset((c + .5) * _cell, (r + .5) * _cell);
    if ((p - center).distance > _cell * .46) return;
    _pop(r * BubbleWrapGame.cols + c);
  }

  void _pop(int i) {
    if (_popped[i]) return;
    setState(() {
      _popped[i] = true;
      _total++;
    });
    HapticFeedback.selectionClick();
    _sfx.bubble();
    if (_popped.every((b) => b)) {
      _newSheet(delay: const Duration(milliseconds: 700));
    }
  }

  void _newSheet({Duration delay = Duration.zero}) {
    _refill?.cancel();
    setState(() => _refilling = true);
    _refill = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _popped = List.filled(_popped.length, false);
        _sheet++;
        _refilling = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = _sheetColors[_sheet % _sheetColors.length];
    return Scaffold(
      appBar: AppBar(title: const Text('Bubble Wrap Pop 🫧'), actions: [
        IconButton(
          key: const Key('bubbles-new-sheet'),
          tooltip: 'Fresh sheet',
          icon: const Icon(Icons.refresh),
          onPressed: () => _newSheet(),
        ),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            _refilling
                ? '✨ A fresh sheet is rolling in…'
                : _total == 0
                    ? 'Tap or swipe to pop. There is always more.'
                    : '🫧 $_total popped. Keep going as long as you like.',
            key: const Key('bubbles-count'),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: LayoutBuilder(builder: (context, c) {
              _layout(c.biggest);
              return Listener(
                key: const Key('bubble-sheet'),
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => _popAt(_lastPointer = e.localPosition),
                onPointerMove: (e) => _swipeTo(e.localPosition),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  opacity: _refilling ? 0.25 : 1,
                  child: Stack(children: [
                    for (var i = 0; i < _popped.length; i++)
                      Positioned(
                        left: (i % BubbleWrapGame.cols) * _cell,
                        top: (i ~/ BubbleWrapGame.cols) * _cell,
                        width: _cell,
                        height: _cell,
                        child: _Bubble(
                            key: Key('bubble-$i'),
                            popped: _popped[i],
                            size: _cell,
                            color: color),
                      ),
                  ]),
                ),
              );
            }),
          ),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(
      {super.key,
      required this.popped,
      required this.size,
      required this.color});
  final bool popped;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        width: popped ? size * .45 : size - 10,
        height: popped ? size * .45 : size - 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: popped
              ? null
              : RadialGradient(
                  center: const Alignment(-0.35, -0.4),
                  radius: 0.9,
                  colors: [
                    Colors.white.withValues(alpha: 0.95),
                    color.withValues(alpha: 0.75),
                    color,
                  ],
                  stops: const [0, 0.35, 1],
                ),
          color: popped ? color.withValues(alpha: 0.25) : null,
          boxShadow: popped
              ? null
              : [
                  BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2)),
                ],
        ),
      ),
    );
  }
}

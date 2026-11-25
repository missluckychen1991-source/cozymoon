import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sand Garden: drag a finger to rake calm lines through soft sand.
/// "Smooth the sand" gently wipes it clean. Nothing to finish or win.
class SandGarden extends StatefulWidget {
  const SandGarden({super.key, this.random});
  final Random? random;

  @override
  State<SandGarden> createState() => _SandGardenState();
}

enum _Tool { rake, finger }

class _Stone {
  const _Stone(this.at, this.radius, this.color);
  final Offset at; // fraction of the garden size
  final double radius;
  final Color color;
}

class _SandGardenState extends State<SandGarden>
    with SingleTickerProviderStateMixin {
  static const _maxPoints = 6000;

  late final Random _r = widget.random ?? Random();
  final _strokes = <List<Offset>>[];
  final _tines = <int>[];
  _Tool _tool = _Tool.rake;
  late final List<_Stone> _stones = _placeStones();
  late final AnimationController _smooth = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(_strokes.clear);
        _tines.clear();
        _smooth.reset();
      }
    });

  List<_Stone> _placeStones() {
    const colors = [Color(0xFF8C8179), Color(0xFFA39A90), Color(0xFF6F6760)];
    return [
      for (var i = 0; i < 3; i++)
        _Stone(
          Offset(0.2 + _r.nextDouble() * 0.6,
              0.15 + i * 0.3 + _r.nextDouble() * 0.1),
          14 + _r.nextDouble() * 12,
          colors[i],
        ),
    ];
  }

  int get _pointCount => _strokes.fold(0, (n, s) => n + s.length);

  void _start(Offset p) {
    if (_smooth.isAnimating) return;
    // Keep things smooth on older phones: forget the oldest lines.
    while (_pointCount > _maxPoints && _strokes.isNotEmpty) {
      _strokes.removeAt(0);
      _tines.removeAt(0);
    }
    setState(() {
      _strokes.add([p]);
      _tines.add(_tool == _Tool.rake ? 5 : 1);
    });
  }

  void _move(Offset p) {
    if (_smooth.isAnimating || _strokes.isEmpty) return;
    final s = _strokes.last;
    if ((s.last - p).distance < 3) return;
    setState(() => s.add(p));
  }

  void _smoothSand() {
    if (_strokes.isEmpty || _smooth.isAnimating) return;
    HapticFeedback.lightImpact();
    _smooth.forward();
  }

  @override
  void dispose() {
    _smooth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sand Garden 🪷')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(children: [
            SegmentedButton<_Tool>(
              segments: const [
                ButtonSegment(value: _Tool.rake, label: Text('Rake')),
                ButtonSegment(value: _Tool.finger, label: Text('Finger')),
              ],
              selected: {_tool},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _tool = v.first),
            ),
            const Spacer(),
            TextButton.icon(
              key: const Key('sand-smooth'),
              onPressed: _strokes.isEmpty ? null : _smoothSand,
              icon: const Icon(Icons.waves),
              label: const Text('Smooth'),
            ),
          ]),
        ),
        Text(
          _strokes.isEmpty
              ? 'Drag slowly. Make circles, waves, anything.'
              : 'Breathe out as you draw. 🌬️',
          key: const Key('sand-hint'),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LayoutBuilder(builder: (context, c) {
                return Listener(
                  key: const Key('sand-area'),
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) => _start(e.localPosition),
                  onPointerMove: (e) => _move(e.localPosition),
                  child: AnimatedBuilder(
                    animation: _smooth,
                    builder: (context, _) => CustomPaint(
                      size: c.biggest,
                      painter: _SandPainter(
                          _strokes, _tines, _stones, _smooth.value),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SandPainter extends CustomPainter {
  _SandPainter(this.strokes, this.tines, this.stones, this.wipe);
  final List<List<Offset>> strokes;
  final List<int> tines;
  final List<_Stone> stones;
  final double wipe; // 0..1, a soft wave sweeping the sand flat

  static const _sand = Color(0xFFEBDCC3);
  static const _groove = Color(0xFFCDB894);
  static const _ridge = Color(0xFFF8EEDB);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _sand);
    // A little grain so it feels like sand, not paper.
    final grain = Random(4);
    final dot = Paint()..color = _groove.withValues(alpha: 0.35);
    for (var i = 0; i < 500; i++) {
      canvas.drawCircle(
          Offset(grain.nextDouble() * size.width,
              grain.nextDouble() * size.height),
          0.8,
          dot);
    }

    final groove = Paint()
      ..color = _groove
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final ridge = Paint()
      ..color = _ridge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var s = 0; s < strokes.length; s++) {
      final pts = strokes[s];
      final n = tines[s];
      for (var k = 0; k < n; k++) {
        final off = (k - (n - 1) / 2) * 9.0;
        final path = _offsetPath(pts, off);
        canvas.drawPath(path, groove);
        canvas.save();
        canvas.translate(-1.2, -1.2);
        canvas.drawPath(path, ridge);
        canvas.restore();
      }
    }

    // Raked circles hug each stone, like a real zen garden.
    for (final st in stones) {
      final c = Offset(st.at.dx * size.width, st.at.dy * size.height);
      for (var ring = 1; ring <= 2; ring++) {
        canvas.drawCircle(c, st.radius + ring * 9, groove..strokeWidth = 2);
      }
      groove.strokeWidth = 3;
      canvas.drawCircle(c + const Offset(2, 3), st.radius,
          Paint()..color = Colors.black.withValues(alpha: 0.15));
      canvas.drawCircle(c, st.radius, Paint()..color = st.color);
      canvas.drawCircle(
          c - Offset(st.radius * .3, st.radius * .35),
          st.radius * .25,
          Paint()..color = Colors.white.withValues(alpha: 0.25));
    }

    if (wipe > 0) {
      final edge = wipe * (size.width + 80);
      canvas.drawRect(
          Rect.fromLTWH(0, 0, edge - 40, size.height), Paint()..color = _sand);
      canvas.drawRect(
        Rect.fromLTWH(edge - 40, 0, 40, size.height),
        Paint()
          ..shader = const LinearGradient(colors: [_sand, Color(0x00EBDCC3)])
              .createShader(Rect.fromLTWH(edge - 40, 0, 40, size.height)),
      );
    }
  }

  Path _offsetPath(List<Offset> pts, double off) {
    final path = Path();
    if (pts.length == 1) {
      path.addOval(
          Rect.fromCircle(center: pts.first + Offset(off, 0), radius: 1));
      return path;
    }
    for (var i = 0; i < pts.length; i++) {
      final a = pts[max(0, i - 1)];
      final b = pts[min(pts.length - 1, i + 1)];
      final d = b - a;
      final len = d.distance;
      final normal = len == 0 ? Offset.zero : Offset(-d.dy / len, d.dx / len);
      final p = pts[i] + normal * off;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

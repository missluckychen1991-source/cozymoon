import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/ambient_service.dart';

/// Smash Annoyance Rocks: tap floating pastel rocks to burst them into
/// sparkles. No timer, no score to beat, no losing. New rocks drift in forever.
class RocksGame extends StatefulWidget {
  const RocksGame({super.key, this.sfx, this.random});
  final Sfx? sfx;
  final Random? random;

  @override
  State<RocksGame> createState() => _RocksGameState();
}

class _Rock {
  _Rock(this.pos, this.vel, this.radius, this.color, this.label, this.seed);
  Offset pos;
  Offset vel;
  final double radius;
  final Color color;
  final String? label;
  final int seed;
}

class _Spark {
  _Spark(this.pos, this.vel, this.color);
  Offset pos;
  Offset vel;
  final Color color;
  double life = 1;
}

class _RocksGameState extends State<RocksGame>
    with SingleTickerProviderStateMixin {
  static const _pastels = [
    Color(0xFFF4B6C2),
    Color(0xFFB8D8BA),
    Color(0xFFF7D9A8),
    Color(0xFFC9B6E4),
    Color(0xFFA8D5E2),
    Color(0xFFF2B866),
  ];

  late final Random _r = widget.random ?? Random();
  late final Sfx _sfx = widget.sfx ?? Sfx();
  late final AnimationController _ticker =
      AnimationController(vsync: this, duration: const Duration(days: 1))
        ..addListener(_tick);
  final _rocks = <_Rock>[];
  final _sparks = <_Spark>[];
  final _annoyance = TextEditingController();
  Size _size = Size.zero;
  Duration _last = Duration.zero;
  int smashed = 0;
  String? _label;

  @override
  void initState() {
    super.initState();
    _ticker.forward();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _annoyance.dispose();
    if (widget.sfx == null) _sfx.dispose();
    super.dispose();
  }

  void _spawn() {
    if (_size == Size.zero) return;
    final radius = 30 + _r.nextDouble() * 22;
    final x = radius + _r.nextDouble() * max(1, _size.width - 2 * radius);
    _rocks.add(_Rock(
      Offset(x, _size.height + radius),
      Offset((_r.nextDouble() - 0.5) * 30, -(25 + _r.nextDouble() * 35)),
      radius,
      _pastels[_r.nextInt(_pastels.length)],
      _label != null && _r.nextBool() ? _label : null,
      _r.nextInt(1 << 20),
    ));
  }

  void _tick() {
    final now = _ticker.lastElapsedDuration ?? Duration.zero;
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    while (_rocks.length < 6) {
      _spawn();
      if (_size == Size.zero) break;
    }
    for (final rock in _rocks) {
      rock.pos += rock.vel * dt;
      if (rock.pos.dx < rock.radius ||
          rock.pos.dx > _size.width - rock.radius) {
        rock.vel = Offset(-rock.vel.dx, rock.vel.dy);
      }
    }
    _rocks.removeWhere((rk) => rk.pos.dy < -rk.radius * 2);
    for (final s in _sparks) {
      s.pos += s.vel * dt;
      s.vel = s.vel * 0.96 + const Offset(0, 40) * dt;
      s.life -= dt * 1.1;
    }
    _sparks.removeWhere((s) => s.life <= 0);
    setState(() {});
  }

  void _tap(Offset p) {
    for (var i = _rocks.length - 1; i >= 0; i--) {
      final rock = _rocks[i];
      if ((rock.pos - p).distance <= rock.radius + 8) {
        _rocks.removeAt(i);
        for (var k = 0; k < 22; k++) {
          final a = _r.nextDouble() * 2 * pi;
          final speed = 60 + _r.nextDouble() * 160;
          _sparks.add(_Spark(rock.pos, Offset(cos(a), sin(a)) * speed,
              k.isEven ? rock.color : Colors.white));
        }
        smashed++;
        HapticFeedback.lightImpact();
        _sfx.pop();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smash Annoyance Rocks 🪨')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: _annoyance,
            maxLength: 24,
            decoration: const InputDecoration(
              hintText: "Optional: what's annoying you?",
              counterText: '',
            ),
            onChanged: (v) => _label = v.trim().isEmpty ? null : v.trim(),
          ),
        ),
        Text(
            smashed == 0
                ? 'Tap the rocks. No timer, no losing.'
                : '✨ $smashed smashed. Keep going as long as you like.',
            key: const Key('rocks-count')),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            _size = c.biggest;
            return GestureDetector(
              key: const Key('rocks-area'),
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _tap(d.localPosition),
              child: CustomPaint(
                size: c.biggest,
                painter: _RocksPainter(
                    _rocks, _sparks, Theme.of(context).colorScheme.onSurface),
              ),
            );
          }),
        ),
      ]),
    );
  }
}

class _RocksPainter extends CustomPainter {
  _RocksPainter(this.rocks, this.sparks, this.text);
  final List<_Rock> rocks;
  final List<_Spark> sparks;
  final Color text;

  @override
  void paint(Canvas canvas, Size size) {
    for (final rock in rocks) {
      final r = Random(rock.seed);
      final path = Path();
      const n = 9;
      for (var i = 0; i < n; i++) {
        final a = i / n * 2 * pi;
        final rr = rock.radius * (0.82 + r.nextDouble() * 0.22);
        final p = rock.pos + Offset(cos(a), sin(a)) * rr;
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawShadow(path, Colors.black26, 3, false);
      canvas.drawPath(path, Paint()..color = rock.color);
      canvas.drawCircle(
          rock.pos - Offset(rock.radius * .3, rock.radius * .3),
          rock.radius * .18,
          Paint()..color = Colors.white.withValues(alpha: 0.5));
      if (rock.label != null) {
        final tp = TextPainter(
          text: TextSpan(
              text: rock.label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF2D242C))),
          textDirection: TextDirection.ltr,
          maxLines: 2,
          textAlign: TextAlign.center,
          ellipsis: '…',
        )..layout(maxWidth: rock.radius * 1.6);
        tp.paint(canvas, rock.pos - Offset(tp.width / 2, tp.height / 2));
      }
    }
    for (final s in sparks) {
      canvas.drawCircle(s.pos, 3 * s.life + 1,
          Paint()..color = s.color.withValues(alpha: s.life.clamp(0, 1)));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/ambient_service.dart';

class TeaKind {
  const TeaKind(this.name, this.emoji, this.color);
  final String name;
  final String emoji;
  final Color color;
}

const teaKinds = [
  TeaKind('Chamomile', '🌼', Color(0xFFE8B84A)),
  TeaKind('Matcha', '🍵', Color(0xFF8DB86B)),
  TeaKind('Rooibos', '🍂', Color(0xFFC0643A)),
  TeaKind('Earl Grey', '🫖', Color(0xFF9A6A45)),
];

/// Tea Pour: press and hold to pour tea into a cup. It can never spill.
/// When it is full the cup glows warm and a soft bell rings.
class TeaPour extends StatefulWidget {
  const TeaPour({super.key, this.sfx, this.fillSeconds = 5});
  final Sfx? sfx;
  final double fillSeconds;

  @override
  State<TeaPour> createState() => _TeaPourState();
}

class _TeaPourState extends State<TeaPour> with TickerProviderStateMixin {
  late final Sfx _sfx = widget.sfx ?? Sfx();
  late final AnimationController _ticker =
      AnimationController(vsync: this, duration: const Duration(days: 1))
        ..addListener(_tick);
  late final AnimationController _glow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400));
  TeaKind _tea = teaKinds.first;
  double _fill = 0;
  double _tilt = 0;
  bool _holding = false;
  bool _full = false;
  int _cups = 0;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker.forward();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _glow.dispose();
    _sfx.stopPour();
    if (widget.sfx == null) _sfx.dispose();
    super.dispose();
  }

  bool get _pouring => _holding && !_full && _tilt > 0.8;

  void _tick() {
    final now = _ticker.lastElapsedDuration ?? Duration.zero;
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    final wantTilt = _holding && !_full ? 1.0 : 0.0;
    final tilt = _tilt + (wantTilt - _tilt) * min(1.0, dt * 8);
    var fill = _fill;
    if (_pouring) fill = min(1.0, fill + dt / widget.fillSeconds);
    if (tilt == _tilt && fill == _fill) return;
    setState(() {
      _tilt = (tilt - wantTilt).abs() < 0.001 ? wantTilt : tilt;
      _fill = fill;
    });
    if (_fill >= 1 && !_full) _finish();
  }

  void _down() {
    if (_full) return;
    setState(() => _holding = true);
    _sfx.startPour();
  }

  void _up() {
    setState(() => _holding = false);
    _sfx.stopPour();
  }

  void _finish() {
    setState(() {
      _full = true;
      _cups++;
    });
    _sfx.stopPour();
    _sfx.chime();
    HapticFeedback.mediumImpact();
    _glow.repeat(reverse: true);
  }

  void _another() {
    _glow.stop();
    _glow.value = 0;
    setState(() {
      _fill = 0;
      _full = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final hint = _full
        ? 'Your ${_tea.name.toLowerCase()} is ready. Take a slow, warm sip ☕'
        : _holding
            ? 'Pouring… breathe in the steam.'
            : _fill == 0
                ? 'Press and hold anywhere to pour.'
                : 'Hold again whenever you like. It will never spill.';
    return Scaffold(
      appBar: AppBar(title: const Text('Tea Pour 🫖')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            for (final k in teaKinds)
              ChoiceChip(
                label: Text('${k.emoji} ${k.name}'),
                selected: _tea == k,
                onSelected: _fill > 0 && !_full
                    ? null
                    : (_) => setState(() {
                          _tea = k;
                          if (_full) _another();
                        }),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(hint,
              key: const Key('tea-hint'),
              style: t.bodyLarge,
              textAlign: TextAlign.center),
        ),
        Expanded(
          child: Listener(
            key: const Key('tea-area'),
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => _down(),
            onPointerUp: (_) => _up(),
            onPointerCancel: (_) => _up(),
            child: AnimatedBuilder(
              animation: _glow,
              builder: (context, _) => CustomPaint(
                size: Size.infinite,
                painter: _TeaPainter(
                  fill: _fill,
                  tilt: _tilt,
                  pouring: _pouring,
                  tea: _tea.color,
                  glow: _full ? 0.5 + 0.5 * _glow.value : 0,
                  time: (_ticker.lastElapsedDuration ?? Duration.zero)
                          .inMilliseconds /
                      1000,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: _full
              ? FilledButton.tonal(
                  key: const Key('tea-another'),
                  onPressed: _another,
                  child: Text(_cups == 1
                      ? 'Pour another cup'
                      : 'Pour another cup ($_cups so far)'))
              : const SizedBox(height: 40),
        ),
      ]),
    );
  }
}

class _TeaPainter extends CustomPainter {
  _TeaPainter({
    required this.fill,
    required this.tilt,
    required this.pouring,
    required this.tea,
    required this.glow,
    required this.time,
  });
  final double fill;
  final double tilt;
  final bool pouring;
  final Color tea;
  final double glow;
  final double time;

  static const _porcelain = Color(0xFFFFFBF5);
  static const _pot = Color(0xFFD97757);
  static const _outline = Color(0xFF6B4E45);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cupW = min(w * 0.5, 220.0);
    final cupH = cupW * 0.72;
    final cupTop = h * 0.55;
    final cupRect = Rect.fromLTWH((w - cupW) / 2, cupTop, cupW, cupH);
    final line = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    if (glow > 0) {
      canvas.drawCircle(
        cupRect.center,
        cupW * (0.9 + 0.1 * glow),
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFC870).withValues(alpha: 0.55 * glow),
            const Color(0x00FFC870),
          ]).createShader(
              Rect.fromCircle(center: cupRect.center, radius: cupW)),
      );
    }

    // Saucer.
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w / 2, cupRect.bottom + 6),
            width: cupW * 1.5,
            height: 22),
        Paint()..color = _porcelain);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w / 2, cupRect.bottom + 6),
            width: cupW * 1.5,
            height: 22),
        line);

    // Cup body: a soft bowl shape.
    final cup = Path()
      ..moveTo(cupRect.left, cupRect.top)
      ..lineTo(cupRect.right, cupRect.top)
      ..cubicTo(
          cupRect.right,
          cupRect.bottom - cupH * .2,
          cupRect.right - cupW * .12,
          cupRect.bottom,
          cupRect.center.dx,
          cupRect.bottom)
      ..cubicTo(cupRect.left + cupW * .12, cupRect.bottom, cupRect.left,
          cupRect.bottom - cupH * .2, cupRect.left, cupRect.top)
      ..close();
    canvas.drawPath(cup, Paint()..color = _porcelain);

    // Tea inside, clipped to the cup, with a gentle wobble on top.
    if (fill > 0) {
      canvas.save();
      canvas.clipPath(cup);
      final level = cupRect.bottom - (cupH - 8) * fill;
      final wave = Path()..moveTo(cupRect.left, cupRect.bottom);
      for (var x = cupRect.left; x <= cupRect.right; x += 4) {
        final amp = pouring ? 2.5 : 1.0;
        wave.lineTo(x, level + sin(x / 14 + time * 4) * amp);
      }
      wave
        ..lineTo(cupRect.right, cupRect.bottom)
        ..close();
      canvas.drawPath(wave, Paint()..color = tea);
      canvas.restore();
    }
    canvas.drawPath(cup, line);

    // Handle.
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(cupRect.right + 4, cupRect.top + cupH * .38),
            width: cupW * .32,
            height: cupH * .45),
        -pi / 2,
        pi,
        false,
        line..strokeWidth = 7);
    line.strokeWidth = 3;

    // Steam when the cup is full.
    if (glow > 0) {
      final steam = Paint()
        ..color = _outline.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (var i = -1; i <= 1; i++) {
        final x0 = w / 2 + i * cupW * .22;
        final p = Path()..moveTo(x0, cupRect.top - 10);
        for (var y = 0.0; y < 60; y += 4) {
          p.lineTo(x0 + sin(y / 10 + time * 2 + i) * 6, cupRect.top - 10 - y);
        }
        canvas.drawPath(p, steam);
      }
    }

    // Teapot, tilting toward the cup while held.
    final potW = min(w * 0.42, 190.0);
    final potCenter = Offset(max(potW * 0.75, w / 2 - potW * 0.55), h * 0.2);
    final spoutTip = Offset(potW * .78, -potW * .18);
    final angle = tilt * 0.75;
    canvas.save();
    canvas.translate(potCenter.dx, potCenter.dy);
    canvas.rotate(angle);
    final body =
        Rect.fromCenter(center: Offset.zero, width: potW, height: potW * .7);
    final spout = Path()
      ..moveTo(potW * .38, potW * .05)
      ..quadraticBezierTo(potW * .62, 0, spoutTip.dx, spoutTip.dy)
      ..lineTo(spoutTip.dx + 6, spoutTip.dy + 8)
      ..quadraticBezierTo(potW * .6, potW * .12, potW * .4, potW * .2)
      ..close();
    canvas.drawPath(spout, Paint()..color = _pot);
    canvas.drawPath(spout, line);
    canvas.drawOval(body, Paint()..color = _pot);
    canvas.drawOval(body, line);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(-potW * .5, 0),
            width: potW * .35,
            height: potW * .42),
        pi / 2,
        pi,
        false,
        line..strokeWidth = 7);
    line.strokeWidth = 3;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, -potW * .37), width: potW * .4, height: 16),
        Paint()..color = _pot);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, -potW * .37), width: potW * .4, height: 16),
        line);
    canvas.drawCircle(Offset(0, -potW * .45), 7, Paint()..color = _outline);
    canvas.restore();

    // The stream of tea from spout to cup.
    if (pouring) {
      final tip = potCenter +
          Offset(spoutTip.dx * cos(angle) - spoutTip.dy * sin(angle),
              spoutTip.dx * sin(angle) + spoutTip.dy * cos(angle));
      final level = cupRect.bottom - (cupH - 8) * fill;
      final stream = Path()
        ..moveTo(tip.dx, tip.dy)
        ..quadraticBezierTo(tip.dx + 18, tip.dy + 10, w / 2, level);
      canvas.drawPath(
          stream,
          Paint()
            ..color = tea
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6 + sin(time * 20)
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

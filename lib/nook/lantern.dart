import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Breathing Tea Lantern: hold the lantern and breathe with it. It grows for
/// a 4-second inhale and dims for a 6-second exhale.
class BreathingLantern extends StatefulWidget {
  const BreathingLantern({super.key});

  static const inhale = Duration(seconds: 4);
  static const exhale = Duration(seconds: 6);

  @override
  State<BreathingLantern> createState() => _BreathingLanternState();
}

class _BreathingLanternState extends State<BreathingLantern>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _holding = false;
  bool _inhaling = true;
  int breaths = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _cycle() async {
    while (_holding && mounted) {
      setState(() => _inhaling = true);
      HapticFeedback.selectionClick();
      await _c.animateTo(1,
          duration: BreathingLantern.inhale * (1 - _c.value),
          curve: Curves.easeInOut);
      if (!_holding || !mounted) break;
      setState(() => _inhaling = false);
      HapticFeedback.selectionClick();
      await _c.animateTo(0,
          duration: BreathingLantern.exhale * _c.value,
          curve: Curves.easeInOut);
      if (!mounted) break;
      if (_holding) setState(() => breaths++);
    }
  }

  void _start() {
    if (_holding) return;
    _holding = true;
    _cycle();
  }

  void _stop() {
    _holding = false;
    if (mounted) {
      setState(() => _inhaling = false);
      _c.animateTo(0,
          duration: BreathingLantern.exhale * _c.value, curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final hint = !_holding
        ? 'Press and hold the lantern'
        : (_inhaling ? 'Breathe in… 4' : 'Breathe out slowly… 6');
    return Scaffold(
      appBar: AppBar(title: const Text('Breathing Tea Lantern 🏮')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(hint, key: const Key('lantern-hint'), style: t.headlineSmall),
          const SizedBox(height: 40),
          Listener(
            key: const Key('lantern'),
            onPointerDown: (_) => _start(),
            onPointerUp: (_) => _stop(),
            onPointerCancel: (_) => _stop(),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final v = _c.value;
                return Container(
                  width: 140 + 120 * v,
                  height: 140 + 120 * v,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Color.lerp(CozyColors.amber.withValues(alpha: .55),
                          const Color(0xFFFFE3A8), v)!,
                      CozyColors.terracotta.withValues(alpha: .15 + .35 * v),
                    ]),
                    boxShadow: [
                      BoxShadow(
                        color: CozyColors.amber.withValues(alpha: .25 + .5 * v),
                        blurRadius: 30 + 50 * v,
                        spreadRadius: 4 + 20 * v,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text('🏮', style: TextStyle(fontSize: 48 + 30 * v)),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
          Text(
              breaths == 0
                  ? 'Let go any time. There is no wrong way.'
                  : '$breaths calm breaths 💛',
              style: t.bodyLarge),
        ]),
      ),
    );
  }
}

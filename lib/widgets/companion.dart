import 'package:flutter/material.dart';

import '../theme.dart';

/// Placeholder companion: a cat holding tea that gently bobs. Swap for real
/// art (Rive or Lottie) later.
class Companion extends StatefulWidget {
  const Companion({super.key, this.size = 120});
  final double size;

  @override
  State<Companion> createState() => _CompanionState();
}

class _CompanionState extends State<Companion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -6 * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            CozyColors.amber.withValues(alpha: 0.55),
            CozyColors.terracotta.withValues(alpha: 0.15),
          ]),
        ),
        alignment: Alignment.center,
        child: Text('🐱☕', style: TextStyle(fontSize: widget.size * 0.32)),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Efecto gelatina para un elemento completo: al soltar el dedo, [child]
/// tiembla alternando ancho y alto con amortiguación (unos dos ciclos)
/// hasta quedarse quieto, como una gota de agua.
///
/// Escucha el puntero sin competir con otros gestos, así que se combina con
/// `GestureDetector` y con `LiquidStretch` (que estira mientras se mantiene
/// el dedo). El cristal sigue la deformación porque usa [Transform].
class JellyWobble extends StatefulWidget {
  const JellyWobble({
    required this.child,
    this.enabled = true,
    this.amplitude = .09,
    this.duration = const Duration(milliseconds: 820),
    super.key,
  });

  final Widget child;
  final bool enabled;

  /// Deformación máxima al empezar a temblar (0.09 = 9 % más ancho).
  final double amplitude;
  final Duration duration;

  @override
  State<JellyWobble> createState() => _JellyWobbleState();
}

class _JellyWobbleState extends State<JellyWobble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void dispose() {
    _wobble.dispose();
    super.dispose();
  }

  void _start(PointerEvent _) {
    if (widget.enabled) _wobble.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _wobble.stop(),
      onPointerUp: _start,
      onPointerCancel: _start,
      child: AnimatedBuilder(
        animation: _wobble,
        builder: (context, child) {
          if (!_wobble.isAnimating) return child!;
          final t = _wobble.value;
          // Oscilación amortiguada: positiva = más ancha y baja.
          final d =
              widget.amplitude *
              math.exp(-4.2 * t) *
              math.sin(2 * math.pi * 2.3 * t + math.pi / 2);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(1 + d, 1 - d * .85, 1),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

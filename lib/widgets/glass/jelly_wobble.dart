import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Reacción de gota de agua para un elemento completo:
///
/// 1. **Al presionar** se aplasta hacia abajo, como una gota que recibe
///    presión: más ancha y más baja.
/// 2. **Al soltar** rebota desde ese aplastamiento y tiembla alternando
///    ancho y alto con amortiguación (unos tres ciclos) hasta quedarse
///    quieta. El rebote parte exactamente de la forma aplastada, sin saltos.
///
/// Escucha el puntero sin competir con otros gestos, así que se combina con
/// `GestureDetector` y con `LiquidStretch` (que la infla y la estira hacia
/// el dedo). El cristal sigue la deformación porque usa [Transform].
class JellyWobble extends StatefulWidget {
  const JellyWobble({
    required this.child,
    this.enabled = true,
    this.amplitude = .16,
    this.squash = .10,
    this.cycles = 3,
    this.duration = const Duration(milliseconds: 1100),
    super.key,
  });

  final Widget child;
  final bool enabled;

  /// Deformación máxima del rebote (0.16 = 16 % más ancha).
  final double amplitude;

  /// Aplastamiento mientras se presiona (0.10 = 10 % más ancha).
  final double squash;

  /// Cuántos temblores da antes de quedarse quieta.
  final double cycles;
  final Duration duration;

  /// Punto fijo de la deformación: algo por debajo del centro, para que
  /// se aplaste "hacia abajo" como una gota apoyada.
  static const anchor = Alignment(0, .45);

  @override
  State<JellyWobble> createState() => _JellyWobbleState();
}

class _JellyWobbleState extends State<JellyWobble>
    with TickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );

  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Listenable _motion = Listenable.merge([_press, _wobble]);

  /// Aplastamiento en el instante de soltar (punto de partida del rebote).
  double _releaseSquash = 0;
  bool _held = false;

  @override
  void dispose() {
    _press.dispose();
    _wobble.dispose();
    super.dispose();
  }

  void _onDown(PointerDownEvent _) {
    if (!widget.enabled) return;
    _held = true;
    _wobble.stop();
    _press.forward(from: 0);
  }

  void _onRelease(PointerEvent _) {
    if (!widget.enabled || !_held) return;
    _held = false;
    _releaseSquash = _squashNow;
    _press.stop();
    _press.value = 0;
    _wobble.forward(from: 0);
  }

  double get _squashNow =>
      widget.squash * Curves.easeOutCubic.transform(_press.value);

  /// Deformación actual: positiva = más ancha y baja, negativa = más alta.
  double get _deformation {
    if (_held) return _squashNow;
    if (!_wobble.isAnimating) return 0;
    final t = _wobble.value;
    final w = 2 * math.pi * widget.cycles;
    final decay = math.exp(-3.6 * t);
    // Parte de la forma aplastada (cos) y se lanza hacia el lado contrario
    // con la amplitud del rebote (sin), así no hay salto al soltar.
    return decay *
        (_releaseSquash * math.cos(w * t) - widget.amplitude * math.sin(w * t));
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerUp: _onRelease,
      onPointerCancel: _onRelease,
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, child) {
          final d = _deformation;
          if (d == 0) return child!;
          return Transform(
            alignment: JellyWobble.anchor,
            // Conserva el volumen aproximado: lo que gana de ancho lo
            // pierde de alto.
            transform: Matrix4.diagonal3Values(1 + d, 1 / (1 + d), 1),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

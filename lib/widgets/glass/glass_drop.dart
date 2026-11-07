import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Gota de cristal 3D que se posa sobre [child] (normalmente un ícono).
///
/// - Es cristal real con su propio layer: refracta y aumenta un poco lo que
///   tiene debajo, incluido el cristal del botón que la contiene.
/// - **Gelatina:** al presionar se aplasta; al soltar tiembla alternando
///   ancho y alto con amortiguación, como una gota de agua, hasta quedarse
///   quieta.
///
/// Cada gota visible añade una captura de fondo; úsala en botones
/// protagonistas, no en listas largas.
class GlassDrop extends StatefulWidget {
  const GlassDrop({
    required this.size,
    this.child,
    this.shape = const LiquidOval(),
    this.settings = dropSettings,
    this.fake = false,
    this.magnify = 1.06,
    this.jelly = true,
    this.visibility = 1,
    super.key,
  });

  /// Tamaño de la gota (no del botón que la contiene).
  final Size size;

  /// Lo que la gota cubre; se dibuja debajo, aumentado por [magnify].
  final Widget? child;
  final LiquidShape shape;
  final LiquidGlassSettings settings;

  /// Usa FakeGlass, para coincidir con un layer padre falso.
  final bool fake;

  /// Aumento del contenido bajo la gota (1.06 = 6 %).
  final double magnify;

  /// Si reacciona al toque con el efecto gelatina.
  final bool jelly;

  /// Materialización del cristal, de 0 (invisible) a 1, para hacerla
  /// aparecer o desaparecer suavemente.
  final double visibility;

  /// Lente limpia, sin escarcha, con borde que dobla y separa un poco los
  /// colores, como una gota de agua.
  static const dropSettings = LiquidGlassSettings(
    refractionHeight: 12,
    refractionAmount: 14,
    dispersion: -.25,
    frost: 0,
    highlight: .9,
    contourStrength: .3,
  );

  @override
  State<GlassDrop> createState() => _GlassDropState();
}

class _GlassDropState extends State<GlassDrop> with TickerProviderStateMixin {
  /// Aplastamiento mientras se presiona (0 → 1).
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 110),
  );

  /// Temblor amortiguado tras soltar (0 → 1 = tiempo normalizado).
  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  late final Listenable _motion = Listenable.merge([_press, _wobble]);

  /// Amplitud con la que empezó el temblor.
  double _amplitude = 0;
  bool _pressed = false;

  @override
  void dispose() {
    _press.dispose();
    _wobble.dispose();
    super.dispose();
  }

  void _onDown(PointerDownEvent _) {
    if (!widget.jelly) return;
    _pressed = true;
    _wobble.stop();
    _press.forward();
  }

  void _onUp(PointerEvent _) {
    if (!widget.jelly || !_pressed) return;
    _pressed = false;
    // Al menos un temblor visible aunque el toque haya sido muy corto.
    _amplitude = math.max(_press.value, .7);
    _press.value = 0;
    _wobble.forward(from: 0);
  }

  /// Deformación actual: positiva = más ancha y baja, negativa = más alta.
  double get _deformation {
    if (_pressed || _press.isAnimating) {
      return Curves.easeOut.transform(_press.value);
    }
    if (!_wobble.isAnimating) return 0;
    final t = _wobble.value;
    // Oscilación amortiguada: ~2.3 ciclos que se apagan.
    return _amplitude * math.exp(-4.2 * t) * math.cos(2 * math.pi * 2.3 * t);
  }

  @override
  Widget build(BuildContext context) {
    final drop = AnimatedBuilder(
      animation: _motion,
      builder: (context, child) {
        final d = _deformation;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(1 + .16 * d, 1 - .13 * d, 1),
          child: child,
        );
      },
      child: IgnorePointer(
        child: LiquidGlass.withOwnLayer(
          settings: widget.settings,
          fake: widget.fake,
          shape: widget.shape,
          appearance: LiquidGlassAppearance(visibility: widget.visibility),
          child: SizedBox.fromSize(size: widget.size),
        ),
      ),
    );

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerUp: _onUp,
      onPointerCancel: _onUp,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (widget.child != null)
            Transform.scale(scale: widget.magnify, child: widget.child),
          drop,
        ],
      ),
    );
  }
}

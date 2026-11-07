import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Gota de cristal real que se posa sobre [child] y lo aumenta un poco.
///
/// Tiene su propio layer, así que refracta también el cristal que tenga
/// debajo. Se usa para replicar la gota de reposo del menú durante la
/// transición del buscador; para botones completos usa `LiquidGlassButton`
/// con `lens`.
class GlassDrop extends StatelessWidget {
  const GlassDrop({
    required this.size,
    this.child,
    this.shape = const LiquidOval(),
    this.settings = dropSettings,
    this.fake = false,
    this.magnify = 1.06,
    this.visibility = 1,
    super.key,
  });

  /// Tamaño de la gota.
  final Size size;

  /// Lo que la gota cubre; se dibuja debajo, aumentado por [magnify].
  final Widget? child;
  final LiquidShape shape;
  final LiquidGlassSettings settings;

  /// Usa FakeGlass, para coincidir con un layer padre falso.
  final bool fake;

  /// Aumento del contenido bajo la gota (1.06 = 6 %).
  final double magnify;

  /// Materialización del cristal, de 0 (invisible) a 1.
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
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (child != null) Transform.scale(scale: magnify, child: child),
        IgnorePointer(
          child: LiquidGlass.withOwnLayer(
            settings: settings,
            fake: fake,
            shape: shape,
            appearance: LiquidGlassAppearance(visibility: visibility),
            child: SizedBox.fromSize(size: size),
          ),
        ),
      ],
    );
  }
}

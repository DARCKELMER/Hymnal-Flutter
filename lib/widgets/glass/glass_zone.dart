import 'package:flutter/material.dart';
import 'package:hymnal_app/widgets/glass/glass_scope.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Una zona de cristal: **un** [LiquidGlassLayer] con la configuración de
/// [GlassScope] para todos los componentes de cristal que contiene.
///
/// Reglas (ver el plan, 3.4):
/// - Un layer por zona de pantalla (barra inferior, encabezado…): cada
///   layer copia el fondo y esa copia es lo caro.
/// - Máximo 16 formas por layer.
/// - No pongas cristal sobre cristal.
///
/// Con [blend] mayor que 0, los componentes agrupados (`grouped: true`) se
/// funden como gotas al acercarse.
class GlassZone extends StatelessWidget {
  const GlassZone({
    required this.child,
    this.blend = 0,
    this.refractionHeight,
    super.key,
  });

  final Widget child;

  /// Mezcla entre formas agrupadas (0 = sin grupo).
  final double blend;

  /// Ancho del bisel (refracción del borde). Por defecto el del agua
  /// brillante (26 dp); en formas angostas conviene menos, o el bisel
  /// ocupa todo el interior y lo deforma en franjas.
  final double? refractionHeight;

  @override
  Widget build(BuildContext context) {
    final scope = GlassScope.of(context);
    return LiquidGlassLayer(
      settings: refractionHeight == null
          ? scope.settings
          : scope.settings.copyWith(refractionHeight: refractionHeight),
      defaultAppearance: const LiquidGlassAppearance.ios27Clear(),
      child: blend > 0
          ? LiquidGlassBlendGroup(blend: blend, child: child)
          : child,
    );
  }
}

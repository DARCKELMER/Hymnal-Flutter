import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hymnal_app/widgets/glass/jelly_wobble.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Botón de cristal líquido suelto, que se comporta como **una gota entera**:
///
/// 1. **Estira** ([LiquidStretch]): al presionar se infla y, si se arrastra
///    el dedo, se estira hacia él.
/// 2. **Gelatina** ([JellyWobble]): al soltar tiembla alternando ancho y
///    alto hasta quedarse quieto.
/// 3. **Brillo táctil** ([GlassGlow]): un resplandor suave sigue el dedo.
/// 4. Con [lens], el botón usa su propia óptica de gota (borde más grueso y
///    brillante, leve prisma) en un layer propio; sin ella, comparte el
///    cristal del [LiquidGlassLayer] padre.
///
/// Con [grouped] (sin [lens]) se funde con sus vecinos dentro de un
/// [LiquidGlassBlendGroup].
class LiquidGlassButton extends StatelessWidget {
  const LiquidGlassButton({
    required this.semanticLabel,
    required this.onTap,
    required this.child,
    this.size = const Size.square(64),
    this.shape = const LiquidOval(),
    this.appearance,
    this.grouped = false,
    this.lens,
    this.fake = false,
    this.interactionScale = 1.10,
    this.stretch = .5,
    this.wrapSemantics = true,
    this.glassKey,
    this.jelly = true,
    this.iconMagnify = 1,
    this.glowColor = const Color(0x33FFFFFF),
    this.haptics = true,
    super.key,
  }) : assert(
         lens == null || !grouped,
         'Un botón con lente propia no puede fundirse en un blend group.',
       );

  /// Estiramiento mínimo para que [LiquidStretch] conserve su estructura.
  static const _minStretch = 1e-4;

  /// Óptica de gota para los botones redondos protagonistas.
  ///
  /// Pensada para 48–84 dp: el bisel ocupa el borde y dobla el fondo con
  /// fuerza, como una gota de agua, y separa un poco los colores.
  static const dropLens = LiquidGlassSettings(
    refractionHeight: 16,
    refractionAmount: 22,
    dispersion: -.25,
    frost: 0,
    highlight: .9,
    contourStrength: .32,
  );

  /// Etiqueta para lectores de pantalla (el botón suele ser solo ícono).
  final String semanticLabel;
  final VoidCallback? onTap;
  final Widget child;

  /// Tamaño del botón; nunca menor que el área táctil mínima de 48 dp.
  final Size size;
  final LiquidShape shape;
  final LiquidGlassAppearance? appearance;

  /// Si forma parte de un [LiquidGlassBlendGroup] (solo sin [lens]).
  final bool grouped;

  /// Óptica propia del botón (ej. [dropLens]); `null` = cristal compartido.
  ///
  /// Solo para botones de tamaño fijo: si un layer propio cambia de tamaño
  /// rápido, el renderizador dibuja 1–2 cuadros de su forma anterior fuera
  /// del botón.
  final LiquidGlassSettings? lens;

  /// FakeGlass para la lente propia, para coincidir con el layer padre.
  final bool fake;

  /// Cuánto crece mientras se presiona (1.10 = 10 %).
  final double interactionScale;

  /// Cuánto se estira hacia el dedo al arrastrar (0 = nada). Útil desactivarlo
  /// cuando el botón se transforma en un campo de texto.
  final double stretch;

  /// Si el botón se anuncia como un único botón con [semanticLabel].
  /// Desactívalo cuando contiene controles propios (campo de texto, X).
  final bool wrapSemantics;

  /// Clave del cristal. Con una [GlobalKey] el cristal se conserva (no se
  /// destruye ni se recrea) aunque cambien el estiramiento o la gelatina,
  /// p. ej. cuando el botón se transforma en un campo y vuelve.
  final Key? glassKey;

  /// Si tiembla como gelatina al soltar.
  final bool jelly;

  /// Aumento del contenido, como una gota que agranda lo que tiene debajo.
  final double iconMagnify;
  final Color glowColor;

  /// Toque háptico ligero al pulsar.
  final bool haptics;

  @override
  Widget build(BuildContext context) {
    final content = GlassGlowLayer(
      child: GlassGlow(
        glowColor: glowColor,
        child: SizedBox.fromSize(
          size: size,
          child: Center(
            // Siempre presente (escala 1 = sin aumento) para no cambiar la
            // estructura del árbol al variar el aumento.
            child: Transform.scale(scale: iconMagnify, child: child),
          ),
        ),
      ),
    );

    final Widget glass;
    if (lens != null) {
      glass = LiquidGlass.withOwnLayer(
        key: glassKey,
        settings: lens!,
        fake: fake,
        shape: shape,
        appearance: appearance ?? const LiquidGlassAppearance.ios27Clear(),
        child: content,
      );
    } else if (grouped) {
      glass = LiquidGlass.grouped(
        key: glassKey,
        shape: shape,
        appearance: appearance,
        child: content,
      );
    } else {
      glass = LiquidGlass(
        key: glassKey,
        shape: shape,
        appearance: appearance,
        child: content,
      );
    }

    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              if (haptics) HapticFeedback.lightImpact();
              onTap!();
            },
      child: JellyWobble(
        enabled: jelly,
        child: LiquidStretch(
          interactionScale: interactionScale,
          // LiquidStretch devuelve su hijo sin envoltura cuando no estira ni
          // escala; ese cambio de estructura volvería a montar el cristal.
          // Un estiramiento mínimo e imperceptible la mantiene siempre.
          stretch: math.max(stretch, _minStretch),
          child: glass,
        ),
      ),
    );

    // Siempre el mismo widget Semantics (solo cambian sus propiedades) para
    // no reconstruir el cristal cuando el botón pasa a ser un campo.
    return Semantics(
      button: wrapSemantics,
      enabled: wrapSemantics ? onTap != null : null,
      label: wrapSemantics ? semanticLabel : null,
      // La acción va aquí: excludeSemantics oculta la del GestureDetector
      // y sin ella TalkBack anunciaría el botón sin poder activarlo.
      onTap: wrapSemantics && onTap != null
          ? () {
              if (haptics) HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      excludeSemantics: wrapSemantics,
      child: button,
    );
  }
}

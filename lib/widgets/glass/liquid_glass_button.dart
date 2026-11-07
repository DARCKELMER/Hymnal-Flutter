import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Botón de cristal líquido suelto con:
///
/// 1. **Presión de gota** ([LiquidStretch]): al tocar se infla un poco y,
///    si se arrastra el dedo, se estira hacia él como gelatina; al soltar
///    rebota a su forma con un resorte.
/// 2. **Brillo táctil** ([GlassGlow]): un resplandor suave sigue el dedo por
///    dentro del cristal.
///
/// Debe estar dentro de un [LiquidGlassLayer]; con [grouped] también dentro
/// de un [LiquidGlassBlendGroup] para fundirse con sus vecinos.
class LiquidGlassButton extends StatelessWidget {
  const LiquidGlassButton({
    required this.semanticLabel,
    required this.onTap,
    required this.child,
    this.size = const Size.square(64),
    this.shape = const LiquidOval(),
    this.appearance,
    this.grouped = false,
    this.interactionScale = 1.05,
    this.glowColor = const Color(0x33FFFFFF),
    this.haptics = true,
    super.key,
  });

  /// Etiqueta para lectores de pantalla (el botón suele ser solo ícono).
  final String semanticLabel;
  final VoidCallback? onTap;
  final Widget child;

  /// Tamaño del botón; nunca menor que el área táctil mínima de 48 dp.
  final Size size;
  final LiquidShape shape;
  final LiquidGlassAppearance? appearance;

  /// Si forma parte de un [LiquidGlassBlendGroup].
  final bool grouped;

  /// Cuánto crece mientras se presiona (1.05 = 5 %).
  final double interactionScale;
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
          child: Center(child: child),
        ),
      ),
    );

    final glass = grouped
        ? LiquidGlass.grouped(
            shape: shape,
            appearance: appearance,
            child: content,
          )
        : LiquidGlass(shape: shape, appearance: appearance, child: content);

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null
            ? null
            : () {
                if (haptics) HapticFeedback.lightImpact();
                onTap!();
              },
        child: LiquidStretch(interactionScale: interactionScale, child: glass),
      ),
    );
  }
}

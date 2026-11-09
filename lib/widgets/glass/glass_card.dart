import 'package:flutter/material.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/widgets/glass/glass_scope.dart';
import 'package:hymnal_app/widgets/glass/lyrics_card.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Tarjeta de cristal **legible** para listas y paneles con mucho texto
/// (p. ej. resultados de búsqueda): mismo criterio que [LyricsCard] —
/// cristal muy tintado y un velo del tema— para un contraste de al menos
/// 4.5:1 sobre cualquier paisaje.
///
/// Es **una sola forma** de cristal aunque contenga una lista larga: el
/// contenido se desplaza por dentro y el cristal no cambia.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.radius = GlassMetrics.cardRadius,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scope = GlassScope.of(context);
    final brightness = Theme.of(context).brightness;
    return LiquidGlassLayer(
      settings: scope.lyricsSettings,
      defaultAppearance: const LiquidGlassAppearance.ios27Clear(),
      child: LiquidGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: LyricsCard.veil(brightness),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            // Material transparente: los toques (InkWell) se dibujan sobre
            // el cristal y no debajo de él.
            child: Material(
              type: MaterialType.transparency,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

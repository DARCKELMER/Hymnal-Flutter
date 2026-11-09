import 'package:flutter/material.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
import 'package:hymnal_app/widgets/glass/glass_scope.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Tarjeta de letra del himno: cristal **siempre muy tintado** para que la
/// letra se lea sobre cualquier paisaje.
///
/// Dos capas de legibilidad (contraste de al menos 4.5:1):
/// 1. El cristal usa un tinte mínimo de 0.85, sin importar el ajuste
///    "Cristal" del usuario (más desenfoque y menos fondo visible).
/// 2. Encima, una capa translúcida del tema (blanca en claro, azul noche en
///    oscuro): el cristal "Clear" es igual en ambos modos y por sí solo no
///    garantiza contraste para la letra clara del modo oscuro.
///
/// Tiene su propio layer (su tinte es distinto del resto de la pantalla).
class LyricsCard extends StatelessWidget {
  const LyricsCard({
    required this.child,
    this.tablet = false,
    this.padding = const EdgeInsets.fromLTRB(22, 22, 22, 26),
    super.key,
  });

  final Widget child;

  /// Radio de 34 dp en tableta (32 en celular).
  final bool tablet;
  final EdgeInsetsGeometry padding;

  /// Capa de legibilidad sobre el cristal, según el brillo del tema.
  static Color veil(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0xA60B1220) // azul noche al 65 % (≥ 4.5:1 sobre blanco)
      : const Color(0x8CFFFFFF); // blanco al 55 %

  @override
  Widget build(BuildContext context) {
    final scope = GlassScope.of(context);
    final tokens = GlassTokens.of(context);
    final brightness = Theme.of(context).brightness;
    final radius = tablet
        ? GlassMetrics.lyricsCardRadiusTablet
        : GlassMetrics.lyricsCardRadius;
    return LiquidGlassLayer(
      settings: scope.lyricsSettings,
      defaultAppearance: const LiquidGlassAppearance.ios27Clear(),
      child: LiquidGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: veil(brightness),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: GlassTypography.lyrics(
                tablet ? HymnLayout.tabletPortrait : HymnLayout.phone,
                tokens.textPrimary,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

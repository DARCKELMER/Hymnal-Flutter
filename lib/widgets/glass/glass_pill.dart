import 'package:flutter/material.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/widgets/glass/jelly_wobble.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Cápsula de cristal con varias acciones dentro (p. ej. el grupo de
/// acciones del encabezado: compartir, favorito, partitura).
///
/// Los hijos suelen ser [GlassPillAction]. Debe ir dentro de una zona de
/// cristal (`GlassZone`).
class GlassPill extends StatelessWidget {
  const GlassPill({
    required this.children,
    this.height = GlassMetrics.minTouchTarget,
    this.grouped = false,
    super.key,
  });

  final List<Widget> children;
  final double height;

  /// Se funde con sus vecinos en un `GlassZone(blend: …)`.
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    final shape = LiquidRoundedSuperellipse(
      borderRadius: GlassMetrics.capsuleRadius(height),
    );
    final content = SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
    return grouped
        ? LiquidGlass.grouped(shape: shape, child: content)
        : LiquidGlass(shape: shape, child: content);
  }
}

/// Acción dentro de una [GlassPill]: ícono con área táctil de 48 dp que
/// tiembla como gelatina al tocarlo (sin cristal propio: no hay cristal
/// sobre cristal).
class GlassPillAction extends StatelessWidget {
  const GlassPillAction({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.color,
    this.selected = false,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  /// Color del ícono (por defecto, texto principal).
  final Color? color;

  /// Estado activo (p. ej. favorito marcado), anunciado al lector.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final iconColor = color ?? tokens.textPrimary;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: onPressed != null,
      label: semanticLabel,
      onTap: onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: GlassMetrics.minTouchTarget,
          child: Center(
            child: JellyWobble(
              enabled: onPressed != null,
              child: Icon(
                icon,
                size: 24,
                color: onPressed == null
                    ? iconColor.withValues(alpha: .4)
                    : iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

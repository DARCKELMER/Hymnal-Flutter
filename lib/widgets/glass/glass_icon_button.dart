import 'package:flutter/material.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/widgets/glass/liquid_glass_button.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Botón circular de cristal: 48 dp suelto, 64 dp en barras ([bar]).
///
/// Es una gota entera: se infla al presionar, se estira hacia el dedo y
/// tiembla como gelatina al soltar. Con [prominent] va tintado con el color
/// de los botones principales y el ícono en blanco.
///
/// Debe ir dentro de una zona de cristal (`GlassZone`).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.bar = false,
    this.prominent = false,
    this.grouped = false,
    this.iconColor,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  /// 64 dp (en barras) en vez de 48 dp.
  final bool bar;

  /// Tintado (acción principal).
  final bool prominent;

  /// Se funde con sus vecinos en un `GlassZone(blend: …)`.
  final bool grouped;

  /// Color del ícono (por defecto, texto principal o blanco si es
  /// [prominent]).
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final size = bar ? GlassMetrics.barButton : GlassMetrics.iconButton;
    final color = iconColor ?? (prominent ? Colors.white : tokens.textPrimary);
    return LiquidGlassButton(
      semanticLabel: semanticLabel,
      onTap: onPressed,
      size: Size.square(size),
      grouped: grouped,
      appearance: prominent
          ? LiquidGlassAppearance.ios27Clear(tint: tokens.buttonTint)
          : null,
      iconMagnify: 1.06,
      child: Icon(
        icon,
        size: size * .46,
        color: onPressed == null ? color.withValues(alpha: .4) : color,
      ),
    );
  }
}

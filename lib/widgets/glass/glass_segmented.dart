import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/widgets/glass/loupe_tab_bar/loupe_tab_bar.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Una opción de [GlassSegmented].
@immutable
class GlassSegment<T> {
  const GlassSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Control segmentado de cristal (Numérico/Alfabético/Temático,
/// Instrumental/Cantado, Claro/Oscuro/Sistema…).
///
/// Es **la misma barra del menú** (cápsula de cristal con la gota de agua
/// 3D que recorre las opciones con efecto lupa, se infla al presionar,
/// sigue al dedo y rebota), con opciones de solo texto (o texto e ícono).
/// Debe ir dentro de una zona de cristal (`GlassZone`); trae su propio
/// grupo de mezcla.
class GlassSegmented<T> extends StatelessWidget {
  const GlassSegmented({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.height = GlassMetrics.minTouchTarget,
    super.key,
  }) : assert(segments.length >= 2, 'Al menos dos opciones');

  final List<GlassSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final index = math.max(0, segments.indexWhere((s) => s.value == selected));
    final withIcons = segments.any((s) => s.icon != null);
    return SizedBox(
      height: height,
      child: LiquidGlassBlendGroup(
        child: LoupeTabBar(
          tabs: [
            for (final s in segments) BottomBarTab(label: s.label, icon: s.icon),
          ],
          selectedIndex: index,
          onSelected: (i) => onChanged(segments[i].value),
          height: height,
          tint: tokens.vivid,
          restingDrop: true,
          restingIconScale: 1.04,
          labelFontSize: withIcons ? 11 : 14,
        ),
      ),
    );
  }
}

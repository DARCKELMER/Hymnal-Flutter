import 'package:flutter/material.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/widgets/glass/loupe_tab_bar/loupe_tab_bar.dart';

/// Un destino de [GlassNavigationRail].
@immutable
class GlassRailDestination {
  const GlassRailDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Barra lateral de cristal para tableta: **la misma barra de pestañas del
/// celular** (cápsula de 64 dp con la gota de agua 3D que recorre la barra
/// con efecto lupa, se infla al presionar, sigue al dedo y rebota), girada
/// 90°, con los íconos y etiquetas girados de vuelta para leerse derechos.
///
/// Debe ir dentro de un `LiquidGlassLayer` con `LiquidGlassBlendGroup`
/// (p. ej. `GlassZone(blend: …)`), como la barra inferior.
class GlassNavigationRail extends StatelessWidget {
  const GlassNavigationRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.header,
    this.itemHeight = defaultItemHeight,
    super.key,
  });

  final List<GlassRailDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Arriba de la barra (p. ej. la insignia del himnario).
  final Widget? header;

  /// Alto de cada destino (menos en pantallas bajas, como un celular
  /// girado).
  final double itemHeight;

  static const double defaultItemHeight = 72;

  /// Grosor de la barra: el mismo alto que la barra del celular.
  static const double thickness = GlassMetrics.tabBarHeight;

  /// Alto reservado para [header].
  static const double headerHeight = 60;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header case final header?)
          SizedBox(
            width: thickness,
            height: headerHeight,
            child: Center(child: header),
          ),
        SizedBox(
          width: thickness,
          height: itemHeight * destinations.length,
          // La barra horizontal girada 90°: su comienzo queda arriba.
          child: RotatedBox(
            quarterTurns: 1,
            child: LoupeTabBar(
              tabs: [
                for (final d in destinations)
                  BottomBarTab(icon: d.icon, label: d.label),
              ],
              selectedIndex: selectedIndex,
              onSelected: onSelected,
              height: thickness,
              tint: tokens.vivid,
              restingDrop: true,
              restingIconScale: 1.06,
              // Íconos y etiquetas girados de vuelta, derechos.
              contentQuarterTurns: 3,
            ),
          ),
        ),
      ],
    );
  }
}

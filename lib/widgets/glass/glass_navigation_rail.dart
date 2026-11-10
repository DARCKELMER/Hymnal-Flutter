import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
import 'package:hymnal_app/widgets/glass/loupe_tab_bar/loupe_tab_bar.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:motor/motor.dart';

/// Un destino de [GlassNavigationRail].
@immutable
class GlassRailDestination {
  const GlassRailDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Barra lateral de cristal para tableta: cápsula vertical de 84 dp de
/// ancho con ícono y etiqueta por destino.
///
/// La opción elegida lleva una píldora interior **sin** cristal (blanco
/// translúcido) que se desliza con rebote. Debe ir dentro de un
/// `GlassZone`.
class GlassNavigationRail extends StatefulWidget {
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

  /// Arriba de los destinos (p. ej. la insignia del himnario).
  final Widget? header;

  /// Alto de cada destino (menos en pantallas bajas, como un celular
  /// girado).
  final double itemHeight;

  static const double defaultItemHeight = 72;

  /// Clave de la gota de agua (pruebas).
  static const dropKey = ValueKey('rail-drop');

  /// Alto reservado para [header].
  static const double headerHeight = 60;

  @override
  State<GlassNavigationRail> createState() => _GlassNavigationRailState();
}

class _GlassNavigationRailState extends State<GlassNavigationRail>
    with SingleTickerProviderStateMixin {
  late final SingleMotionController _position = SingleMotionController(
    motion: const Motion.bouncySpring(),
    vsync: this,
    initialValue: widget.selectedIndex.toDouble(),
  );

  @override
  void didUpdateWidget(GlassNavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _position.animateTo(widget.selectedIndex.toDouble());
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    const width = GlassMetrics.navigationRailWidth;
    const inset = 6.0;
    final itemHeight = widget.itemHeight;
    final headerHeight = widget.header == null
        ? 0.0
        : GlassNavigationRail.headerHeight;
    final height =
        headerHeight + itemHeight * widget.destinations.length + inset * 2;
    final dropRadius = (width - inset * 2) / 2;
    double dropTop() => inset + headerHeight + itemHeight * _position.value;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // La cápsula de cristal con los destinos.
          LiquidGlass(
            shape: const LiquidRoundedSuperellipse(borderRadius: width / 2),
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  // Píldora suave bajo la gota (contraste del elegido).
                  AnimatedBuilder(
                    animation: _position,
                    builder: (context, _) => Positioned(
                      left: inset,
                      right: inset,
                      top: dropTop(),
                      height: itemHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: tokens.selected,
                          borderRadius: BorderRadius.circular(dropRadius),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(inset),
                    child: Column(
                      children: [
                        if (widget.header case final header?)
                          SizedBox(
                            height: headerHeight,
                            child: Center(child: header),
                          ),
                        for (final (i, d) in widget.destinations.indexed)
                          _RailItem(
                            height: itemHeight,
                            destination: d,
                            selected: i == widget.selectedIndex,
                            onTap: () {
                              if (i == widget.selectedIndex) return;
                              HapticFeedback.selectionClick();
                              widget.onSelected(i);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // La gota de agua 3D (la misma lente que la barra inferior): en
          // su propio layer, encima, para refractar y magnificar la cápsula
          // y el ícono de abajo. Se desliza con rebote y se estira como
          // gelatina con la velocidad. Solo se traslada: no cambia de
          // tamaño (un layer propio que cambia de tamaño deja restos).
          AnimatedBuilder(
            animation: _position,
            builder: (context, child) {
              final speed = _position.velocity.abs();
              final stretch = 1.0 + math.min(speed * .045, .22);
              return Positioned(
                left: inset,
                right: inset,
                top: dropTop(),
                height: itemHeight,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(
                    1 / math.sqrt(stretch),
                    stretch,
                    1,
                  ),
                  child: child,
                ),
              );
            },
            child: IgnorePointer(
              child: LiquidGlass.withOwnLayer(
                key: GlassNavigationRail.dropKey,
                settings: LoupeTabBar.defaultLoupeSettings,
                shape: LiquidRoundedSuperellipse(borderRadius: dropRadius),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.height,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final double height;
  final GlassRailDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final color = selected ? tokens.accent : tokens.textPrimary;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: destination.label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(destination.icon, size: 26, color: color),
              const SizedBox(height: 4),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GlassTypography.tabLabel(color, selected: selected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

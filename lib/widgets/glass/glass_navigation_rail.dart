import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
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
    super.key,
  });

  final List<GlassRailDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Alto de cada destino.
  static const double itemHeight = 72;

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
    const itemHeight = GlassNavigationRail.itemHeight;
    final height = itemHeight * widget.destinations.length + inset * 2;
    return LiquidGlass(
      shape: const LiquidRoundedSuperellipse(borderRadius: width / 2),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _position,
              builder: (context, _) => Positioned(
                left: inset,
                right: inset,
                top: inset + itemHeight * _position.value,
                height: itemHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.selected,
                    borderRadius: BorderRadius.circular(
                      (width - inset * 2) / 2,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(inset),
              child: Column(
                children: [
                  for (final (i, d) in widget.destinations.indexed)
                    _RailItem(
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
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

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
          height: GlassNavigationRail.itemHeight,
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

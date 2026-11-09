import 'package:flutter/material.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/widgets/glass/liquid_glass_button.dart';
import 'package:hymnal_app/widgets/glass/loupe_tab_bar/loupe_tab_bar.dart';

/// Barra inferior de cristal: la cápsula de pestañas con la gota de agua
/// (que recorre la barra con efecto lupa y queda en 3D sobre la pestaña
/// activa) y, al lado, el botón circular de búsqueda.
///
/// Debe ir dentro de un `LiquidGlassLayer` con `LiquidGlassBlendGroup`
/// (lo pone `GlassDock`).
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    required this.onSearch,
    required this.searchLabel,
    super.key,
  });

  final List<BottomBarTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onSearch;
  final String searchLabel;

  static const double height = GlassMetrics.tabBarHeight;
  static const double gap = GlassMetrics.gapS;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: LoupeTabBar(
              tabs: tabs,
              selectedIndex: selectedIndex,
              onSelected: onSelected,
              height: height,
              tint: tokens.accent,
              restingDrop: true,
              restingIconScale: 1.06,
            ),
          ),
          const SizedBox(width: gap),
          LiquidGlassButton(
            semanticLabel: searchLabel,
            onTap: onSearch,
            size: const Size.square(height),
            iconMagnify: 1.06,
            child: Icon(
              Icons.search_rounded,
              size: 28,
              color: tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

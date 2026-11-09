import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/widgets/glass/liquid_glass_button.dart';
import 'package:hymnal_app/widgets/glass/loupe_tab_bar/loupe_tab_bar.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:motor/motor.dart';

/// Búsqueda integrada en la barra: la lupa se transforma en el campo.
///
/// El padre controla si está abierta ([open]) y muestra los resultados.
@immutable
class GlassTabSearch {
  const GlassTabSearch({
    required this.controller,
    required this.focusNode,
    required this.open,
    required this.onOpen,
    required this.onClose,
    required this.hint,
    required this.cancelLabel,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool open;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final String hint;
  final String cancelLabel;
  final ValueChanged<String>? onSubmitted;
}

/// Barra inferior de cristal: la cápsula de pestañas con la gota de agua
/// (que recorre la barra con efecto lupa y queda en 3D sobre la pestaña
/// activa) y, al lado, el botón circular de búsqueda.
///
/// Con [search], la lupa y el campo de búsqueda son **el mismo cristal**:
/// al abrirla, la barra se encoge en un círculo con el ícono de la pestaña
/// activa y la lupa se estira hasta ser el campo (con rebote líquido). Al
/// cerrarla, vuelve todo. Nada se crea ni se destruye: así el renderizador
/// no deja restos de contorno (la "media luna").
///
/// Debe ir dentro de un `LiquidGlassLayer` con `LiquidGlassBlendGroup`
/// (lo pone `GlassDock`).
class GlassTabBar extends StatefulWidget {
  const GlassTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    required this.searchLabel,
    this.onSearch,
    this.search,
    super.key,
  }) : assert(
         onSearch != null || search != null,
         'La lupa necesita onSearch o search',
       );

  final List<BottomBarTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String searchLabel;

  /// Lupa simple (sin campo integrado).
  final VoidCallback? onSearch;

  /// Búsqueda integrada (la lupa se transforma en el campo).
  final GlassTabSearch? search;

  static const double height = GlassMetrics.tabBarHeight;
  static const double gap = GlassMetrics.gapS;

  @override
  State<GlassTabBar> createState() => _GlassTabBarState();
}

class _GlassTabBarState extends State<GlassTabBar>
    with SingleTickerProviderStateMixin {
  /// 0 = barra + lupa, 1 = barra en círculo + campo. Resorte con rebote.
  late final SingleMotionController _morph = SingleMotionController(
    motion: const Motion.bouncySpring(snapToEnd: true),
    vsync: this,
    initialValue: _open ? 1 : 0,
  );

  /// Conserva el cristal de la lupa/campo durante toda la transformación.
  final _searchGlassKey = GlobalKey(debugLabel: 'tab-bar-search');

  bool get _open => widget.search?.open ?? false;

  @override
  void didUpdateWidget(GlassTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasOpen = oldWidget.search?.open ?? false;
    if (wasOpen == _open) return;
    _morph.animateTo(_open ? 1 : 0);
    if (_open) {
      // Enfoca el campo cuando ya casi terminó de abrirse.
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted && _open) widget.search?.focusNode.requestFocus();
      });
    } else {
      widget.search?.focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _morph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) return _buildSearchOnly();
    const h = GlassTabBar.height;
    const gap = GlassTabBar.gap;
    return SizedBox(
      height: h,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return AnimatedBuilder(
            animation: _morph,
            builder: (context, _) {
              // El resorte se pasa un poco de 0 y 1: ese rebote es el
              // "líquido".
              final t = _morph.value.clamp(-0.05, 1.06);
              final fullBar = width - h - gap;
              const minWidth = h * .9;
              final barWidth = lerpDouble(
                fullBar,
                h,
                t,
              )!.clamp(minWidth, width - minWidth - gap);
              final searchWidth = width - barWidth - gap;
              // 0 = barra encogida en círculo, 1 = barra a lo ancho.
              final widthProgress = ((barWidth - h) / (fullBar - h)).clamp(
                0.0,
                1.0,
              );
              return Row(
                children: [
                  SizedBox(
                    width: barWidth,
                    // La barra real nunca se desmonta: solo se encoge.
                    child: _tabs(collapse: 1 - widthProgress),
                  ),
                  const SizedBox(width: gap),
                  SizedBox(
                    width: searchWidth,
                    child: _searchGlass(searchWidth, t),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Sin pestañas (tableta: las pestañas están en la barra lateral): solo
  /// la búsqueda. Cerrada no ocupa espacio y es invisible; al abrirla, una
  /// gota brota abajo al centro y se estira hasta ser el campo.
  Widget _buildSearchOnly() {
    const h = GlassTabBar.height;
    return LayoutBuilder(
      builder: (context, constraints) {
        final full = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _morph,
          builder: (context, _) {
            final t = _morph.value.clamp(-0.05, 1.06);
            final appear = t.clamp(0.0, 1.0);
            final width = lerpDouble(h, full, t)!.clamp(h * .9, full);
            return SizedBox(
              width: full,
              height: h * appear,
              child: OverflowBox(
                alignment: Alignment.bottomCenter,
                minHeight: h,
                maxHeight: h,
                child: IgnorePointer(
                  ignoring: !_open,
                  child: ExcludeSemantics(
                    excluding: !_open,
                    child: Center(
                      child: SizedBox(
                        width: width,
                        child: _searchGlass(
                          width,
                          t,
                          visibility: (appear * 3).clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _tabs({required double collapse}) {
    final tokens = GlassTokens.of(context);
    return LoupeTabBar(
      tabs: widget.tabs,
      selectedIndex: widget.selectedIndex,
      onSelected: widget.onSelected,
      height: GlassTabBar.height,
      tint: tokens.accent,
      restingDrop: true,
      restingIconScale: 1.06,
      collapse: collapse,
      collapsedLabel: widget.search?.cancelLabel,
      onCollapsedTap: widget.search?.onClose,
    );
  }

  /// La lupa y el campo: una gota con el cristal compartido (no una lente
  /// propia: un layer propio que cambia de tamaño deja una "media luna").
  /// Cerrada: se infla, se estira hacia el dedo y tiembla como gelatina.
  /// Abierta: campo quieto con texto y ✕.
  Widget _searchGlass(double width, double t, {double? visibility}) {
    final tokens = GlassTokens.of(context);
    final search = widget.search;
    final closed = !_open;
    final contentOpacity = ((t - .35) / .65).clamp(0.0, 1.0);
    final roomForField = search != null && width > 160;
    const h = GlassTabBar.height;
    final color = tokens.textPrimary;

    return LiquidGlassButton(
      semanticLabel: widget.searchLabel,
      onTap: closed ? (search != null ? search.onOpen : widget.onSearch) : null,
      glassKey: _searchGlassKey,
      appearance: visibility == null
          ? null
          : LiquidGlassAppearance.ios27Clear(visibility: visibility),
      size: Size(width, h),
      // Radio = mitad del alto: círculo a 64 × 64 y cápsula al estirarse.
      shape: const LiquidRoundedRectangle(borderRadius: h / 2),
      iconMagnify: closed ? 1.06 : 1,
      interactionScale: closed ? 1.10 : 1,
      stretch: closed ? .5 : 0,
      jelly: closed,
      wrapSemantics: closed,
      child: SizedBox(
        width: width,
        height: h,
        child: Row(
          children: [
            SizedBox(
              width: roomForField ? 56 : width,
              child: Icon(Icons.search_rounded, color: color, size: 28),
            ),
            if (roomForField) ...[
              Expanded(
                child: Opacity(
                  opacity: contentOpacity,
                  child: TextField(
                    controller: search.controller,
                    focusNode: search.focusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: search.onSubmitted,
                    cursorColor: tokens.accent,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: search.hint,
                      hintStyle: TextStyle(color: tokens.textSecondary),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: contentOpacity,
                child: _CircleTap(
                  semanticLabel: search.cancelLabel,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    search.onClose();
                  },
                  child: Icon(Icons.close_rounded, color: color),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

/// Área táctil circular de 48 dp con etiqueta, sin cristal propio.
class _CircleTap extends StatelessWidget {
  const _CircleTap({
    required this.semanticLabel,
    required this.onTap,
    required this.child,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: GlassMetrics.minTouchTarget,
          child: Center(child: child),
        ),
      ),
    );
  }
}

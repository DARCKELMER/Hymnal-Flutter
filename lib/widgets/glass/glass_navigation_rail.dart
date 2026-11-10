import 'dart:math' as math;

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

  /// Lente de la gota: la de la barra inferior con el borde más brillante
  /// y más refracción, para que se note en 3D sobre la barra.
  static const dropSettings = LiquidGlassSettings(
    refractionHeight: 18,
    refractionAmount: 16,
    refractionFitsShape: false,
    dispersion: -.35,
    frost: 0,
    contourStrength: .5,
    highlight: .9,
    backdropShrink: .16,
  );

  /// Ancho de la gota (cápsula vertical) y cuánto sobresale arriba y
  /// abajo del destino.
  static const double dropWidth = 66;
  static const double dropOverhang = 6;

  /// Alto reservado para [header].
  static const double headerHeight = 60;

  @override
  State<GlassNavigationRail> createState() => _GlassNavigationRailState();
}

class _GlassNavigationRailState extends State<GlassNavigationRail>
    with TickerProviderStateMixin {
  /// Posición de la gota en "destinos" (puede ir entre dos al arrastrar).
  late final SingleMotionController _position = SingleMotionController(
    motion: const Motion.bouncySpring(),
    vsync: this,
    initialValue: widget.selectedIndex.toDouble(),
  );

  /// Se infla mientras se mantiene presionada (0 → 1).
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    reverseDuration: const Duration(milliseconds: 260),
  );

  static const double _inset = 6;

  bool _dragging = false;
  int _hovered = 0;

  double get _headerHeight =>
      widget.header == null ? 0 : GlassNavigationRail.headerHeight;

  @override
  void didUpdateWidget(GlassNavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex && !_dragging) {
      _position.animateTo(widget.selectedIndex.toDouble());
    }
  }

  @override
  void dispose() {
    _position.dispose();
    _press.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Arrastrar la gota por la barra (como en el laboratorio)
  // ---------------------------------------------------------------------------

  double _positionAt(double localY) {
    final last = widget.destinations.length - 1.0;
    final p = (localY - _inset - _headerHeight) / widget.itemHeight - .5;
    // Más allá de los extremos cede poco, como un líquido.
    if (p < 0) return p * .25;
    if (p > last) return last + (p - last) * .25;
    return p;
  }

  void _onDragStart(DragStartDetails d) {
    _dragging = true;
    _hovered = widget.selectedIndex;
    _press.forward();
    _position.value = _positionAt(d.localPosition.dy);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final p = _positionAt(d.localPosition.dy);
    _position.value = p;
    final over = p.round().clamp(0, widget.destinations.length - 1);
    if (over != _hovered) {
      _hovered = over;
      HapticFeedback.selectionClick(); // cruza un destino
    }
  }

  void _onDragEnd([DragEndDetails? d]) {
    _dragging = false;
    _press.reverse();
    final target = _position.value.round().clamp(
      0,
      widget.destinations.length - 1,
    );
    // Se asienta en el destino con rebote (y la velocidad del dedo).
    _position.animateTo(
      target.toDouble(),
      withVelocity: (d?.velocity.pixelsPerSecond.dy ?? 0) / widget.itemHeight,
    );
    HapticFeedback.lightImpact();
    if (target != widget.selectedIndex) widget.onSelected(target);
  }

  @override
  Widget build(BuildContext context) {
    const width = GlassMetrics.navigationRailWidth;
    const inset = _inset;
    final itemHeight = widget.itemHeight;
    final headerHeight = _headerHeight;
    final height =
        headerHeight + itemHeight * widget.destinations.length + inset * 2;
    const dropWidth = GlassNavigationRail.dropWidth;
    const overhang = GlassNavigationRail.dropOverhang;
    const dropRadius = dropWidth / 2;
    double dropTop() =>
        inset + headerHeight + itemHeight * _position.value - overhang;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: _onDragStart,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      onVerticalDragCancel: _onDragEnd,
      child: Listener(
        // Mantener presionado infla la gota (también al tocar).
        onPointerDown: (_) => _press.forward(),
        onPointerUp: (_) {
          if (!_dragging) _press.reverse();
        },
        onPointerCancel: (_) {
          if (!_dragging) _press.reverse();
        },
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // La cápsula de cristal con los destinos (sin píldora plana:
              // el elegido lo marca solo la gota, como en la barra inferior).
              LiquidGlass(
                shape: const LiquidRoundedSuperellipse(borderRadius: width / 2),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Padding(
                    padding: const EdgeInsets.all(inset),
                    child: AnimatedBuilder(
                      animation: _position,
                      builder: (context, _) => Column(
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
                              // El ícono bajo la gota se agranda y toma
                              // color mientras ella pasa encima.
                              under: (1 - (_position.value - i).abs()).clamp(
                                0.0,
                                1.0,
                              ),
                              onTap: () {
                                if (i == widget.selectedIndex) return;
                                HapticFeedback.selectionClick();
                                widget.onSelected(i);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // La gota de agua 3D (la misma lente que la barra inferior):
              // en su propio layer, encima, para refractar y agrandar la
              // cápsula y el ícono de abajo. Se infla al presionar, sigue
              // al dedo al arrastrar, se desliza con rebote y se estira
              // como gelatina con la velocidad. Solo se transforma: no
              // cambia de tamaño (un layer propio que cambia de tamaño deja
              // restos de contorno).
              AnimatedBuilder(
                animation: Listenable.merge([_position, _press]),
                builder: (context, child) {
                  final speed = _position.velocity.abs();
                  final stretch = 1.0 + math.min(speed * .045, .22);
                  // Se infla al presionar y también en el trayecto entre
                  // destinos (y se desinfla al llegar), como en el
                  // laboratorio.
                  final travel = _dragging
                      ? 0.0
                      : (_position.value - widget.selectedIndex).abs().clamp(
                          0.0,
                          1.0,
                        );
                  final swell =
                      1 +
                      math.max(
                        .1 * Curves.easeOutBack.transform(_press.value),
                        .14 * travel,
                      );
                  return Positioned(
                    left: (width - dropWidth) / 2,
                    width: dropWidth,
                    top: dropTop(),
                    height: itemHeight + overhang * 2,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(
                        swell / math.sqrt(stretch),
                        swell * stretch,
                        1,
                      ),
                      child: child,
                    ),
                  );
                },
                child: const IgnorePointer(
                  child: CustomPaint(
                    painter: _DropShadowPainter(),
                    child: LiquidGlass.withOwnLayer(
                      key: GlassNavigationRail.dropKey,
                      settings: GlassNavigationRail.dropSettings,
                      shape: LiquidRoundedSuperellipse(
                        borderRadius: dropRadius,
                      ),
                      child: SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sombra suave de la gota, pintada **solo por fuera** (una sombra dentro
/// la captaría su propio layer y oscurecería la lente).
class _DropShadowPainter extends CustomPainter {
  const _DropShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.shortestSide / 2),
    );
    canvas
      ..saveLayer(rect.inflate(24), Paint())
      ..drawRRect(
        shape.shift(const Offset(0, 3)),
        Paint()
          ..color = const Color(0x38000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      )
      ..drawRRect(shape, Paint()..blendMode = BlendMode.clear)
      ..restore();
  }

  @override
  bool shouldRepaint(_DropShadowPainter oldDelegate) => false;
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.height,
    required this.destination,
    required this.selected,
    required this.under,
    required this.onTap,
  });

  final double height;
  final GlassRailDestination destination;
  final bool selected;

  /// Cuánto está la gota encima (0–1): agranda y colorea el ícono.
  final double under;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final color = Color.lerp(tokens.textPrimary, tokens.vivid, under)!;
    final magnify = 1 + .18 * under;
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
              Transform.scale(
                scale: magnify,
                child: Icon(destination.icon, size: 26, color: color),
              ),
              SizedBox(height: 4 * magnify),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GlassTypography.tabLabel(color, selected: under > .5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

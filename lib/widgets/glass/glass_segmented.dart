import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:motor/motor.dart';

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
/// Una cápsula de cristal con una píldora interior **sin** cristal (blanco
/// translúcido, para no apilar cristal sobre cristal) que se desliza con
/// rebote hasta la opción elegida. Debe ir dentro de un `GlassZone`.
class GlassSegmented<T> extends StatefulWidget {
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
  State<GlassSegmented<T>> createState() => _GlassSegmentedState<T>();
}

class _GlassSegmentedState<T> extends State<GlassSegmented<T>>
    with SingleTickerProviderStateMixin {
  late final SingleMotionController _position = SingleMotionController(
    motion: const Motion.bouncySpring(),
    vsync: this,
    initialValue: _selectedIndex.toDouble(),
  );

  int get _selectedIndex => math.max(
    0,
    widget.segments.indexWhere((s) => s.value == widget.selected),
  );

  @override
  void didUpdateWidget(GlassSegmented<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _position.animateTo(_selectedIndex.toDouble());
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
    final h = widget.height;
    const inset = 4.0;
    return LiquidGlass(
      shape: LiquidRoundedSuperellipse(
        borderRadius: GlassMetrics.capsuleRadius(h),
      ),
      child: SizedBox(
        height: h,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final count = widget.segments.length;
            final segmentWidth = (constraints.maxWidth - inset * 2) / count;
            return Stack(
              children: [
                // Píldora de la opción elegida.
                AnimatedBuilder(
                  animation: _position,
                  builder: (context, _) => Positioned(
                    left: inset + segmentWidth * _position.value,
                    top: inset,
                    width: segmentWidth,
                    height: h - inset * 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tokens.selected,
                        borderRadius: BorderRadius.circular((h - inset) / 2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: inset),
                  child: Row(
                    children: [
                      for (final (i, segment) in widget.segments.indexed)
                        Expanded(
                          child: _SegmentButton(
                            segment: segment,
                            selected: i == _selectedIndex,
                            onTap: () {
                              if (i == _selectedIndex) return;
                              HapticFeedback.selectionClick();
                              widget.onChanged(segment.value);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({
    required this.segment,
    required this.selected,
    required this.onTap,
  });

  final GlassSegment<T> segment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final color = selected ? tokens.accent : tokens.textPrimary;
    final style = GlassTypography.listRow(
      color,
      selected: selected,
    ).copyWith(fontSize: 14);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: segment.label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (segment.icon != null) ...[
                Icon(segment.icon, size: 18, color: color),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  segment.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

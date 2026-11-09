import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:motor/motor.dart';

/// Interruptor del rediseño. **Sin cristal propio**: va sobre tarjetas o
/// barras de cristal, y cristal sobre cristal se ve mal y cuesta más.
///
/// Riel translúcido (acento cuando está activo) y una perilla blanca que
/// se desliza con rebote y se estira un poco al moverse, como una gota.
/// Área táctil de 48 dp.
class GlassSwitch extends StatefulWidget {
  const GlassSwitch({
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Etiqueta para el lector de pantalla si no la da la fila que lo
  /// contiene.
  final String? semanticLabel;

  @override
  State<GlassSwitch> createState() => _GlassSwitchState();
}

class _GlassSwitchState extends State<GlassSwitch>
    with SingleTickerProviderStateMixin {
  late final SingleMotionController _position = SingleMotionController(
    motion: const Motion.bouncySpring(),
    vsync: this,
    initialValue: widget.value ? 1 : 0,
  );

  static const _width = 52.0;
  static const _height = 32.0;
  static const _knob = 26.0;

  @override
  void didUpdateWidget(GlassSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _position.animateTo(widget.value ? 1 : 0);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _toggle() {
    final onChanged = widget.onChanged;
    if (onChanged == null) return;
    HapticFeedback.selectionClick();
    onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final enabled = widget.onChanged != null;
    return Semantics(
      container: true,
      toggled: widget.value,
      enabled: enabled,
      label: widget.semanticLabel,
      onTap: enabled ? _toggle : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: SizedBox(
          width: _width + 8,
          height: GlassMetrics.minTouchTarget,
          child: Center(
            child: Opacity(
              opacity: enabled ? 1 : .45,
              child: AnimatedBuilder(
                animation: _position,
                builder: (context, _) {
                  final p = _position.value;
                  final t = p.clamp(0.0, 1.0);
                  // Se estira con la velocidad, como una gota.
                  final stretch =
                      1 + (_position.velocity.abs() * .03).clamp(0.0, .25);
                  return Container(
                    width: _width,
                    height: _height,
                    padding: const EdgeInsets.all((_height - _knob) / 2),
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        tokens.textPrimary.withValues(alpha: .18),
                        tokens.accent,
                        t,
                      ),
                      borderRadius: BorderRadius.circular(_height / 2),
                      border: Border.all(color: const Color(0x40FFFFFF)),
                    ),
                    child: Align(
                      alignment: Alignment(-1 + 2 * p, 0),
                      child: Container(
                        width: _knob * stretch,
                        height: _knob / stretch,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(_knob / 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Deslizador del rediseño (sin cristal propio, como [GlassSwitch]):
/// riel de 6 dp en el color de acento y perilla blanca.
class GlassSlider extends StatelessWidget {
  const GlassSlider({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
    this.semanticFormatterCallback,
    this.activeColor,
    super.key,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;

  /// Texto de la burbuja al arrastrar (con [divisions]).
  final String? label;
  final SemanticFormatterCallback? semanticFormatterCallback;

  /// Color del tramo activo (por defecto, el acento).
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final active = activeColor ?? tokens.accent;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        activeTrackColor: active,
        inactiveTrackColor: tokens.textPrimary.withValues(alpha: .18),
        thumbColor: Colors.white,
        overlayColor: active.withValues(alpha: .12),
        valueIndicatorColor: active,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 11,
          elevation: 2,
        ),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      child: Slider(
        value: value.clamp(min, max),
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        semanticFormatterCallback: semanticFormatterCallback,
      ),
    );
  }
}

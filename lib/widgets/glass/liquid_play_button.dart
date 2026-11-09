import 'package:flutter/material.dart';
import 'package:hymnal_app/widgets/glass/liquid_glass_button.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Botón circular de reproducir/pausar con "pulso de gota":
///
/// - El ícono se transforma de ▶ a ⏸ con una animación continua.
/// - Al pulsar, un anillo de luz tenue sale del borde y se desvanece
///   rápido, sin quitarle protagonismo a la reacción de la gota.
/// - Hereda la presión de gota y el brillo táctil de [LiquidGlassButton].
/// - Todo el botón es una gota de agua 3D (lente propia) que se estira
///   hacia el dedo y tiembla como gelatina al soltar.
///
/// Las ondas se pintan fuera del cristal (sin geometría de cristal animada),
/// así que no añaden capturas de fondo.
class LiquidPlayButton extends StatefulWidget {
  const LiquidPlayButton({
    required this.isPlaying,
    required this.onPressed,
    required this.playLabel,
    required this.pauseLabel,
    this.diameter = 64,
    this.tint = const Color(0xD61F4FD1),
    this.rippleColor = Colors.white,
    this.fake = false,
    this.ownLens = true,
    this.visibility = 1,
    super.key,
  });

  final bool isPlaying;
  final VoidCallback onPressed;
  final String playLabel;
  final String pauseLabel;
  final double diameter;

  /// Tinte del cristal (por defecto `#1F4FD1` al 84 %).
  final Color tint;
  final Color rippleColor;

  /// FakeGlass para la lente propia, para coincidir con el layer padre.
  final bool fake;

  /// Con lente propia (layer aparte, óptica de gota) o con el cristal del
  /// layer padre, agrupado para poder fundirse con sus vecinos en un
  /// [LiquidGlassBlendGroup] (que entonces debe ser ancestro).
  final bool ownLens;

  /// Cuánto se ve (0–1): cristal, ícono y onda se desvanecen juntos, p. ej.
  /// al absorberse en otro cristal.
  final double visibility;

  @override
  State<LiquidPlayButton> createState() => _LiquidPlayButtonState();
}

class _LiquidPlayButtonState extends State<LiquidPlayButton>
    with TickerProviderStateMixin {
  late final AnimationController _icon = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: widget.isPlaying ? 1 : 0,
  );

  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void didUpdateWidget(LiquidPlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _icon.animateTo(1, curve: Curves.easeOutBack);
      } else {
        _icon.animateBack(0, curve: Curves.easeOutBack);
      }
    }
  }

  @override
  void dispose() {
    _icon.dispose();
    _ripple.dispose();
    super.dispose();
  }

  void _onTap() {
    _ripple.forward(from: 0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.diameter;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: widget.visibility.clamp(0.0, 1.0),
              child: CustomPaint(
                painter: _RipplePainter(_ripple, widget.rippleColor),
              ),
            ),
          ),
        ),
        LiquidGlassButton(
          semanticLabel: widget.isPlaying
              ? widget.pauseLabel
              : widget.playLabel,
          onTap: _onTap,
          size: Size.square(d),
          shape: const LiquidOval(),
          appearance: LiquidGlassAppearance.ios27Clear(
            tint: widget.tint,
            visibility: widget.visibility,
          ),
          glowColor: const Color(0x40FFFFFF),
          lens: widget.ownLens ? LiquidGlassButton.dropLens : null,
          grouped: !widget.ownLens,
          fake: widget.fake,
          iconMagnify: 1.06,
          child: Opacity(
            opacity: widget.visibility.clamp(0.0, 1.0),
            child: AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: _icon,
              color: Colors.white,
              size: d * 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Un anillo fino y tenue que nace en el borde, se expande poco y se
/// desvanece rápido: acompaña sin quitarle protagonismo a la gota.
class _RipplePainter extends CustomPainter {
  _RipplePainter(this.animation, this.color) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  /// Opacidad máxima del anillo.
  static const _maxOpacity = .25;

  /// Cuánto se aleja del borde, relativo al radio.
  static const _spread = .3;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t == 0 || t == 1) return;
    final base = size.shortestSide / 2;
    final eased = Curves.easeOutCubic.transform(t);
    canvas.drawCircle(
      size.center(Offset.zero),
      base * (1 + _spread * eased),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: _maxOpacity * (1 - t)),
    );
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.animation != animation;
}

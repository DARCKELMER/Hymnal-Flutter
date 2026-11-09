import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:hymnal_app/widgets/glass/jelly_wobble.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:motor/motor.dart';

/// Mini reproductor de cristal líquido con cuatro animaciones:
///
/// - **A. Progreso de agua:** la cápsula se llena de agua tintada de
///   izquierda a derecha según el avance, con el borde ondulado mientras
///   suena.
/// - **B. Deslizar para cambiar de himno:** a la izquierda pasa al
///   siguiente y a la derecha al anterior; la cápsula se estira hacia el
///   dedo y vuelve con rebote de gelatina. Hacia abajo, se cierra.
/// - **C. Brota de la barra:** con [emerge] de 0 a 1 la gota sale de la
///   barra de pestañas y se ensancha hasta ser la cápsula; de 1 a 0 vuelve a
///   fundirse. El padre debe envolver este widget y la barra en un mismo
///   [LiquidGlassBlendGroup] y animar su `blend` con [emerge].
/// - **E. Insignia viva:** el número del himno en un círculo de cristal con
///   un ecualizador sutil mientras suena; ▶ ↔ ⏸ se transforma y tiembla
///   como gelatina al tocarlo.
/// - **Teñido:** al ensancharse, la cápsula alcanza por el costado la gota
///   ▶ del padre, que se disuelve donde queda el ▶/⏸ (extremo derecho) y
///   deja una mancha lila ([dyeColor]); ver [dyeFor].
///
/// El cristal (`LiquidGlass.grouped`, sin layer propio) **nunca se crea ni
/// se destruye**: oculto sigue montado con visibilidad 0 dentro de la barra.
/// Así el renderizador no deja restos de contorno.
class LiquidMiniPlayer extends StatefulWidget {
  const LiquidMiniPlayer({
    required this.emerge,
    required this.shown,
    required this.number,
    required this.title,
    required this.isPlaying,
    required this.progress,
    required this.onTogglePlay,
    required this.onNext,
    required this.onPrevious,
    required this.onClose,
    required this.playLabel,
    required this.pauseLabel,
    required this.closeLabel,
    required this.nextLabel,
    required this.previousLabel,
    this.liftFromBar = 74,
    this.height = 60,
    this.accent = const Color(0xD61F4FD1),
    this.dyeColor = const Color(0xFFB08CFF),
    super.key,
  });

  /// Progreso de brote (C): 0 = fundido en la barra, 1 = cápsula completa.
  /// Puede pasarse un poco de 0 y 1 (resorte con rebote).
  final Animation<double> emerge;

  /// Si está visible para el usuario (toques y lector de pantalla).
  final bool shown;

  final int number;
  final String title;
  final bool isPlaying;

  /// Avance del himno actual, de 0 a 1 (A).
  final Animation<double> progress;

  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onClose;

  final String playLabel;
  final String pauseLabel;
  final String closeLabel;
  final String nextLabel;
  final String previousLabel;

  /// Distancia vertical (dp) del centro del reproductor al de la barra, de
  /// donde brota la gota.
  final double liftFromBar;
  final double height;

  /// Color del agua de progreso.
  final Color accent;

  /// Tinte lila que la gota ▶ deja en el extremo de la cápsula al fundirse.
  final Color dyeColor;

  /// Progreso de fusión de la gota ▶ con la cápsula (0–1) según [emerge]:
  /// empieza cuando la cápsula, al ensancharse, ya alcanzó la gota por el
  /// costado. El padre usa el mismo valor para disolver la gota.
  static double dyeFor(double emerge) => ((emerge - .75) / .25).clamp(0.0, 1.0);

  /// Distancia (dp) del centro del ▶/⏸ al borde derecho de la cápsula.
  static const double playInset = _trailing + 22;
  static const double _trailing = 10;

  /// Tamaño de la gota cuando está fundida en la barra.
  static const Size _seed = Size(56, 40);

  static const _onGlass = Colors.white;
  static const _textShadow = [Shadow(color: Color(0x66000000), blurRadius: 6)];

  @override
  State<LiquidMiniPlayer> createState() => _LiquidMiniPlayerState();
}

class _LiquidMiniPlayerState extends State<LiquidMiniPlayer>
    with TickerProviderStateMixin {
  /// Desplazamiento horizontal de la cápsula (dedo crudo; se amortigua al
  /// dibujar). Vuelve a 0 con rebote: ese rebote es la gelatina.
  late final SingleMotionController _dx = SingleMotionController(
    motion: const Motion.bouncySpring(),
    vsync: this,
  );

  /// Desplazamiento del título; al cambiar de himno entra por el lado
  /// contrario.
  late final SingleMotionController _titleDx = SingleMotionController(
    motion: const Motion.smoothSpring(),
    vsync: this,
  );

  /// Arrastre hacia abajo para cerrar.
  late final SingleMotionController _dy = SingleMotionController(
    motion: const Motion.bouncySpring(),
    vsync: this,
  );

  /// Fase de la onda del agua y del ecualizador (solo corre mientras suena).
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// Cuánto se ve el ecualizador (0 en pausa, 1 sonando).
  late final AnimationController _eq = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: widget.isPlaying ? 1 : 0,
  );

  /// ▶ ↔ ⏸.
  late final AnimationController _icon = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: widget.isPlaying ? 1 : 0,
  );

  late final Listenable _motion = Listenable.merge([
    widget.emerge,
    _dx,
    _titleDx,
    _dy,
  ]);

  double _width = 0;

  @override
  void initState() {
    super.initState();
    _syncWave();
  }

  @override
  void didUpdateWidget(LiquidMiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _icon.animateTo(1, curve: Curves.easeOutBack);
        _eq.forward();
      } else {
        _icon.animateBack(0, curve: Curves.easeOutBack);
        _eq.reverse();
      }
    }
    _syncWave();
  }

  /// La onda solo corre sonando y visible: en pausa no gasta cuadros.
  void _syncWave() {
    final run = widget.isPlaying && widget.shown;
    if (run && !_wave.isAnimating) {
      _wave.repeat();
    } else if (!run && _wave.isAnimating) {
      _wave.stop();
    }
  }

  @override
  void dispose() {
    _dx.dispose();
    _titleDx.dispose();
    _dy.dispose();
    _wave.dispose();
    _eq.dispose();
    _icon.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Gestos (B)
  // ---------------------------------------------------------------------------

  /// Desplazamiento del gesto en curso (independiente de dónde estaba la
  /// cápsula: puede seguir rebotando de un deslizamiento anterior).
  double _gestureDx = 0;
  double _gestureDy = 0;
  double _baseDx = 0;
  double _baseDy = 0;

  void _onHorizontalStart(DragStartDetails d) {
    _gestureDx = 0;
    _baseDx = _dx.value;
  }

  void _onHorizontalUpdate(DragUpdateDetails d) {
    _gestureDx += d.delta.dx;
    _dx.value = _baseDx + _gestureDx;
    _titleDx.value = _dx.value;
  }

  void _onHorizontalEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dx;
    final w = math.max(_width, 1);
    final dx = _gestureDx;
    final next = dx < -w * .22 || v < -650;
    final previous = !next && (dx > w * .22 || v > 650);
    if (next || previous) {
      HapticFeedback.selectionClick();
      if (next) {
        widget.onNext();
      } else {
        widget.onPrevious();
      }
      // El título nuevo entra por el lado contrario al deslizamiento.
      _titleDx.value = (next ? 1 : -1) * w * .45;
      _titleDx.animateTo(0);
    } else {
      _titleDx.animateTo(0);
    }
    // Vuelve al centro con la velocidad del dedo: rebota como gelatina.
    _dx.animateTo(0, withVelocity: v);
  }

  void _onVerticalStart(DragStartDetails d) {
    _gestureDy = 0;
    _baseDy = _dy.value;
  }

  void _onVerticalUpdate(DragUpdateDetails d) {
    _gestureDy += d.delta.dy;
    // Hacia arriba apenas cede; hacia abajo sigue al dedo.
    _dy.value = _baseDy + (_gestureDy < 0 ? _gestureDy * .3 : _gestureDy);
  }

  void _onVerticalEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dy;
    if (_gestureDy > 36 || v > 500) {
      widget.onClose();
    }
    _dy.animateTo(0, withVelocity: v);
  }

  // ---------------------------------------------------------------------------
  // Construcción
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        return SizedBox(
          width: _width,
          height: widget.height,
          child: AnimatedBuilder(
            animation: _motion,
            builder: (context, _) => _buildCapsule(),
          ),
        );
      },
    );
  }

  Widget _buildCapsule() {
    final w = _width;
    final h = widget.height;
    final e = widget.emerge.value;
    final ec = e.clamp(0.0, 1.0);

    // C: primero sube desde la barra, luego se ensancha (con rebote).
    final rise = Curves.easeOutCubic.transform((ec / .55).clamp(0.0, 1.0));
    final widen = ((e - .3) / .7).clamp(-0.04, 1.04);
    final seed = LiquidMiniPlayer._seed;
    final width = (seed.width + (w - seed.width) * widen).clamp(
      seed.width * .9,
      w * 1.03,
    );
    final height = (seed.height + (h - seed.height) * ec).clamp(
      seed.height,
      h * 1.04,
    );
    final visibility = (e / .25).clamp(0.0, 1.0);
    final contentOpacity = ((e - .7) / .3).clamp(0.0, 1.0);
    final dye = LiquidMiniPlayer.dyeFor(e);

    // B: estirado hacia el dedo, conservando más o menos el volumen.
    final dx = _dx.value;
    final pull = (dx.abs() / math.max(w, 1)).clamp(0.0, .6);
    final stretchX = 1 + pull * .18;
    final dy = _dy.value;
    final sink = (dy / 220).clamp(-0.05, .12);

    final radius = math.min(30.0, height / 2);
    final offset = Offset(dx * .4, widget.liftFromBar * (1 - rise) + dy * .6);

    return IgnorePointer(
      ignoring: !widget.shown,
      child: ExcludeSemantics(
        excluding: !widget.shown,
        // Estructura fija: los Transform siempre presentes (identidad en
        // reposo) para que el cristal no se vuelva a montar.
        child: Transform.translate(
          offset: offset,
          child: Center(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(
                stretchX * (1 - sink * .4),
                (1 / math.sqrt(stretchX)) * (1 - sink),
                1,
              ),
              child: _gestures(
                SizedBox(
                  width: width,
                  height: height,
                  child: LiquidGlass.grouped(
                    shape: LiquidRoundedSuperellipse(borderRadius: radius),
                    appearance: LiquidGlassAppearance.ios27Clear(
                      visibility: visibility,
                    ),
                    child: ClipRSuperellipse(
                      borderRadius: BorderRadius.circular(radius),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // A: agua de progreso.
                          CustomPaint(
                            painter: _WaterProgressPainter(
                              progress: widget.progress,
                              wave: _wave,
                              color: widget.accent,
                              opacity: visibility,
                            ),
                          ),
                          // Teñido lila donde se fundió la gota ▶. Anclado
                          // al tamaño completo, como el contenido.
                          OverflowBox(
                            minWidth: w,
                            maxWidth: w,
                            minHeight: h,
                            maxHeight: h,
                            child: CustomPaint(
                              painter: _DyePainter(
                                amount: dye,
                                color: widget.dyeColor,
                                inset: LiquidMiniPlayer.playInset,
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: contentOpacity,
                            // Los controles se anuncian desde que se
                            // muestra, aunque aún no terminen de aparecer.
                            alwaysIncludeSemantics: true,
                            // El contenido siempre mide lo de la cápsula
                            // completa; mientras brota, el recorte lo revela.
                            child: OverflowBox(
                              minWidth: w,
                              maxWidth: w,
                              minHeight: h,
                              maxHeight: h,
                              child: _buildContent(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gestures(Widget child) {
    return Semantics(
      container: true,
      customSemanticsActions: {
        CustomSemanticsAction(label: widget.nextLabel): widget.onNext,
        CustomSemanticsAction(label: widget.previousLabel): widget.onPrevious,
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: _onHorizontalStart,
        onHorizontalDragUpdate: _onHorizontalUpdate,
        onHorizontalDragEnd: _onHorizontalEnd,
        onVerticalDragStart: _onVerticalStart,
        onVerticalDragUpdate: _onVerticalUpdate,
        onVerticalDragEnd: _onVerticalEnd,
        child: child,
      ),
    );
  }

  Widget _buildContent() {
    final w = math.max(_width, 1.0);
    final titleDx = _titleDx.value;
    final titleOpacity = (1 - titleDx.abs() / (w * .5)).clamp(0.0, 1.0);

    return Row(
      children: [
        const SizedBox(width: 8),
        _LiveBadge(number: widget.number, eq: _eq, wave: _wave),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRect(
            child: Transform.translate(
              offset: Offset(titleDx * .9, 0),
              child: Opacity(
                opacity: titleOpacity,
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LiquidMiniPlayer._onGlass,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    shadows: LiquidMiniPlayer._textShadow,
                  ),
                ),
              ),
            ),
          ),
        ),
        _SmallTap(
          size: 40,
          semanticLabel: widget.closeLabel,
          onTap: widget.onClose,
          // Tiembla al tocarla y gira un cuarto de vuelta mientras la
          // cápsula se recoge (y al revés al brotar).
          child: JellyWobble(
            child: Transform.rotate(
              angle: (1 - widget.emerge.value.clamp(0.0, 1.0)) * math.pi / 2,
              child: const Icon(
                Icons.close_rounded,
                size: 20,
                color: Color(0xD9FFFFFF),
                shadows: LiquidMiniPlayer._textShadow,
              ),
            ),
          ),
        ),
        // ▶/⏸ en el extremo derecho: justo donde estaba la gota ▶ que se
        // fundió (su centro queda a 10 + 22 = 32 dp del borde, igual que la
        // gota sobre la lupa).
        _SmallTap(
          size: 44,
          semanticLabel: widget.isPlaying
              ? widget.pauseLabel
              : widget.playLabel,
          onTap: widget.onTogglePlay,
          child: JellyWobble(
            child: AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: _icon,
              color: LiquidMiniPlayer._onGlass,
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: LiquidMiniPlayer._trailing),
      ],
    );
  }
}

/// E: el número del himno en un círculo de cristal; mientras suena, el número
/// sube un poco y aparece debajo un ecualizador de tres barras.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge({
    required this.number,
    required this.eq,
    required this.wave,
  });

  final int number;
  final Animation<double> eq;
  final Animation<double> wave;

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Insignia de cristal: el color queda para el agua y el teñido.
          color: const Color(0x2EFFFFFF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x59FFFFFF)),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([eq, wave]),
          builder: (context, _) {
            final amount = Curves.easeOut.transform(eq.value);
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: Offset(0, -5 * amount),
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: number > 99 ? 14 : 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 7,
                  child: Opacity(
                    opacity: amount,
                    child: CustomPaint(
                      size: const Size(14, 7),
                      painter: _EqualizerPainter(wave.value, amount),
                    ),
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

class _EqualizerPainter extends CustomPainter {
  _EqualizerPainter(this.phase, this.amount);

  final double phase;
  final double amount;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xE6FFFFFF);
    const bars = 3;
    final barWidth = size.width / (bars * 2 - 1);
    for (var i = 0; i < bars; i++) {
      final t = math.sin(2 * math.pi * (phase * (1 + i * .35) + i * .27));
      final level = (.35 + .65 * (t * .5 + .5)) * amount;
      final barHeight = math.max(1.5, size.height * level);
      final left = i * barWidth * 2;
      canvas.drawRRect(
        RRect.fromLTRBR(
          left,
          size.height - barHeight,
          left + barWidth,
          size.height,
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EqualizerPainter old) =>
      old.phase != phase || old.amount != amount;
}

/// Tinta lila que se difunde desde el ▶/⏸ (donde se fundió la gota) y se
/// queda como una mancha suave que se desvanece hacia la izquierda.
class _DyePainter extends CustomPainter {
  _DyePainter({required this.amount, required this.color, required this.inset});

  final double amount;
  final Color color;

  /// Distancia del centro de la mancha al borde derecho.
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    if (amount <= 0) return;
    final spread = Curves.easeOutCubic.transform(amount);
    final center = Offset(size.width - inset, size.height / 2);
    // Se expande como tinta en el agua: más ancha que alta.
    final radius = 26 + 104 * spread;
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(1.6, 1);
    final alpha = color.a;
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha * .62 * amount),
            color.withValues(alpha: alpha * .30 * amount),
            color.withValues(alpha: 0),
          ],
          stops: const [0, .45, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DyePainter old) =>
      old.amount != amount || old.color != color || old.inset != inset;
}

/// A: agua tintada que llena la cápsula hasta [progress], con el borde
/// ondulado. La onda se mueve con [wave] (quieta en pausa).
class _WaterProgressPainter extends CustomPainter {
  _WaterProgressPainter({
    required this.progress,
    required this.wave,
    required this.color,
    required this.opacity,
  }) : super(repaint: Listenable.merge([progress, wave]));

  final Animation<double> progress;
  final Animation<double> wave;
  final Color color;
  final double opacity;

  /// Amplitud y longitud de la onda del borde, en dp.
  static const double _amplitude = 3;
  static const double _wavelength = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.value.clamp(0.0, 1.0);
    if (p == 0 || opacity == 0) return;
    final edge = size.width * p;
    // La onda se aplana al empezar y al llenarse, para no salirse.
    final amp = _amplitude * math.min(1, math.min(edge, size.width - edge) / 8);
    final phase = wave.value * 2 * math.pi;

    final path = Path()..moveTo(0, 0);
    const steps = 24;
    for (var i = 0; i <= steps; i++) {
      final y = size.height * i / steps;
      final x = edge + amp * math.sin(2 * math.pi * y / _wavelength + phase);
      path.lineTo(x, y);
    }
    path
      ..lineTo(0, size.height)
      ..close();

    final alpha = color.a * opacity;
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: alpha * .22),
            color.withValues(alpha: alpha * .42),
          ],
        ).createShader(Offset.zero & Size(math.max(edge, 1), size.height)),
    );

    // Línea de espuma en el borde del agua.
    final foam = Path();
    for (var i = 0; i <= steps; i++) {
      final y = size.height * i / steps;
      final x = edge + amp * math.sin(2 * math.pi * y / _wavelength + phase);
      if (i == 0) {
        foam.moveTo(x, y);
      } else {
        foam.lineTo(x, y);
      }
    }
    canvas.drawPath(
      foam,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: .35 * opacity),
    );
  }

  @override
  bool shouldRepaint(_WaterProgressPainter old) =>
      old.color != color ||
      old.opacity != opacity ||
      old.progress != progress ||
      old.wave != wave;
}

/// Área táctil con etiqueta semántica, sin cristal propio.
class _SmallTap extends StatelessWidget {
  const _SmallTap({
    required this.size,
    required this.semanticLabel,
    required this.onTap,
    required this.child,
  });

  final double size;
  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      // La acción va aquí: excludeSemantics oculta la del GestureDetector
      // y sin ella TalkBack anunciaría el botón sin poder activarlo.
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Center(child: child),
        ),
      ),
    );
  }
}

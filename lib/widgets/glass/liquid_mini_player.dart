import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:hymnal_app/widgets/glass/glass_haptics.dart';
import 'package:hymnal_app/widgets/glass/jelly_wobble.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:motor/motor.dart';

/// Textos del mini reproductor (lector de pantalla y controles).
class LiquidMiniPlayerLabels {
  const LiquidMiniPlayerLabels({
    required this.play,
    required this.pause,
    required this.close,
    required this.next,
    required this.previous,
    required this.showControls,
    required this.hideControls,
    required this.seekBack,
    required this.seekForward,
    required this.jumpStart,
    required this.jumpMiddle,
    required this.jumpEnd,
    required this.goToStart,
    required this.goToMiddle,
    required this.goToEnd,
    required this.position,
    required this.speed,
  });

  final String play;
  final String pause;
  final String close;
  final String next;
  final String previous;
  final String showControls;
  final String hideControls;
  final String seekBack;
  final String seekForward;
  final String jumpStart;
  final String jumpMiddle;
  final String jumpEnd;

  /// Etiquetas accesibles de los saltos (más claras que el texto corto).
  final String goToStart;
  final String goToMiddle;
  final String goToEnd;
  final String position;

  /// Etiqueta accesible de un botón de velocidad (p. ej. "Velocidad 2×").
  final String Function(int value) speed;
}

/// Mini reproductor de cristal líquido:
///
/// - **A. Progreso de agua:** la cápsula se llena de agua de [color] de
///   izquierda a derecha según el avance, con el borde ondulado mientras
///   suena.
/// - **B. Deslizar a los lados:** a la izquierda pasa al siguiente himno y a
///   la derecha al anterior, con estiramiento y rebote de gelatina.
/// - **C. Brota de la barra:** con [emerge] de 0 a 1 la gota sale de la
///   barra de pestañas y se ensancha hasta ser la cápsula; de 1 a 0 vuelve a
///   fundirse. El padre debe envolver este widget y la barra en un mismo
///   [LiquidGlassBlendGroup] y animar su `blend` con [emerge].
/// - **E. Insignia viva:** el número del himno en un círculo de cristal con
///   un ecualizador sutil mientras suena; ▶ ↔ ⏸ se transforma y tiembla
///   como gelatina al tocarlo.
/// - **Teñido:** al ensancharse, la cápsula alcanza por el costado la gota
///   ▶ del padre, que se disuelve donde queda el ▶/⏸ (extremo derecho) y
///   deja una mancha de [color]; ver [dyeFor].
/// - **Ajustes:** deslizar hacia arriba hace crecer el mismo cristal hacia
///   arriba con la barra de tiempo, saltos (inicio/mitad/final), ±10 s,
///   himno anterior/siguiente y velocidad. Hacia abajo se ocultan, y otro
///   deslizamiento hacia abajo oculta el reproductor.
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
    required this.duration,
    required this.speed,
    required this.onTogglePlay,
    required this.onNext,
    required this.onPrevious,
    required this.onClose,
    required this.onSeek,
    required this.onSpeedChanged,
    required this.labels,
    this.onOpen,
    this.loading = false,
    this.extraControls,
    this.liftFromBar = 74,
    this.collapsible = false,
    this.barGap = 12,
    this.barHeight = 64,
    this.height = 60,
    this.color = const Color(0xFF1F4FD1),
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

  /// Duración del himno (para los tiempos y los saltos de 10 s).
  final Duration duration;

  /// Velocidad actual (1, 2 o 3).
  final int speed;

  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onClose;

  /// Ir a una posición del himno, de 0 a 1.
  final ValueChanged<double> onSeek;
  final ValueChanged<int> onSpeedChanged;

  final LiquidMiniPlayerLabels labels;

  /// Toque en la cápsula (fuera de sus botones): p. ej. abrir el
  /// reproductor completo.
  final VoidCallback? onOpen;

  /// Cargando el audio: el ▶/⏸ muestra un indicador de progreso.
  final bool loading;

  /// Fila extra de controles en el panel de ajustes (p. ej. instrumental/
  /// cantado, reproducción continua, abrir la letra). Usa [MiniPlayerChip].
  final List<Widget>? extraControls;

  /// Distancia vertical (dp) del centro de la cápsula al de la barra, de
  /// donde brota la gota.
  final double liftFromBar;

  /// Plegable: oculto no ocupa espacio. El hueco crece mientras la gota
  /// brota y se pliega al fundirse, así la barra queda abajo del todo
  /// cuando no suena nada. La gota brota del centro de una barra de
  /// [barHeight] separada [barGap] (que el padre también anima con
  /// [emerge]); con `barHeight: 0` brota del borde inferior. En este modo
  /// se ignora [liftFromBar].
  final bool collapsible;
  final double barGap;
  final double barHeight;

  /// Alto de la cápsula compacta.
  final double height;

  /// Color de la gota ▶: agua de progreso, teñido y controles activos.
  final Color color;

  /// Progreso de fusión de la gota ▶ con la cápsula (0–1) según [emerge]:
  /// empieza cuando la cápsula, al ensancharse, ya alcanzó la gota por el
  /// costado. El padre usa el mismo valor para disolver la gota.
  static double dyeFor(double emerge) => ((emerge - .75) / .25).clamp(0.0, 1.0);

  /// Distancia (dp) del centro del ▶/⏸ al borde derecho de la cápsula.
  static const double playInset = _trailing + 22;
  static const double _trailing = 10;

  /// Alto extra del panel de ajustes (sin fila extra).
  static const double panelHeight = 150;

  /// Alto de la fila extra de controles.
  static const double extraRowHeight = 46;

  /// Alto del panel de este reproductor.
  double get effectivePanelHeight =>
      panelHeight + (extraControls == null ? 0 : extraRowHeight);

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

  /// Hundimiento al arrastrar hacia abajo la cápsula compacta (cerrar).
  late final SingleMotionController _dy = SingleMotionController(
    motion: const Motion.bouncySpring(),
    vsync: this,
  );

  /// Panel de ajustes: 0 = cápsula compacta, 1 = crecida hacia arriba.
  late final SingleMotionController _expand = SingleMotionController(
    motion: const Motion.bouncySpring(snapToEnd: true),
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
    _expand,
  ]);

  double _width = 0;

  bool get _expanded => _expand.value > .5;

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
    // Al ocultarse se recoge también el panel.
    if (!widget.shown && oldWidget.shown) _expand.animateTo(0);
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
    _expand.dispose();
    _wave.dispose();
    _eq.dispose();
    _icon.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  /// Cambia de himno con el título entrando por el lado contrario.
  void _switchHymn({required bool next}) {
    GlassHaptics.tick(context);
    if (next) {
      widget.onNext();
    } else {
      widget.onPrevious();
    }
    _titleDx.value = (next ? 1 : -1) * math.max(_width, 1) * .45;
    _titleDx.animateTo(0);
  }

  void _setExpanded(bool open, {double velocity = 0}) {
    if (open != _expanded) GlassHaptics.tick(context);
    _expand.animateTo(
      open ? 1 : 0,
      withVelocity: -velocity / widget.effectivePanelHeight,
    );
  }

  void _seekBy(int seconds) {
    final total = math.max(widget.duration.inMilliseconds, 1);
    final next = widget.progress.value + seconds * 1000 / total;
    widget.onSeek(next.clamp(0.0, 1.0));
  }

  /// "Final": los últimos 5 segundos (ir al final exacto saltaría ya al
  /// siguiente himno).
  double get _endPosition {
    final total = math.max(widget.duration.inMilliseconds, 1);
    return (1 - 5000 / total).clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------------
  // Gestos
  // ---------------------------------------------------------------------------

  /// Desplazamiento del gesto en curso (independiente de dónde estaba la
  /// cápsula: puede seguir rebotando de un deslizamiento anterior).
  double _gestureDx = 0;
  double _gestureDy = 0;
  double _baseDx = 0;
  double _baseDy = 0;
  double _baseExpand = 0;

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
      _switchHymn(next: next);
    } else {
      _titleDx.animateTo(0);
    }
    // Vuelve al centro con la velocidad del dedo: rebota como gelatina.
    _dx.animateTo(0, withVelocity: v);
  }

  void _onVerticalStart(DragStartDetails d) {
    _gestureDy = 0;
    _baseDy = _dy.value;
    _baseExpand = _expand.value;
  }

  void _onVerticalUpdate(DragUpdateDetails d) {
    _gestureDy += d.delta.dy;
    final wasOpen = _baseExpand > .5;
    if (!wasOpen && _gestureDy > 0) {
      // Compacta y hacia abajo: se hunde siguiendo al dedo (para cerrar).
      _dy.value = _baseDy + _gestureDy;
      return;
    }
    // Hacia arriba crece; abierta, hacia abajo se recoge. Más allá de los
    // extremos cede poco, como un líquido.
    final e = _baseExpand - _gestureDy / widget.effectivePanelHeight;
    _expand.value = e < 0 ? e * .3 : (e > 1 ? 1 + (e - 1) * .3 : e);
  }

  void _onVerticalEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dy;
    final wasOpen = _baseExpand > .5;
    if (wasOpen) {
      // Abierta: hacia abajo oculta los ajustes; si no, vuelve a abrirse.
      _setExpanded(!(_gestureDy > 30 || v > 500), velocity: v);
    } else if (_gestureDy < -30 || v < -500) {
      _setExpanded(true, velocity: v);
    } else {
      if (_gestureDy > 36 || v > 500) widget.onClose();
      _expand.animateTo(0);
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
        return AnimatedBuilder(
          animation: _motion,
          builder: (context, _) {
            final open = math.max(_expand.value, 0.0);
            final panel = widget.effectivePanelHeight * open;
            final full = widget.height + panel;
            final ec = widget.emerge.value.clamp(0.0, 1.0);
            // El hueco crece con el panel: el reproductor sube y todo sigue
            // dentro de su caja (si no, los controles no recibirían toques).
            // Plegable: además crece y se pliega con el brote.
            return SizedBox(
              width: _width,
              height: widget.collapsible ? widget.height * ec + panel : full,
              child: OverflowBox(
                alignment: Alignment.bottomCenter,
                minHeight: full,
                maxHeight: full,
                child: _buildCapsule(open),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCapsule(double open) {
    final w = _width;
    final h = widget.height;
    final panel = widget.effectivePanelHeight * open;
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
    final height =
        (seed.height + (h - seed.height) * ec).clamp(seed.height, h * 1.04) +
        panel;
    final visibility = (e / .25).clamp(0.0, 1.0);
    final contentOpacity = ((e - .7) / .3).clamp(0.0, 1.0);
    final dye = LiquidMiniPlayer.dyeFor(e);
    final panelOpacity = ((open - .25) / .75).clamp(0.0, 1.0);
    final panelActive = open > .5;

    // B: estirado hacia el dedo, conservando más o menos el volumen.
    final dx = _dx.value;
    final pull = (dx.abs() / math.max(w, 1)).clamp(0.0, .6);
    final stretchX = 1 + pull * .18;
    final dy = _dy.value;
    final sink = (dy / 220).clamp(-0.05, .12);

    final radius = math.min(30.0, height / 2);
    // Distancia del centro de la cápsula al punto de donde brota la gota.
    final lift = widget.collapsible
        ? h / 2 + widget.barGap * ec + widget.barHeight / 2
        : widget.liftFromBar;
    final offset = Offset(dx * .4, lift * (1 - rise) + dy * .6);
    final fullHeight = h + panel;

    Widget compactLayer(Widget child) =>
        Positioned(left: 0, right: 0, bottom: 0, height: h, child: child);

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
                panelActive,
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
                      // El contenido siempre mide lo del reproductor completo
                      // y se ancla abajo: mientras brota o crece, el recorte
                      // lo va revelando.
                      child: OverflowBox(
                        alignment: Alignment.bottomCenter,
                        minWidth: w,
                        maxWidth: w,
                        minHeight: fullHeight,
                        maxHeight: fullHeight,
                        child: Stack(
                          children: [
                            // A: agua de progreso.
                            compactLayer(
                              CustomPaint(
                                painter: _WaterProgressPainter(
                                  progress: widget.progress,
                                  wave: _wave,
                                  color: widget.color,
                                  opacity: visibility,
                                ),
                              ),
                            ),
                            // Teñido donde se fundió la gota ▶.
                            compactLayer(
                              CustomPaint(
                                painter: _DyePainter(
                                  amount: dye,
                                  color: widget.color,
                                  inset: LiquidMiniPlayer.playInset,
                                ),
                              ),
                            ),
                            compactLayer(
                              Opacity(
                                opacity: contentOpacity,
                                // Los controles se anuncian desde que se
                                // muestra, aunque aún no terminen de aparecer.
                                alwaysIncludeSemantics: true,
                                child: _buildCompactRow(),
                              ),
                            ),
                            // Ajustes, encima de la fila compacta.
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: h,
                              height: widget.effectivePanelHeight,
                              child: IgnorePointer(
                                ignoring: !panelActive,
                                child: ExcludeSemantics(
                                  excluding: !panelActive,
                                  child: Opacity(
                                    opacity: panelOpacity,
                                    child: _buildPanel(),
                                  ),
                                ),
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
      ),
    );
  }

  Widget _gestures(bool panelActive, Widget child) {
    final labels = widget.labels;
    return Semantics(
      container: true,
      // Cada control es su propio nodo (si no, TalkBack leería toda la
      // cápsula como un solo bloque y no podría activar sus botones).
      explicitChildNodes: true,
      // Alternativas accesibles a los gestos (TalkBack no puede deslizar
      // igual que un dedo).
      onTap: widget.onOpen,
      customSemanticsActions: {
        CustomSemanticsAction(label: labels.next): () =>
            _switchHymn(next: true),
        CustomSemanticsAction(label: labels.previous): () =>
            _switchHymn(next: false),
        CustomSemanticsAction(
          label: panelActive ? labels.hideControls : labels.showControls,
        ): () =>
            _setExpanded(!panelActive),
        CustomSemanticsAction(label: labels.close): widget.onClose,
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: _onHorizontalStart,
        onHorizontalDragUpdate: _onHorizontalUpdate,
        onHorizontalDragEnd: _onHorizontalEnd,
        onVerticalDragStart: _onVerticalStart,
        onVerticalDragUpdate: _onVerticalUpdate,
        onVerticalDragEnd: _onVerticalEnd,
        onTap: widget.onOpen,
        child: child,
      ),
    );
  }

  Widget _buildCompactRow() {
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
        // ▶/⏸ en el extremo derecho: justo donde estaba la gota ▶ que se
        // fundió (su centro queda a 10 + 22 = 32 dp del borde, igual que la
        // gota sobre la lupa).
        _SmallTap(
          size: 44,
          semanticLabel: widget.isPlaying
              ? widget.labels.pause
              : widget.labels.play,
          onTap: widget.onTogglePlay,
          child: widget.loading
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: LiquidMiniPlayer._onGlass,
                  ),
                )
              : JellyWobble(
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

  /// Panel de ajustes: barra de tiempo, himno anterior/siguiente, ±10 s,
  /// saltos y velocidad.
  Widget _buildPanel() {
    final labels = widget.labels;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: AnimatedBuilder(
              animation: widget.progress,
              builder: (context, _) {
                final p = widget.progress.value.clamp(0.0, 1.0);
                return Row(
                  children: [
                    _TimeText(widget.duration * p),
                    Expanded(
                      child: Semantics(
                        label: labels.position,
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 6,
                            activeTrackColor: widget.color,
                            inactiveTrackColor: const Color(0x4DFFFFFF),
                            thumbColor: Colors.white,
                            overlayColor: const Color(0x33FFFFFF),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                          ),
                          child: Slider(value: p, onChanged: widget.onSeek),
                        ),
                      ),
                    ),
                    _TimeText(widget.duration),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PanelIcon(
                  icon: Icons.skip_previous_rounded,
                  label: labels.previous,
                  onTap: () => _switchHymn(next: false),
                ),
                _PanelIcon(
                  icon: Icons.replay_10_rounded,
                  label: labels.seekBack,
                  onTap: () => _seekBy(-10),
                ),
                _PanelIcon(
                  icon: Icons.forward_10_rounded,
                  label: labels.seekForward,
                  onTap: () => _seekBy(10),
                ),
                _PanelIcon(
                  icon: Icons.skip_next_rounded,
                  label: labels.next,
                  onTap: () => _switchHymn(next: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: MiniPlayerChip(
                          label: labels.jumpStart,
                          semanticLabel: labels.goToStart,
                          color: widget.color,
                          onTap: () => widget.onSeek(0),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: MiniPlayerChip(
                          label: labels.jumpMiddle,
                          semanticLabel: labels.goToMiddle,
                          color: widget.color,
                          onTap: () => widget.onSeek(.5),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: MiniPlayerChip(
                          label: labels.jumpEnd,
                          semanticLabel: labels.goToEnd,
                          color: widget.color,
                          onTap: () => widget.onSeek(_endPosition),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                for (final s in const [1, 2, 3]) ...[
                  if (s > 1) const SizedBox(width: 4),
                  MiniPlayerChip(
                    label: '$s×',
                    semanticLabel: labels.speed(s),
                    selected: widget.speed == s,
                    color: widget.color,
                    onTap: () => widget.onSpeedChanged(s),
                  ),
                ],
              ],
            ),
          ),
          if (widget.extraControls case final extra?) ...[
            const SizedBox(height: 10),
            SizedBox(height: 36, child: Row(children: extra)),
          ],
        ],
      ),
    );
  }
}

class _TimeText extends StatelessWidget {
  const _TimeText(this.time);

  final Duration time;

  @override
  Widget build(BuildContext context) {
    final m = time.inMinutes;
    final s = (time.inSeconds % 60).toString().padLeft(2, '0');
    return SizedBox(
      width: 38,
      child: Text(
        '$m:$s',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: LiquidMiniPlayer._onGlass,
          fontSize: 12,
          fontFeatures: [FontFeature.tabularFigures()],
          shadows: LiquidMiniPlayer._textShadow,
        ),
      ),
    );
  }
}

/// Botón de ícono del panel: tiembla como gelatina al tocarlo.
class _PanelIcon extends StatelessWidget {
  const _PanelIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SmallTap(
      size: 48,
      semanticLabel: label,
      onTap: onTap,
      child: JellyWobble(
        child: Icon(
          icon,
          size: 28,
          color: LiquidMiniPlayer._onGlass,
          shadows: LiquidMiniPlayer._textShadow,
        ),
      ),
    );
  }
}

/// Píldora del panel del mini reproductor (saltos, velocidad y controles
/// extra). Seleccionada se tiñe de [color]. Sin cristal propio: va dentro
/// del cristal del reproductor.
class MiniPlayerChip extends StatelessWidget {
  const MiniPlayerChip({
    required this.label,
    required this.color,
    required this.onTap,
    this.semanticLabel,
    this.selected = false,
    this.icon,
    super.key,
  });

  /// Texto visible; vacío para una píldora solo con [icon].
  final String label;
  final String? semanticLabel;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: semanticLabel ?? label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null
            ? null
            : () {
                GlassHaptics.tick(context);
                onTap!();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          // Alto fijo y ancho del contenido (con alineación se estiraría a
          // todo el ancho disponible).
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: .8)
                : const Color(0x29FFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x47FFFFFF)),
          ),
          child: Opacity(
            opacity: onTap == null ? .45 : 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Icon(
                    icon,
                    size: 18,
                    color: LiquidMiniPlayer._onGlass,
                    shadows: LiquidMiniPlayer._textShadow,
                  ),
                if (icon != null && label.isNotEmpty) const SizedBox(width: 6),
                if (label.isNotEmpty)
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LiquidMiniPlayer._onGlass,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        shadows: LiquidMiniPlayer._textShadow,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
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

/// Tinta del color de la gota que se difunde desde el ▶/⏸ (donde se fundió la gota) y se
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
      container: true,
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

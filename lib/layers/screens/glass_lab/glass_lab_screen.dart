import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hymnal_app/core/constants/app_assets.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/utils/vivid_color.dart';
import 'package:hymnal_app/widgets/glass/liquid_glass_button.dart';
import 'package:hymnal_app/widgets/glass/liquid_mini_player.dart';
import 'package:hymnal_app/widgets/glass/liquid_play_button.dart';
import 'package:hymnal_app/widgets/glass/loupe_tab_bar/loupe_tab_bar.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:motor/motor.dart';

/// Cristal "agua brillante": parte del preset Clear de iOS 27 con un bisel
/// más ancho y profundo (más refracción en el borde) y un reflejo especular
/// más intenso, para que se vea como agua sobre el fondo en vez de mate.
LiquidGlassSettings waterGlassSettings(double tintAmount) =>
    LiquidGlassSettings.ios27Clear(tintAmount: tintAmount).copyWith(
      refractionHeight: 26,
      refractionAmount: 72,
      highlight: 0.9,
      contourStrength: 0.45,
    );

/// Pantalla de depuración para validar el cristal Liquid Glass "Clear"
/// en un dispositivo real antes de rediseñar la app (Fase 1).
///
/// Solo es accesible desde Ajustes cuando `kDebugMode` es verdadero.
class GlassLabScreen extends StatefulWidget {
  const GlassLabScreen({super.key});

  @override
  State<GlassLabScreen> createState() => _GlassLabScreenState();
}

class _GlassLabScreenState extends State<GlassLabScreen>
    with TickerProviderStateMixin {
  static const Color _accent = Color(0xFF1F4FD1);

  /// Color de la gota ▶ (y de su agua y teñido): el color más vivo del
  /// fondo. Mientras se calcula, el azul de la marca.
  Color _dropColor = _accent;
  static const Color _onGlass = Colors.white;
  static const List<Shadow> _textShadow = [
    Shadow(color: Color(0x66000000), blurRadius: 6),
  ];

  late final AnimationController _backgroundController;

  double _tint = 0;
  bool _shinyWater = true;
  bool _forceFake = false;
  bool _animateBackground = false;
  bool _showPerformance = false;
  bool _isPlaying = false;
  int _selectedTab = 0;

  /// Himnos de prueba (los primeros del himnario nuevo en español) para
  /// deslizar el mini reproductor.
  static const List<(int, String)> _hymns = [
    (1, 'Cantad alegres al Señor'),
    (2, 'Da gloria al Señor'),
    (3, 'Unidos en espíritu'),
    (4, 'Alabanzas sin cesar'),
    (5, 'A ti, glorioso Dios'),
  ];
  int _hymnIndex = 0;

  /// Mini reproductor: brota de la barra al reproducir y se funde al
  /// cerrarlo (✕ o deslizándolo hacia abajo). Pausar no lo oculta.
  bool _miniShown = false;
  late final SingleMotionController _miniEmerge = SingleMotionController(
    motion: const Motion.bouncySpring(snapToEnd: true),
    vsync: this,
  );

  /// Comparación: la gota ▶ con su propia lente (no puede fundirse) o con
  /// el cristal compartido (se funde con la cápsula).
  bool _playOwnLens = false;

  /// Duración simulada de cada himno.
  static const Duration _hymnLength = Duration(seconds: 90);

  /// Velocidad de reproducción (1×, 2× o 3×).
  int _speed = 1;

  /// Avance simulado del himno; al terminar pasa al siguiente.
  late final AnimationController _hymnProgress = AnimationController(
    vsync: this,
    duration: _hymnLength,
  )..addStatusListener(_onHymnProgressStatus);

  /// Transición del buscador: 0 = barra de pestañas + lupa,
  /// 1 = barra encogida en un círculo + campo de búsqueda.
  /// Resorte con rebote para que se sienta como líquido.
  late final SingleMotionController _search = SingleMotionController(
    motion: const Motion.bouncySpring(snapToEnd: true),
    vsync: this,
  );
  bool _searchOpen = false;

  final _searchText = TextEditingController();

  /// Conserva el cristal de la lupa/campo durante toda la transformación.
  final _searchGlassKey = GlobalKey(debugLabel: 'search-glass');
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    _loadDropColor();
  }

  /// Toma el color más vivo del fondo para la gota ▶.
  Future<void> _loadDropColor() async {
    final color = await vividColorFromImage(
      const AssetImage(AppAssets.backgroundImage),
    );
    if (!mounted || color == null) return;
    setState(() => _dropColor = dropColorFrom(color));
  }

  /// Ir a una posición del himno (0–1), sin perder la reproducción.
  void _seek(double position) {
    _hymnProgress.value = position;
    if (_isPlaying) _hymnProgress.forward();
  }

  void _setSpeed(int speed) {
    setState(() => _speed = speed);
    _hymnProgress.duration = _hymnLength ~/ speed;
    // Sigue desde el mismo punto con la nueva duración.
    if (_isPlaying) _hymnProgress.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _miniEmerge.dispose();
    _hymnProgress.dispose();
    _search.dispose();
    _searchText.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _setAnimateBackground(bool value) {
    setState(() => _animateBackground = value);
    if (value) {
      _backgroundController.repeat();
    } else {
      _backgroundController.stop();
    }
  }

  void _togglePlaying() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _hymnProgress.forward();
      if (!_miniShown) {
        setState(() => _miniShown = true);
        // La cápsula brota de la barra y, al ensancharse, alcanza la gota
        // ▶ por el costado y la disuelve (ver _buildPlayButton).
        _miniEmerge.animateTo(1);
      }
    } else {
      _hymnProgress.stop();
    }
  }

  /// Cerrar el mini reproductor detiene el himno y lo funde con la barra.
  void _closeMiniPlayer() {
    if (!_miniShown) return;
    HapticFeedback.lightImpact();
    _hymnProgress
      ..stop()
      ..value = 0;
    setState(() {
      _isPlaying = false;
      _miniShown = false;
    });
    _miniEmerge.animateTo(0);
  }

  void _changeHymn(int delta) {
    setState(() {
      _hymnIndex = (_hymnIndex + delta) % _hymns.length;
    });
    _hymnProgress.value = 0;
    if (_isPlaying) _hymnProgress.forward();
  }

  /// Reproducción continua simulada: al terminar, sigue el próximo himno.
  void _onHymnProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) _changeHymn(1);
  }

  void _openSearch() {
    if (_searchOpen) return;
    setState(() => _searchOpen = true);
    _search.animateTo(1);
    // Enfoca el campo cuando ya casi terminó de abrirse.
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted && _searchOpen) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    if (!_searchOpen) return;
    HapticFeedback.lightImpact();
    _searchFocus.unfocus();
    _searchText.clear();
    setState(() => _searchOpen = false);
    _search.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // El panel se oculta con el buscador abierto o mientras el teclado sigue
    // visible (al cerrar, el teclado tarda en bajar).
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showPanel = !_searchOpen && !keyboardVisible;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: _onGlass,
        elevation: 0,
        title: Text(l10n.glassLabTitle),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                // Zona superior desplazable: nunca se desborda aunque falte
                // sitio (teclado, pantalla pequeña o texto grande).
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (showPanel)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: _buildControlsPanel(l10n),
                          ),
                        if (_showPerformance && showPanel)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: PerformanceOverlay.allEnabled(),
                          ),
                      ],
                    ),
                  ),
                ),
                _buildGlassZone(l10n),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Fondo
  // ---------------------------------------------------------------------------

  Widget _buildBackground() {
    final image = Image.asset(
      AppAssets.backgroundImage,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );

    return AnimatedBuilder(
      animation: _backgroundController,
      child: image,
      builder: (context, child) {
        // Recorrido elíptico lento para ver la refracción en movimiento.
        final t = _backgroundController.value * 2 * math.pi;
        final offset = _animateBackground
            ? Offset(math.cos(t) * 40, math.sin(t) * 60)
            : Offset.zero;
        return Transform.translate(
          offset: offset,
          child: Transform.scale(scale: 1.25, child: child),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Controles de prueba (sin cristal, para no interferir con la medición)
  // ---------------------------------------------------------------------------

  Widget _buildControlsPanel(AppLocalizations l10n) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: const Color(0xCC10141C),
      borderRadius: BorderRadius.circular(20),
      child: Theme(
        data: Theme.of(context).copyWith(brightness: Brightness.dark),
        child: DefaultTextStyle(
          style: textTheme.bodyMedium!.copyWith(color: Colors.white),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('${l10n.glassLabTint}: ${_tint.toStringAsFixed(2)}'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${l10n.glassLabClear} ↔ ${l10n.glassLabTinted}',
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _tint,
                  onChanged: (value) => setState(() => _tint = value),
                ),
                _labSwitch(
                  l10n.glassLabWater,
                  _shinyWater,
                  (value) => setState(() => _shinyWater = value),
                ),
                _labSwitch(
                  l10n.glassLabPlayOwnLens,
                  _playOwnLens,
                  (value) => setState(() => _playOwnLens = value),
                ),
                _labSwitch(
                  l10n.glassLabForceFake,
                  _forceFake,
                  (value) => setState(() => _forceFake = value),
                ),
                _labSwitch(
                  l10n.glassLabAnimatedBackground,
                  _animateBackground,
                  _setAnimateBackground,
                ),
                _labSwitch(
                  l10n.glassLabPerformanceOverlay,
                  _showPerformance,
                  (value) => setState(() => _showPerformance = value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _labSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Zona de cristal: un solo LiquidGlassLayer para mini reproductor,
  // botón de reproducir y barra de pestañas con búsqueda.
  // ---------------------------------------------------------------------------

  Widget _buildGlassZone(AppLocalizations l10n) {
    return LiquidGlassLayer(
      settings: _shinyWater
          ? waterGlassSettings(_tint)
          : LiquidGlassSettings.ios27Clear(tintAmount: _tint),
      defaultAppearance: const LiquidGlassAppearance.ios27Clear(),
      fake: _forceFake,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        // Mini reproductor, gota ▶ y barra en el mismo grupo: el reproductor
        // brota de la barra y la gota se funde en él. La mezcla solo existe
        // durante las transiciones; en reposo (0) no hay "cuellos" entre
        // cristales cercanos.
        child: AnimatedBuilder(
          animation: _miniEmerge,
          builder: (context, child) => LiquidGlassBlendGroup(
            blend: math.max(
              28 * math.sin(math.pi * _miniEmerge.value.clamp(0.0, 1.0)),
              // Puente líquido mientras la gota ▶ se disuelve.
              24 *
                  math.sin(
                    math.pi * LiquidMiniPlayer.dyeFor(_miniEmerge.value),
                  ),
            ),
            child: child!,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMiniPlayer(l10n),
                  const SizedBox(height: _gap),
                  _buildBottomRow(l10n),
                ],
              ),
              // La gota ▶ reposa sobre la lupa, centrada en la fila compacta
              // del mini reproductor (60 dp de alto, gota de 64). Anclada
              // desde abajo: el reproductor crece hacia arriba con el panel.
              Positioned(
                bottom: _barHeight + _gap - 2,
                right: 0,
                child: _buildPlayButton(l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// La gota ▶ no se mueve: la cápsula, al ensancharse, la alcanza por el
  /// costado, se forma el puente líquido y la gota se disuelve en su sitio,
  /// justo donde queda el ▶/⏸ de la cápsula (y deja el teñido lila). Al
  /// cerrar, la cápsula se recoge y la gota vuelve a formarse. Los Transform
  /// están siempre presentes para no volver a montar el cristal.
  Widget _buildPlayButton(AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _miniEmerge,
      builder: (context, child) {
        final a = LiquidMiniPlayer.dyeFor(_miniEmerge.value);
        final absorbed = _miniShown;
        return IgnorePointer(
          ignoring: absorbed,
          child: ExcludeSemantics(
            excluding: absorbed,
            child: Transform.scale(
              scale: 1 - .3 * Curves.easeIn.transform(a),
              child: LiquidPlayButton(
                isPlaying: _isPlaying,
                onPressed: _togglePlaying,
                playLabel: l10n.glassLabPlay,
                pauseLabel: l10n.glassLabPause,
                tint: _dropColor.withValues(alpha: .84),
                fake: _forceFake,
                ownLens: _playOwnLens,
                visibility: 1 - a,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniPlayer(AppLocalizations l10n) {
    final (number, title) = _hymns[_hymnIndex];
    return LiquidMiniPlayer(
      emerge: _miniEmerge,
      shown: _miniShown,
      number: number,
      title: title,
      isPlaying: _isPlaying,
      progress: _hymnProgress,
      duration: _hymnLength,
      speed: _speed,
      onTogglePlay: _togglePlaying,
      onNext: () => _changeHymn(1),
      onPrevious: () => _changeHymn(-1),
      onClose: _closeMiniPlayer,
      onSeek: _seek,
      onSpeedChanged: _setSpeed,
      labels: LiquidMiniPlayerLabels(
        play: l10n.glassLabPlay,
        pause: l10n.glassLabPause,
        close: l10n.glassLabClosePlayer,
        next: l10n.glassLabNextHymn,
        previous: l10n.glassLabPreviousHymn,
        showControls: l10n.glassLabShowControls,
        hideControls: l10n.glassLabHideControls,
        seekBack: l10n.glassLabSeekBack,
        seekForward: l10n.glassLabSeekForward,
        jumpStart: l10n.glassLabJumpStart,
        jumpMiddle: l10n.glassLabJumpMiddle,
        jumpEnd: l10n.glassLabJumpEnd,
        goToStart: l10n.glassLabGoToStart,
        goToMiddle: l10n.glassLabGoToMiddle,
        goToEnd: l10n.glassLabGoToEnd,
        position: l10n.glassLabPosition,
        speed: l10n.glassLabSpeed,
      ),
      liftFromBar: 60 / 2 + _gap + _barHeight / 2,
      color: _dropColor,
    );
  }

  /// Barra con indicador de "gota de agua": al tocar o arrastrar, la gota
  /// crece, recorre la barra estirándose como gelatina con efecto lupa sobre
  /// los íconos que cruza y rebota al llegar a la pestaña.
  Widget _buildTabBar(AppLocalizations l10n, {double collapse = 0}) {
    return LoupeTabBar(
      tabs: [
        BottomBarTab(icon: Icons.home_rounded, label: l10n.home),
        BottomBarTab(
          icon: Icons.format_list_bulleted_rounded,
          label: l10n.lists,
        ),
        BottomBarTab(icon: Icons.favorite_rounded, label: l10n.favorites),
        BottomBarTab(icon: Icons.settings_rounded, label: l10n.settings),
      ],
      selectedIndex: _selectedTab,
      onSelected: (index) => setState(() => _selectedTab = index),
      height: 64,
      tint: _accent,
      fake: _forceFake,
      restingDrop: true,
      restingIconScale: 1.06,
      collapse: collapse,
      collapsedLabel: l10n.cancel,
      onCollapsedTap: _closeSearch,
    );
  }

  // ---------------------------------------------------------------------------
  // Buscador: "la gota que se derrite en campo"
  // ---------------------------------------------------------------------------

  static const double _barHeight = 64;
  static const double _gap = 12;

  /// Fila inferior. Al abrir la búsqueda, la barra de pestañas se encoge en
  /// un círculo con el ícono de la pestaña activa y la lupa se estira hasta
  /// ser el campo de búsqueda; el blend group las funde como dos gotas.
  /// La geometría solo se anima durante esta transición corta.
  Widget _buildBottomRow(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _search,
          builder: (context, _) {
            // El resorte se pasa un poco de 0 y 1: ese rebote es el "líquido".
            final t = _search.value.clamp(-0.05, 1.06);
            final fullBar = width - _barHeight - _gap;
            final minWidth = _barHeight * 0.9;
            final barWidth = lerpDouble(
              fullBar,
              _barHeight,
              t,
            )!.clamp(minWidth, width - minWidth - _gap);
            final searchWidth = width - barWidth - _gap;
            // 0 = barra encogida en círculo, 1 = barra a lo ancho.
            final widthProgress =
                ((barWidth - _barHeight) / (fullBar - _barHeight)).clamp(
                  0.0,
                  1.0,
                );

            return Row(
              children: [
                SizedBox(
                  width: barWidth,
                  // La barra real nunca se desmonta: solo se encoge.
                  child: _buildTabBar(l10n, collapse: 1 - widthProgress),
                ),
                const SizedBox(width: _gap),
                SizedBox(
                  width: searchWidth,
                  child: _buildSearch(l10n, searchWidth, t),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// La lupa y el campo de búsqueda son **el mismo elemento de cristal**:
  /// una gota que se estira de círculo a cápsula y vuelve, sin destruirse
  /// nunca. Así no hay saltos de forma ni de óptica, ni restos de contorno
  /// al cerrar.
  ///
  /// Usa el cristal de agua del layer principal, **no una lente propia**:
  /// un layer propio que cambia de tamaño rápido (al cerrar) hace que el
  /// renderizador dibuje durante 1–2 cuadros un trozo de su forma anterior
  /// fuera del botón (la "media luna" a su derecha). Medido en el S24 Ultra:
  /// 7 destellos en 12 cierres con lente propia, 0 en 12 sin ella. Las
  /// lentes propias quedan para botones que no cambian de tamaño (play).
  ///
  /// Cerrada: gota que se infla, se estira hacia el dedo y tiembla como
  /// gelatina. Abierta: campo quieto (sin estirarse ni temblar) con texto y X.
  Widget _buildSearch(AppLocalizations l10n, double width, double t) {
    final contentOpacity = ((t - 0.35) / 0.65).clamp(0.0, 1.0);
    final roomForField = width > 160;
    final closed = !_searchOpen;

    return LiquidGlassButton(
      semanticLabel: l10n.search,
      onTap: closed ? _openSearch : null,
      glassKey: _searchGlassKey,
      fake: _forceFake,
      size: Size(width, _barHeight),
      // Rectángulo con radio = mitad del alto: círculo perfecto a 64 × 64 y
      // cápsula al estirarse.
      shape: const LiquidRoundedRectangle(borderRadius: _barHeight / 2),
      iconMagnify: closed ? 1.06 : 1,
      interactionScale: closed ? 1.10 : 1,
      stretch: closed ? .5 : 0,
      jelly: closed,
      wrapSemantics: closed,
      child: SizedBox(
        width: width,
        height: _barHeight,
        child: Row(
          children: [
            SizedBox(
              width: roomForField ? 56 : width,
              child: const Icon(
                Icons.search_rounded,
                color: _onGlass,
                size: 28,
                shadows: _textShadow,
              ),
            ),
            if (roomForField) ...[
              Expanded(
                child: Opacity(
                  opacity: contentOpacity,
                  child: TextField(
                    controller: _searchText,
                    focusNode: _searchFocus,
                    textInputAction: TextInputAction.search,
                    cursorColor: _onGlass,
                    style: const TextStyle(
                      color: _onGlass,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      shadows: _textShadow,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      hintStyle: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        shadows: _textShadow,
                      ),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: contentOpacity,
                child: _CircleTap(
                  size: 48,
                  semanticLabel: l10n.cancel,
                  onTap: _closeSearch,
                  child: const Icon(
                    Icons.close_rounded,
                    color: _onGlass,
                    shadows: _textShadow,
                  ),
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

/// Área táctil circular con etiqueta semántica, sin cristal propio.
class _CircleTap extends StatelessWidget {
  const _CircleTap({
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

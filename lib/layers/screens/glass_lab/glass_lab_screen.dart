import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart' show CupertinoColors;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hymnal_app/core/constants/app_assets.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/widgets/glass/glass_drop.dart';
import 'package:hymnal_app/widgets/glass/liquid_glass_button.dart';
import 'package:hymnal_app/widgets/glass/liquid_play_button.dart';
import 'package:hymnal_app/widgets/glass/loupe_tab_bar/loupe_tab_bar.dart';
import 'package:hymnal_app/widgets/glass/loupe_tab_bar/tab_selection.dart';
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
  static const Color _accentTint = Color(0xD61F4FD1); // #1F4FD1 al 84 %
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

  /// Transición del buscador: 0 = barra de pestañas + lupa,
  /// 1 = barra encogida en un círculo + campo de búsqueda.
  /// Resorte con rebote para que se sienta como líquido.
  late final SingleMotionController _search = SingleMotionController(
    motion: const Motion.bouncySpring(snapToEnd: true),
    vsync: this,
  );
  bool _searchOpen = false;

  /// Si ya se volvió a montar la barra de pestañas real. Se activa en
  /// cuanto la barra recupera casi todo su ancho al cerrar, sin esperar a
  /// que termine el rebote, y no se desactiva hasta volver a abrir.
  bool _barRestored = true;
  final _searchText = TextEditingController();

  /// Conserva el cristal de la lupa/campo durante toda la transformación.
  final _searchGlassKey = GlobalKey(debugLabel: 'search-glass');
  final _searchFocus = FocusNode();

  static const List<IconData> _tabIcons = [
    Icons.home_rounded,
    Icons.format_list_bulleted_rounded,
    Icons.favorite_rounded,
    Icons.settings_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    _search
      ..addListener(_onSearchTick)
      ..addStatusListener(_onSearchStatus);
  }

  /// Devuelve la barra real en cuanto casi recuperó su ancho.
  void _onSearchTick() {
    if (!_searchOpen && !_barRestored && _search.value < 0.03) {
      setState(() => _barRestored = true);
    }
  }

  /// Red de seguridad: si el resorte se detiene antes del umbral.
  void _onSearchStatus(AnimationStatus status) {
    if (!_searchOpen && !_barRestored && !_search.isAnimating && mounted) {
      setState(() => _barRestored = true);
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _search
      ..removeListener(_onSearchTick)
      ..removeStatusListener(_onSearchStatus)
      ..dispose();
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

  void _togglePlaying() => setState(() => _isPlaying = !_isPlaying);

  void _openSearch() {
    if (_searchOpen) return;
    setState(() {
      _searchOpen = true;
      _barRestored = false;
    });
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _buildPlayButton(l10n),
            ),
            const SizedBox(height: 16),
            _buildMiniPlayer(l10n),
            const SizedBox(height: 12),
            LiquidGlassBlendGroup(blend: 20, child: _buildBottomRow(l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton(AppLocalizations l10n) {
    return LiquidPlayButton(
      isPlaying: _isPlaying,
      onPressed: _togglePlaying,
      playLabel: l10n.glassLabPlay,
      pauseLabel: l10n.glassLabPause,
      tint: _accentTint,
      fake: _forceFake,
    );
  }

  Widget _buildMiniPlayer(AppLocalizations l10n) {
    return LiquidGlass(
      shape: const LiquidRoundedSuperellipse(borderRadius: 30),
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            const SizedBox(width: 18),
            const Text(
              '1',
              style: TextStyle(
                color: _onGlass,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                shadows: _textShadow,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Cantad alegres al Señor',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _onGlass,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  shadows: _textShadow,
                ),
              ),
            ),
            _CircleTap(
              size: 48,
              semanticLabel: _isPlaying
                  ? l10n.glassLabPause
                  : l10n.glassLabPlay,
              onTap: _togglePlaying,
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: _onGlass,
                shadows: _textShadow,
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  /// Barra con indicador de "gota de agua": al tocar o arrastrar, la gota
  /// crece, recorre la barra estirándose como gelatina con efecto lupa sobre
  /// los íconos que cruza y rebota al llegar a la pestaña.
  Widget _buildTabBar(AppLocalizations l10n) {
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
            final atRest = _barRestored;
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
                  child: atRest
                      ? _buildTabBar(l10n)
                      : _buildCollapsedBar(l10n, barWidth, widthProgress),
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

  /// La barra encogida. Encogida del todo es un círculo con el ícono de la
  /// pestaña activa bajo una gota 3D; mientras se ensancha (al cerrar) o se
  /// estrecha (al abrir) cruza a una réplica de la barra real: los 4 íconos
  /// se desvanecen y la gota de reposo ya está sobre la pestaña activa, así
  /// que el cambio a la barra real no se nota.
  Widget _buildCollapsedBar(
    AppLocalizations l10n,
    double width,
    double widthProgress,
  ) {
    final circleOpacity = (1 - widthProgress / 0.45).clamp(0.0, 1.0);
    final ghostOpacity = ((widthProgress - 0.35) / 0.5).clamp(0.0, 1.0);

    return LiquidGlassButton(
      grouped: true,
      semanticLabel: l10n.cancel,
      onTap: _closeSearch,
      size: Size(width, _barHeight),
      shape: const LiquidRoundedSuperellipse(borderRadius: _barHeight / 2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // El círculo entero es la gota (con gelatina al tocarlo); el ícono
          // va limpio, sin un segundo círculo encima.
          if (circleOpacity > 0)
            Opacity(
              opacity: circleOpacity,
              child: Icon(_tabIcons[_selectedTab], color: _accent, size: 28),
            ),
          if (ghostOpacity > 0) _buildGhostTabs(l10n, width, ghostOpacity),
        ],
      ),
    );
  }

  /// Réplica de [LoupeTabBar] en reposo (mismo relleno, ranuras, ícono,
  /// etiqueta y gota) para la transición.
  Widget _buildGhostTabs(AppLocalizations l10n, double width, double opacity) {
    const padding = EdgeInsets.symmetric(horizontal: 9, vertical: 4);
    final labels = [l10n.home, l10n.lists, l10n.favorites, l10n.settings];
    final slot = (width - padding.horizontal) / labels.length;
    final labelColor = CupertinoColors.label.resolveFrom(context);

    Widget item(int index, Color color) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_tabIcons[index], size: 24, color: color),
        const SizedBox(height: 3),
        Text(
          labels[index],
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    // La gota de LoupeTabBar en reposo muestra el fondo un 14 % más pequeño
    // y compensa agrandando el contenido; aquí se replica igual.
    const settings = LoupeTabBar.defaultLoupeSettings;
    final magnify = 1.06 / (1 - settings.backdropShrink);
    final dropWidth = slot + 2 * TabSelection.platterOutset;
    final dropHeight = _barHeight - padding.vertical;

    return SizedBox(
      width: width,
      height: _barHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: padding,
            child: Opacity(
              opacity: opacity,
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: i == _selectedTab
                          ? const SizedBox.shrink()
                          : item(i, labelColor),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: padding.left + slot * (_selectedTab + .5) - dropWidth / 2,
            top: padding.top,
            width: dropWidth,
            height: dropHeight,
            child: GlassDrop(
              size: Size(dropWidth, dropHeight),
              shape: LiquidRoundedSuperellipse(borderRadius: dropHeight / 2),
              settings: settings,
              magnify: magnify,
              fake: _forceFake,
              visibility: opacity,
              child: Opacity(
                opacity: opacity,
                child: item(_selectedTab, _accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// La lupa y el campo de búsqueda son **el mismo elemento de cristal**:
  /// una gota con lente propia que se estira de círculo a cápsula y vuelve,
  /// sin destruirse nunca. Así no hay saltos de forma ni de óptica, ni
  /// restos de contorno al cerrar.
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
      lens: LiquidGlassButton.dropLens,
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

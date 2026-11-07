import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hymnal_app/core/constants/app_assets.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

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
    with SingleTickerProviderStateMixin {
  static const Color _accentTint = Color(0xD61F4FD1); // #1F4FD1 al 84 %
  static const Color _activePill = Color(0x8CFFFFFF); // blanco al 55 %
  static const Color _onGlass = Colors.white;
  static const List<Shadow> _textShadow = [
    Shadow(color: Color(0x66000000), blurRadius: 6),
  ];

  late final AnimationController _backgroundController;

  double _tint = 0;
  bool _forceFake = false;
  bool _animateBackground = false;
  bool _showPerformance = false;
  bool _isPlaying = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _buildControlsPanel(l10n),
                ),
                if (_showPerformance)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: PerformanceOverlay.allEnabled(),
                  ),
                const Spacer(),
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
      settings: LiquidGlassSettings.ios27Clear(tintAmount: _tint),
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
            LiquidGlassBlendGroup(
              blend: 20,
              child: Row(
                children: [
                  Expanded(child: _buildTabBar(l10n)),
                  const SizedBox(width: 12),
                  _buildSearchButton(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton(AppLocalizations l10n) {
    return LiquidGlass(
      shape: const LiquidOval(),
      appearance: const LiquidGlassAppearance.ios27Clear(tint: _accentTint),
      child: _CircleTap(
        size: 64,
        semanticLabel: _isPlaying ? l10n.glassLabPause : l10n.glassLabPlay,
        onTap: _togglePlaying,
        child: Icon(
          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 34,
        ),
      ),
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

  Widget _buildTabBar(AppLocalizations l10n) {
    final tabs = <(IconData, String)>[
      (Icons.home_rounded, l10n.home),
      (Icons.format_list_numbered_rounded, l10n.lists),
      (Icons.favorite_rounded, l10n.favorites),
      (Icons.settings_rounded, l10n.settings),
    ];

    return LiquidGlass.grouped(
      shape: const LiquidRoundedSuperellipse(borderRadius: 32),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _TabItem(
                    icon: tabs[i].$1,
                    label: tabs[i].$2,
                    selected: i == _selectedTab,
                    activeColor: _activePill,
                    onTap: () => setState(() => _selectedTab = i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton(AppLocalizations l10n) {
    return LiquidGlass.grouped(
      shape: const LiquidOval(),
      child: _CircleTap(
        size: 64,
        semanticLabel: l10n.search,
        onTap: () {},
        child: const Icon(
          Icons.search_rounded,
          color: _onGlass,
          size: 28,
          shadows: _textShadow,
        ),
      ),
    );
  }
}

/// Pestaña de la barra. La activa usa una píldora interior **sin** cristal
/// propio (blanco al 55 %) para no apilar cristal sobre cristal.
class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  static const Color _accent = Color(0xFF1F4FD1);

  @override
  Widget build(BuildContext context) {
    final color = selected ? _accent : Colors.white;
    final shadows = selected ? null : _GlassLabScreenState._textShadow;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(27),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color, shadows: shadows),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                  shadows: shadows,
                ),
              ),
            ],
          ),
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

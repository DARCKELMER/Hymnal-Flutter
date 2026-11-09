import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/widgets/glass/glass_mini_player.dart';
import 'package:hymnal_app/widgets/glass/glass_scope.dart';
import 'package:hymnal_app/widgets/glass/glass_tab_bar.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:motor/motor.dart';

/// Zona de cristal inferior: mini reproductor y, si la hay, barra de
/// pestañas, en **un solo** `LiquidGlassLayer` con blend group.
///
/// - Cuando empieza a sonar un himno, el reproductor brota de la barra (o
///   del borde inferior) con un resorte; la mezcla líquida entre ambos solo
///   existe durante la transición.
/// - Al cerrarlo (deslizar hacia abajo), se funde de vuelta y entonces se
///   libera el himno en [AudioService.finalizeDismiss].
class GlassDock extends StatefulWidget {
  const GlassDock({this.tabBar, this.showPlayer = true, super.key});

  /// Barra de pestañas (opcional).
  final GlassTabBar? tabBar;

  /// Si muestra el mini reproductor cuando suena un himno.
  final bool showPlayer;

  /// Alto que reserva el dock sin animar (para que el contenido no quede
  /// debajo): barra y/o reproductor compacto.
  static double reservedHeight({
    required bool hasTabBar,
    required bool hasPlayer,
  }) {
    var height = 0.0;
    if (hasTabBar) height += GlassTabBar.height;
    if (hasPlayer) {
      height += GlassMetrics.miniPlayerHeight;
      if (hasTabBar) height += GlassTabBar.gap;
    }
    return height;
  }

  @override
  State<GlassDock> createState() => _GlassDockState();
}

class _GlassDockState extends State<GlassDock> with TickerProviderStateMixin {
  final AudioService _audio = GetIt.I<AudioService>();

  late final SingleMotionController _emerge;

  /// Destino actual del brote (1 = visible, 0 = fundido). Solo se anima
  /// al cambiar: el audio avisa su posición varias veces por segundo.
  late double _target;

  bool get _wantsPlayer =>
      widget.showPlayer && _audio.currentHymn != null && !_audio.isDismissing;

  @override
  void initState() {
    super.initState();
    // Estado inicial ahora (no diferido): si se calculara en el primer uso,
    // tomaría el valor de después del primer cambio y no lo detectaría.
    _target = _wantsPlayer ? 1 : 0;
    _emerge = SingleMotionController(
      motion: const Motion.bouncySpring(snapToEnd: true),
      vsync: this,
      initialValue: _target,
    );
    _audio.addListener(_onAudio);
  }

  @override
  void didUpdateWidget(GlassDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _onAudio();
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudio);
    // Si se cierra la pantalla a mitad de la salida, libera el himno.
    if (_audio.isDismissing) _audio.finalizeDismiss();
    _emerge.dispose();
    super.dispose();
  }

  void _onAudio() {
    final target = _wantsPlayer ? 1.0 : 0.0;
    if (target == _target) {
      // Ya estaba fundido (p. ej. reproductor oculto en esta pantalla):
      // libera el himno sin esperar ninguna animación.
      if (target == 0 && _audio.isDismissing && !_emerge.isAnimating) {
        _audio.finalizeDismiss();
      }
      return;
    }
    _target = target;
    if (target == 1) {
      _emerge.animateTo(1);
    } else {
      // Se funde con la barra y, al terminar, libera el himno.
      _emerge.animateTo(0).whenCompleteOrCancel(() {
        if (mounted && _audio.isDismissing && _target == 0) {
          _audio.finalizeDismiss();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = widget.tabBar;
    final barHeight = tabBar == null ? 0.0 : GlassTabBar.height;
    final barGap = tabBar == null ? 0.0 : GlassTabBar.gap;
    return LiquidGlassLayer(
      settings: GlassScope.of(context).settings,
      defaultAppearance: const LiquidGlassAppearance.ios27Clear(),
      child: AnimatedBuilder(
        animation: _emerge,
        builder: (context, child) {
          final e = _emerge.value.clamp(0.0, 1.0);
          return LiquidGlassBlendGroup(
            // Solo durante el brote: en reposo no hay "cuello" entre el
            // reproductor y la barra.
            blend: 28 * math.sin(math.pi * e),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showPlayer)
                  GlassMiniPlayer(
                    emerge: _emerge,
                    barGap: barGap,
                    barHeight: barHeight,
                  ),
                if (tabBar != null) ...[
                  if (widget.showPlayer) SizedBox(height: barGap * e),
                  child!,
                ],
              ],
            ),
          );
        },
        child: tabBar,
      ),
    );
  }
}

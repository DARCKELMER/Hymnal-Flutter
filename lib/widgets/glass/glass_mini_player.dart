import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_opener.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_screen.dart';
import 'package:hymnal_app/layers/screens/player/player_screen.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/services/background_accent_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/widgets/glass/liquid_mini_player.dart';

/// Mini reproductor de cristal conectado al [AudioService]: himno actual,
/// progreso real, reproducir/pausar, siguiente/anterior (deslizar o
/// botones), saltos, ±10 s, velocidad, instrumental/cantado, reproducción
/// continua y abrir la letra. Tocarlo abre el reproductor completo.
///
/// Plegable: sin himno no ocupa espacio. El brote ([emerge]) lo anima el
/// padre (`GlassDock`), que también anima la mezcla con la barra.
class GlassMiniPlayer extends StatefulWidget {
  const GlassMiniPlayer({
    required this.emerge,
    required this.barGap,
    required this.barHeight,
    super.key,
  });

  final Animation<double> emerge;

  /// Separación y alto de la barra de la que brota (0 si no hay barra).
  final double barGap;
  final double barHeight;

  @override
  State<GlassMiniPlayer> createState() => _GlassMiniPlayerState();
}

class _GlassMiniPlayerState extends State<GlassMiniPlayer>
    with SingleTickerProviderStateMixin {
  final AudioService _audio = GetIt.I<AudioService>();

  /// Avance 0–1, animado entre las actualizaciones de posición del audio
  /// (llegan cada ~200 ms) para que el agua avance suave.
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  /// Si el himno actual tiene versión instrumental y cantada.
  bool _hasInstrumental = false;
  bool _hasSung = false;
  String? _versionsFor;

  @override
  void initState() {
    super.initState();
    _audio.addListener(_onAudio);
    _onAudio();
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudio);
    _progress.dispose();
    super.dispose();
  }

  void _onAudio() {
    final total = _audio.duration.inMilliseconds;
    final target = total <= 0
        ? 0.0
        : (_audio.position.inMilliseconds / total).clamp(0.0, 1.0);
    if ((target - _progress.value).abs() > .25) {
      _progress.value = target; // salto (cambio de himno o búsqueda)
    } else {
      _progress.animateTo(target, curve: Curves.linear);
    }
    _loadVersions();
  }

  /// Averigua qué versiones existen del himno actual (una vez por himno).
  Future<void> _loadVersions() async {
    final hymn = _audio.currentHymn;
    final hymnal = _audio.currentHymnal;
    if (hymn == null || hymnal == null) return;
    final key = '${hymnal.id}#${hymn.number}';
    if (_versionsFor == key) return;
    _versionsFor = key;
    final instrumental = await _audio.versionUrl(instrumental: true);
    final sung = await _audio.versionUrl(instrumental: false);
    if (!mounted || _versionsFor != key) return;
    setState(() {
      _hasInstrumental = instrumental != null;
      _hasSung = sung != null;
    });
  }

  void _seek(double position) {
    _progress.value = position;
    _audio.seek(_audio.duration * position);
  }

  void _openPlayer() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/player'),
        builder: (context) =>
            PlayerScreen(onClose: () => Navigator.of(context).pop()),
      ),
    );
  }

  /// Abre la letra del himno que suena (sin apilar otra pantalla de himno).
  void _openLyrics() {
    final hymn = _audio.currentHymn;
    final hymnal = _audio.currentHymnal;
    if (hymn == null || hymnal == null) return;
    // En tableta (vista expandida) se muestra a la derecha, sin navegar.
    final onOpen = context.getInheritedWidgetOfExactType<HymnOpener>()?.onOpen;
    if (onOpen != null) {
      onOpen(hymnal.id, hymn.number, skipHistory: true);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/hymn'),
        builder: (_) => HymnScreen(
          hymnalId: hymnal.id,
          hymnNumber: hymn.number,
          skipHistory: true,
        ),
      ),
      (route) =>
          route.settings.name != '/hymn' && route.settings.name != '/player',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = GlassTokens.of(context);
    final accent = GetIt.I.isRegistered<BackgroundAccentService>()
        ? GetIt.I<BackgroundAccentService>()
        : null;

    return ListenableBuilder(
      listenable: Listenable.merge([_audio, ?accent]),
      builder: (context, _) {
        final hymn = _audio.currentHymn;
        final color = accent?.value ?? tokens.accent;
        final shown = hymn != null && !_audio.isDismissing;
        return LiquidMiniPlayer(
          emerge: widget.emerge,
          shown: shown,
          collapsible: true,
          barGap: widget.barGap,
          barHeight: widget.barHeight,
          number: hymn?.number ?? 0,
          title: hymn?.title ?? '',
          isPlaying: _audio.isPlaying,
          loading: _audio.isLoading && !_audio.isPlaying,
          progress: _progress,
          duration: _audio.duration,
          speed: _audio.speed.round().clamp(1, 3),
          color: color,
          onTogglePlay: _audio.togglePlayPause,
          onNext: _audio.skipNext,
          onPrevious: _audio.skipPrevious,
          onClose: _audio.stop,
          onSeek: _seek,
          onSpeedChanged: (s) => _audio.setSpeed(s.toDouble()),
          onOpen: _openPlayer,
          labels: LiquidMiniPlayerLabels(
            play: l10n.playerPlay,
            pause: l10n.playerPause,
            close: l10n.playerClose,
            next: l10n.playerNextHymn,
            previous: l10n.playerPreviousHymn,
            showControls: l10n.playerShowControls,
            hideControls: l10n.playerHideControls,
            seekBack: l10n.playerSeekBack,
            seekForward: l10n.playerSeekForward,
            jumpStart: l10n.playerJumpStart,
            jumpMiddle: l10n.playerJumpMiddle,
            jumpEnd: l10n.playerJumpEnd,
            goToStart: l10n.playerGoToStart,
            goToMiddle: l10n.playerGoToMiddle,
            goToEnd: l10n.playerGoToEnd,
            position: l10n.playerPosition,
            speed: l10n.playerSpeed,
          ),
          extraControls: [
            Flexible(
              child: MiniPlayerChip(
                label: l10n.instrumental,
                icon: Icons.piano_rounded,
                selected: _audio.isInstrumental,
                color: color,
                onTap: _hasInstrumental
                    ? () => _audio.switchVersion(instrumental: true)
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: MiniPlayerChip(
                label: l10n.sung,
                icon: Icons.mic_rounded,
                selected: !_audio.isInstrumental,
                color: color,
                onTap: _hasSung
                    ? () => _audio.switchVersion(instrumental: false)
                    : null,
              ),
            ),
            const Spacer(),
            MiniPlayerChip(
              label: '',
              icon: Icons.repeat_rounded,
              semanticLabel: l10n.continuousPlay,
              selected: _audio.continuousPlay,
              color: color,
              onTap: _audio.toggleContinuousPlay,
            ),
            const SizedBox(width: 6),
            MiniPlayerChip(
              label: '',
              icon: Icons.lyrics_rounded,
              semanticLabel: l10n.viewLyrics,
              color: color,
              onTap: _openLyrics,
            ),
          ],
        );
      },
    );
  }
}

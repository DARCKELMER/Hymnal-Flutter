import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:share_plus/share_plus.dart';

import 'package:hymnal_app/constants/app_links.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/data/repository/hymnal_repository.dart';
import 'package:hymnal_app/layers/domain/model/hymn.dart';
import 'package:hymnal_app/layers/domain/model/thematic_category.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_screen.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/services/favorites_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
import 'package:hymnal_app/widgets/glass/glass_background.dart';
import 'package:hymnal_app/widgets/glass/glass_card.dart';
import 'package:hymnal_app/widgets/glass/glass_controls.dart';
import 'package:hymnal_app/widgets/glass/glass_icon_button.dart';
import 'package:hymnal_app/widgets/glass/glass_segmented.dart';
import 'package:hymnal_app/widgets/glass/glass_zone.dart';
import 'package:hymnal_app/widgets/glass/liquid_play_button.dart';

part 'player_controller.dart';

/// Reproductor completo (lienzo, pantalla 4): encabezado con cerrar,
/// "Reproduciendo" y acciones; la portada de cristal con el número del
/// himno; título y "sección · versión"; la barra de progreso; anterior,
/// −10 s, reproducir, +10 s y siguiente; Instrumental/Cantado con
/// "Continua"; y la tarjeta "A continuación" con "Ver letra". En
/// horizontal, la portada a la izquierda y los controles a la derecha.
class PlayerScreen extends StatefulWidget {
  final bool showBackground;
  final VoidCallback? onClose;

  /// Abre la letra del himno que suena (si no se da, se abre como
  /// pantalla).
  final VoidCallback? onOpenLyrics;

  const PlayerScreen({
    super.key,
    this.showBackground = true,
    this.onClose,
    this.onOpenLyrics,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends _PlayerController {
  static String _time(Duration d) {
    final s = d.inSeconds.abs();
    final m = s ~/ 60;
    final h = m ~/ 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m % 60)}:${two(s % 60)}' : '$m:${two(s % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final content = Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: GlassZone(
          child: ListenableBuilder(
            listenable: _audioService,
            builder: (context, _) {
              final hymn = _audioService.currentHymn;
              if (hymn == null) {
                return Column(
                  children: [
                    _header(context, null),
                    Expanded(child: Center(child: Text(l10n.noAudioPlaying))),
                  ],
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final wide =
                      constraints.maxWidth > constraints.maxHeight &&
                      constraints.maxWidth >= 560;
                  return wide
                      ? _wideLayout(context, hymn, constraints)
                      : _tallLayout(context, hymn, constraints);
                },
              );
            },
          ),
        ),
      ),
    );

    if (!widget.showBackground) return content;
    return ListenableBuilder(
      listenable: _settingsService,
      builder: (context, child) => Stack(
        children: [
          Positioned.fill(
            child: GlassBackground(
              showImage: _settingsService.showBackgroundImage,
            ),
          ),
          // Fondo desenfocado (lienzo): el texto se lee sobre cualquier foto.
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 36, sigmaY: 36),
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
          ),
          child!,
        ],
      ),
      child: content,
    );
  }

  /// Vertical: todo en una columna (se desplaza si no cabe).
  Widget _tallLayout(
    BuildContext context,
    Hymn hymn,
    BoxConstraints constraints,
  ) {
    const margin = GlassMetrics.screenMarginPhone;
    final width = math.min(constraints.maxWidth, 520.0);
    final cover = math.min(
      width - 2 * margin - 40,
      constraints.maxHeight * .36,
    );
    return Column(
      children: [
        _header(context, hymn),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(margin, 8, margin, 16),
            child: Center(
              child: SizedBox(
                width: width - 2 * margin,
                child: Column(
                  children: [
                    _Cover(
                      size: cover,
                      number: hymn.number,
                      hymnal: _audioService.currentHymnal?.name ?? '',
                    ),
                    const SizedBox(height: 28),
                    ..._details(context, hymn),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Horizontal (tableta acostada): portada a la izquierda, el resto a la
  /// derecha.
  Widget _wideLayout(
    BuildContext context,
    Hymn hymn,
    BoxConstraints constraints,
  ) {
    final cover = math.min(constraints.maxHeight * .62, 420.0);
    return Column(
      children: [
        _header(context, hymn),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    _Cover(
                      size: cover,
                      number: hymn.number,
                      hymnal: _audioService.currentHymnal?.name ?? '',
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(children: _details(context, hymn)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Cerrar, "Reproduciendo", favorito y compartir.
  Widget _header(BuildContext context, Hymn? hymn) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GlassMetrics.screenMarginPhone,
        8,
        GlassMetrics.screenMarginPhone,
        4,
      ),
      child: Row(
        children: [
          if (widget.onClose != null)
            GlassIconButton(
              icon: Icons.keyboard_arrow_down_rounded,
              semanticLabel: l10n.closePlayer,
              onPressed: widget.onClose,
            )
          else
            const SizedBox(width: GlassMetrics.iconButton),
          Expanded(
            child: Text(
              l10n.nowPlaying,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: GlassTypography.ui,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
          ),
          if (hymn != null) ...[
            GlassIconButton(
              icon: _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              iconColor: _isFavorite ? tokens.favorite : null,
              semanticLabel: _isFavorite
                  ? l10n.favoriteRemove
                  : l10n.favoriteAdd,
              onPressed: _toggleFavorite,
            ),
            const SizedBox(width: GlassMetrics.gapS),
            GlassIconButton(
              icon: Icons.ios_share_rounded,
              semanticLabel: l10n.share,
              onPressed: _shareHymn,
            ),
          ] else
            const SizedBox(width: GlassMetrics.iconButton),
        ],
      ),
    );
  }

  /// Título, progreso, controles, versión y "A continuación".
  List<Widget> _details(BuildContext context, Hymn hymn) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = GlassTokens.of(context);
    final instrumental = _audioService.isInstrumental;
    final section = _sectionOf(hymn.number);
    final duration = _audioService.duration;
    final position = _audioService.position;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final next = _nextAfter(hymn);
    final speed = _audioService.speed.round().clamp(1, 3);
    final timeStyle = TextStyle(
      fontFamily: GlassTypography.ui,
      fontSize: 12,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: tokens.textSecondary,
    );

    return [
      Text(
        hymn.title,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: GlassTypography.content,
          fontSize: 26,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: tokens.textPrimary,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        [?section, instrumental ? l10n.instrumental : l10n.sung].join(' · '),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: GlassTypography.ui,
          fontSize: 14,
          color: tokens.textSecondary,
        ),
      ),
      const SizedBox(height: 18),

      // Progreso: arrastrar para ir a otro punto.
      GlassSlider(
        value: progress,
        activeColor: tokens.vivid,
        semanticFormatterCallback: (_) =>
            '${_time(position)} / ${_time(duration)}',
        onChanged: duration > Duration.zero
            ? (v) => _audioService.seek(duration * v)
            : null,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Text(_time(position), style: timeStyle),
            const Spacer(),
            _PlayerChip(
              label: '$speed×',
              semanticLabel: l10n.playerSpeed(speed),
              selected: speed > 1,
              onTap: _cycleSpeed,
            ),
            const Spacer(),
            Text(
              duration > Duration.zero
                  ? '-${_time(duration - position)}'
                  : '--:--',
              style: timeStyle,
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),

      // Anterior, −10 s, reproducir, +10 s, siguiente.
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GlassIconButton(
            icon: Icons.skip_previous_rounded,
            semanticLabel: l10n.playerPreviousHymn,
            onPressed: _audioService.skipPrevious,
          ),
          _PlainIcon(
            icon: Icons.replay_10_rounded,
            label: l10n.playerSeekBack,
            onTap: () => _audioService.seek(
              position - const Duration(seconds: 10) < Duration.zero
                  ? Duration.zero
                  : position - const Duration(seconds: 10),
            ),
          ),
          LiquidPlayButton(
            isPlaying: _audioService.isPlaying,
            onPressed: _audioService.togglePlayPause,
            playLabel: l10n.playerPlay,
            pauseLabel: l10n.playerPause,
            diameter: 80,
            tint: tokens.buttonTint,
          ),
          _PlainIcon(
            icon: Icons.forward_10_rounded,
            label: l10n.playerSeekForward,
            onTap: () {
              final target = position + const Duration(seconds: 10);
              _audioService.seek(target > duration ? duration : target);
            },
          ),
          GlassIconButton(
            icon: Icons.skip_next_rounded,
            semanticLabel: l10n.playerNextHymn,
            onPressed: _audioService.skipNext,
          ),
        ],
      ),
      const SizedBox(height: 22),

      // Versión y reproducción continua.
      Row(
        children: [
          Expanded(
            child: _hasInstrumental && _hasSung
                ? GlassSegmented<bool>(
                    height: 48,
                    segments: [
                      GlassSegment(value: true, label: l10n.instrumental),
                      GlassSegment(value: false, label: l10n.sung),
                    ],
                    selected: instrumental,
                    onChanged: (v) {
                      if (v != instrumental) {
                        _audioService.switchVersion(instrumental: v);
                      }
                    },
                  )
                : Text(
                    instrumental ? l10n.instrumental : l10n.sung,
                    style: GlassTypography.listRow(
                      tokens.textPrimary,
                      selected: true,
                    ),
                  ),
          ),
          const SizedBox(width: GlassMetrics.gapS),
          _PlayerChip(
            label: l10n.continuousShort,
            icon: Icons.repeat_rounded,
            semanticLabel: l10n.continuousPlay,
            selected: _audioService.continuousPlay,
            onTap: _audioService.toggleContinuousPlay,
          ),
        ],
      ),
      const SizedBox(height: 16),

      // "A continuación" y "Ver letra".
      SizedBox(
        height: 72,
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (next != null) ...[
                        Text(
                          l10n.upNext.toUpperCase(),
                          style: TextStyle(
                            fontFamily: GlassTypography.ui,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .6,
                            color: tokens.textSecondary,
                          ),
                        ),
                        Text(
                          '${next.number} · ${next.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: GlassTypography.ui,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _PlayerChip(
                  label: l10n.viewLyrics,
                  icon: Icons.notes_rounded,
                  onTap: _viewLyrics,
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }
}

/// Portada de cristal: el número del himno en Literata grande y el
/// himnario debajo.
class _Cover extends StatelessWidget {
  const _Cover({
    required this.size,
    required this.number,
    required this.hymnal,
  });

  final double size;
  final int number;
  final String hymnal;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return SizedBox.square(
      dimension: size,
      child: GlassCard(
        child: Padding(
          padding: EdgeInsets.all(size * .08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontFamily: GlassTypography.content,
                      fontSize: size * .42,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
              ),
              SizedBox(height: size * .03),
              Text(
                hymnal,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: GlassTypography.ui,
                  fontSize: math.max(12, size * .05),
                  fontWeight: FontWeight.w500,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ícono sin cápsula (−10 s / +10 s, como en el lienzo).
class _PlainIcon extends StatelessWidget {
  const _PlainIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      onPressed: onTap,
      iconSize: 30,
      color: GlassTokens.of(context).textPrimary,
      icon: Icon(icon),
    );
  }
}

/// Chip del reproductor (velocidad, Continua, Ver letra): cápsula clara
/// translúcida con borde brillante; activo, en el color de acento.
class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.label,
    required this.onTap,
    this.icon,
    this.semanticLabel,
    this.selected = false,
  });

  final String label;
  final IconData? icon;
  final String? semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = selected ? tokens.vivid : tokens.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel ?? label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: dark ? const Color(0x33FFFFFF) : const Color(0xB3FFFFFF),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected
                ? tokens.vivid.withValues(alpha: .6)
                : const Color(0x66FFFFFF),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: GlassTypography.ui,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/data/repository/hymnal_repository.dart';
import 'package:hymnal_app/layers/domain/model/hymn.dart';
import 'package:hymnal_app/layers/domain/model/hymnal.dart';
import 'package:hymnal_app/layers/domain/model/music_settings.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
import 'package:hymnal_app/widgets/app_scaffold.dart';
import 'package:hymnal_app/widgets/glass/glass_icon_button.dart';
import 'package:hymnal_app/widgets/glass/glass_pill.dart';
import 'package:hymnal_app/widgets/glass/glass_zone.dart';

part 'sheets_controller.dart';

/// Partitura (lienzo, pantallas 6 y 10): encabezado con Volver y una
/// cápsula "PARTITURA · HIMNO 1 / título". En celular, abajo una cápsula
/// con reproducir, versión, tiempo y progreso, y el botón "Letra". En
/// tableta, arriba a la derecha el zoom (− 100 % +) y abajo la cápsula de
/// audio con "Página 1 de N". Un toque en la partitura oculta todo.
class SheetsScreen extends StatefulWidget {
  final Hymnal hymnal;
  final int hymnNumber;

  const SheetsScreen({
    super.key,
    required this.hymnal,
    required this.hymnNumber,
  });

  @override
  State<SheetsScreen> createState() => _SheetsScreenState();
}

class _SheetsScreenState extends _SheetsController {
  static const Duration _slide = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    return ListenableBuilder(
      listenable: GetIt.I<SettingsService>(),
      builder: (context, _) => AppScaffold(
        // La cápsula de audio propia reemplaza al mini reproductor.
        showPlayer: !_hasAudio,
        body: Stack(
          children: [
            Positioned.fill(child: _sheets(context, l10n)),
            // Encabezado: se desliza hacia arriba al ocultarse (el cristal
            // no se crea ni se destruye).
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                duration: _slide,
                curve: Curves.easeOutCubic,
                offset: _chromeVisible ? Offset.zero : const Offset(0, -1.6),
                child: IgnorePointer(
                  ignoring: !_chromeVisible,
                  child: SafeArea(
                    bottom: false,
                    child: _header(context, l10n, tablet),
                  ),
                ),
              ),
            ),
            if (_hasBottomBar(context))
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedSlide(
                  duration: _slide,
                  curve: Curves.easeOutCubic,
                  offset: _chromeVisible ? Offset.zero : const Offset(0, 1.6),
                  child: IgnorePointer(
                    ignoring: !_chromeVisible,
                    child: SafeArea(
                      top: false,
                      child: _bottomBar(context, l10n, tablet),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sheets(BuildContext context, AppLocalizations l10n) {
    final tokens = GlassTokens.of(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final error = _errorMessage;
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_off_rounded,
              size: 56,
              color: tokens.textSecondary,
            ),
            const SizedBox(height: 14),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GlassTypography.listRow(tokens.textPrimary),
            ),
          ],
        ),
      );
    }
    final insets = MediaQuery.paddingOf(context);
    final top = insets.top + 72;
    // Abajo, el espacio de la cápsula de audio (hasta que la partitura sea
    // transparente, fase 6, las notas no deben quedar debajo de ella).
    final bottom = _hasBottomBar(context) ? insets.bottom + 84 : 0.0;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _toggleChrome,
      child: AnimatedPadding(
        duration: _slide,
        curve: Curves.easeOutCubic,
        // La partitura empieza bajo el encabezado mientras se ve.
        padding: _chromeVisible
            ? EdgeInsets.only(top: top, bottom: bottom)
            : EdgeInsets.zero,
        child: PhotoViewGallery.builder(
          itemCount: _sheetUrls.length,
          builder: (context, index) => PhotoViewGalleryPageOptions(
            imageProvider: AssetImage(_sheetUrls[index]),
            controller: _zoom[index],
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.contained * 4,
            basePosition: Alignment.topCenter,
            tightMode: true,
            gestureDetectorBehavior: HitTestBehavior.translucent,
          ),
          onPageChanged: _onPageChanged,
          pageController: _pageController,
          scrollPhysics: const BouncingScrollPhysics(),
          backgroundDecoration: const BoxDecoration(color: Colors.transparent),
        ),
      ),
    );
  }

  /// Si hay cápsula inferior: audio, "Letra" (celular) o la página
  /// (tableta).
  bool _hasBottomBar(BuildContext context) =>
      _hasAudio ||
      MediaQuery.sizeOf(context).shortestSide < 600 ||
      _sheetUrls.isNotEmpty;

  /// Volver, la cápsula con el título y (en tableta) el zoom.
  Widget _header(BuildContext context, AppLocalizations l10n, bool tablet) {
    final tokens = GlassTokens.of(context);
    final title = _hymn?.title ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GlassMetrics.screenMarginPhone,
        8,
        GlassMetrics.screenMarginPhone,
        8,
      ),
      child: GlassZone(
        child: Row(
          children: [
            GlassIconButton(
              icon: Icons.chevron_left_rounded,
              semanticLabel: MaterialLocalizations.of(context)
                  .backButtonTooltip,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: GlassMetrics.gapS),
            Flexible(
              child: GlassPill(
                height: 56,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Semantics(
                        header: true,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.sheetMusic} · '
                                      '${l10n.hymnTitle(widget.hymnNumber)}'
                                  .toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: GlassTypography.ui,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .6,
                                color: tokens.textSecondary,
                              ),
                            ),
                            if (title.isNotEmpty)
                              Text(
                                title,
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
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (tablet) ...[
              const Spacer(),
              GlassPill(
                children: [
                  GlassPillAction(
                    icon: Icons.zoom_out_rounded,
                    semanticLabel: l10n.zoomOut,
                    onPressed: _zoomPercent > 100
                        ? () => _zoomBy(1 / 1.25)
                        : null,
                  ),
                  Text(
                    '$_zoomPercent %',
                    style: TextStyle(
                      fontFamily: GlassTypography.ui,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: tokens.textPrimary,
                    ),
                  ),
                  GlassPillAction(
                    icon: Icons.zoom_in_rounded,
                    semanticLabel: l10n.zoomIn,
                    onPressed: _zoomPercent < 400 ? () => _zoomBy(1.25) : null,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Cápsula de audio y, al lado, "Letra" (celular) o la página (tableta).
  Widget _bottomBar(BuildContext context, AppLocalizations l10n, bool tablet) {
    final tokens = GlassTokens.of(context);
    final pages = _sheetUrls.length;
    final pageLabel = l10n.pageOfTotal(_currentIndex + 1, pages);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            GlassMetrics.screenMarginPhone,
            8,
            GlassMetrics.screenMarginPhone,
            12,
          ),
          child: GlassZone(
            child: Row(
              children: [
                if (_hasAudio) Expanded(child: _audioCapsule(context, l10n)),
                if (_hasAudio) const SizedBox(width: GlassMetrics.gapS),
                if (!tablet)
                  GlassPill(
                    height: 64,
                    children: [
                      _TextAction(
                        icon: Icons.notes_rounded,
                        label: l10n.lyricsShort,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  )
                else if (pages > 0)
                  GlassPill(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          pageLabel,
                          style: TextStyle(
                            fontFamily: GlassTypography.ui,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Reproducir, "Instrumental · 2:23" y la barra de progreso.
  Widget _audioCapsule(BuildContext context, AppLocalizations l10n) {
    final tokens = GlassTokens.of(context);
    return ListenableBuilder(
      listenable: _audioService,
      builder: (context, _) {
        final current = _isCurrent;
        final playing = current && _audioService.isPlaying;
        final instrumental = current
            ? _audioService.isInstrumental
            : _urlFor(instrumental: true) != null;
        final duration = current ? _audioService.duration : Duration.zero;
        final position = current ? _audioService.position : Duration.zero;
        final progress = duration.inMilliseconds > 0
            ? (position.inMilliseconds / duration.inMilliseconds).clamp(
                0.0,
                1.0,
              )
            : 0.0;
        String time(Duration d) =>
            '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
        final version = instrumental ? l10n.instrumental : l10n.sung;
        return GlassPill(
          height: 64,
          children: [
            const SizedBox(width: 6),
            _PlayCircle(
              playing: playing,
              label: playing ? l10n.playerPause : l10n.playerPlay,
              color: tokens.buttonTint,
              onTap: _togglePlay,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      duration > Duration.zero
                          ? '$version · ${time(duration)}'
                          : version,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: GlassTypography.ui,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        color: tokens.vivid,
                        backgroundColor: tokens.textPrimary.withValues(
                          alpha: .12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Botón circular tintado de reproducir (sin cristal propio: va dentro de
/// la cápsula de cristal).
class _PlayCircle extends StatelessWidget {
  const _PlayCircle({
    required this.playing,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final bool playing;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: color,
        shape: const CircleBorder(side: BorderSide(color: Color(0x66FFFFFF))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: 48,
            child: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

/// Acción con ícono y texto dentro de una cápsula ("Letra").
class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: tokens.textPrimary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: GlassTypography.ui,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
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

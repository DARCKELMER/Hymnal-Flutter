import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/data/repository/hymnal_repository.dart';
import 'package:hymnal_app/layers/domain/model/hymn.dart';
import 'package:hymnal_app/layers/domain/model/hymnal.dart';
import 'package:hymnal_app/layers/domain/model/music_settings.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/services/background_service.dart';
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
            // Cielo claro arriba que se funde con el paisaje abajo (de
            // noche, cielo nocturno): las notas se leen sobre él.
            Positioned.fill(child: _SkyFade(dark: _isDark(context))),
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
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    // Espacio del encabezado y de la cápsula inferior: la primera línea no
    // queda tapada y la última se puede subir por encima de la cápsula.
    final top = insets.top + 76;
    final bottom = _hasBottomBar(context) ? insets.bottom + 90 : 24.0;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = constraints.biggest;
        final landscape = constraints.maxWidth > constraints.maxHeight;
        // En tableta horizontal, dos páginas lado a lado si hay varias.
        _perRow = landscape && tablet && _sheetUrls.length > 1 ? 2 : 1;
        const gap = 16.0;
        final available = constraints.maxHeight - top - bottom;
        final aspect = _sizes.isEmpty
            ? 1275 / 1650
            : _sizes.first.width / _sizes.first.height;
        // Horizontal: la página entera a lo alto. Vertical: a lo ancho.
        final pageWidth = landscape
            ? math.min(
                (constraints.maxWidth - 48 - gap * (_perRow - 1)) / _perRow,
                available * aspect,
              )
            : math.min(constraints.maxWidth - 24, 900.0);

        final rows = <Widget>[];
        final tops = <double>[];
        var y = top;
        for (var r = 0; r * _perRow < _sheetUrls.length; r++) {
          final pages = [
            for (
              var k = r * _perRow;
              k < math.min((r + 1) * _perRow, _sheetUrls.length);
              k++
            )
              k,
          ];
          final rowHeight = pages
              .map((k) => pageWidth * _sizes[k].height / _sizes[k].width)
              .reduce(math.max);
          tops.add(y);
          y += rowHeight + gap;
          rows.add(
            SizedBox(
              height: rowHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (n, k) in pages.indexed) ...[
                    if (n > 0) const SizedBox(width: gap),
                    SizedBox(
                      width: pageWidth,
                      child: _SheetPage(
                        image: AssetImage(_sheetUrls[k]),
                        dark: dark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        _rowTops = tops;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _toggleChrome,
          onDoubleTapDown: (details) => _doubleTapAt = details.localPosition,
          onDoubleTap: _onDoubleTap,
          child: InteractiveViewer(
            transformationController: _transform,
            constrained: false,
            minScale: 1,
            maxScale: 4,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Padding(
                padding: EdgeInsets.only(top: top, bottom: bottom),
                child: Column(
                  children: [
                    for (final (n, row) in rows.indexed) ...[
                      if (n > 0) const SizedBox(height: gap),
                      row,
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

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
            // En celular la cápsula llena el espacio; en tableta, solo lo
            // que ocupa su texto.
            Flexible(
              fit: tablet ? FlexFit.loose : FlexFit.tight,
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
            // Cambiar paisaje (el siguiente de la galería).
            if (_backgrounds?.isReady ?? false) ...[
              const SizedBox(width: GlassMetrics.gapS),
              GlassIconButton(
                icon: Icons.image_outlined,
                semanticLabel: l10n.changeBackground,
                onPressed: _backgrounds!.showNext,
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

/// Una página de partitura **transparente**: el papel blanco desaparece y
/// las notas se pintan en tinta (`#141824`; blancas de noche), con un halo
/// desenfocado del color contrario detrás para que se lean sobre el
/// paisaje.
class _SheetPage extends StatelessWidget {
  const _SheetPage({required this.image, required this.dark});

  final ImageProvider image;
  final bool dark;

  /// Matriz de color: lo blanco queda transparente y todo se pinta de
  /// [color]. Alfa = (alfa original − luminancia) × [strength]: lo que ya
  /// era transparente (fuera de la imagen) sigue transparente. (Con
  /// "255 − luminancia" el filtro, que se aplica a toda la capa, volvía
  /// opaco todo lo de alrededor de la página.)
  static ColorFilter _ink(Color color, {double strength = 1}) {
    final r = (color.r * 255).roundToDouble();
    final g = (color.g * 255).roundToDouble();
    final b = (color.b * 255).roundToDouble();
    return ColorFilter.matrix([
      0, 0, 0, 0, r, //
      0, 0, 0, 0, g, //
      0, 0, 0, 0, b, //
      -0.2126 * strength, -0.7152 * strength, -0.0722 * strength, strength,
      0,
    ]);
  }

  static const Color _inkLight = Color(0xFF141824);
  static const Color _inkDark = Color(0xFFF2F4F8);
  static const Color _haloLight = Color(0xFFFFFFFF);
  static const Color _haloDark = Color(0xFF0B1220);

  @override
  Widget build(BuildContext context) {
    final picture = Image(
      image: image,
      fit: BoxFit.fitWidth,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
    return RepaintBoundary(
      child: Stack(
        children: [
          // Halo: una copia del color contrario, más gruesa y desenfocada.
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
            child: ColorFiltered(
              colorFilter: _ink(dark ? _haloDark : _haloLight, strength: 2.2),
              child: picture,
            ),
          ),
          ColorFiltered(
            colorFilter: _ink(dark ? _inkDark : _inkLight),
            child: picture,
          ),
        ],
      ),
    );
  }
}

/// Cielo de la partitura: claro (o nocturno) en la mitad de arriba,
/// fundiéndose con el paisaje en la de abajo.
class _SkyFade extends StatelessWidget {
  const _SkyFade({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final sky = dark ? const Color(0xFF0B1220) : const Color(0xFFF1F5FA);
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              sky.withValues(alpha: .94),
              sky.withValues(alpha: .80),
              sky.withValues(alpha: 0),
            ],
            stops: const [0, .45, .78],
          ),
        ),
      ),
    );
  }
}

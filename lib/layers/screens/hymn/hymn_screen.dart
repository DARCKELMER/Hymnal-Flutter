import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:hymnal_app/layers/data/repository/hymnal_repository.dart';
import 'package:hymnal_app/layers/domain/model/hymn.dart';
import 'package:hymnal_app/layers/domain/model/hymnal.dart';
import 'package:hymnal_app/layers/domain/model/music_settings.dart';
import 'package:hymnal_app/layers/domain/model/thematic_category.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_lyrics.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/services/favorites_service.dart';
import 'package:hymnal_app/services/history_service.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/layers/screens/sheets/sheets_screen.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
import 'package:hymnal_app/widgets/app_scaffold.dart';
import 'package:hymnal_app/widgets/glass/glass_card.dart';
import 'package:hymnal_app/widgets/glass/glass_controls.dart';
import 'package:hymnal_app/widgets/glass/glass_icon_button.dart';
import 'package:hymnal_app/widgets/glass/glass_pill.dart';
import 'package:hymnal_app/widgets/glass/glass_segmented.dart';
import 'package:hymnal_app/widgets/glass/glass_zone.dart';
import 'package:hymnal_app/widgets/glass/liquid_play_button.dart';

import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/constants/app_links.dart';

part 'hymn_controller.dart';

/// Himno (lienzo, pantallas 3 y 8): encabezado con Volver y una cápsula
/// de acciones (Aa, favorito, partitura, compartir), la tarjeta de letra
/// con estrofas numeradas y, abajo, Instrumental/Cantado con el botón de
/// reproducir. Se desliza entre himnos viendo el borde de las tarjetas
/// vecinas. En tableta: "‹ Himno 1 de 614 ›" y, en vertical, una tarjeta
/// "Siguiente himno".
class HymnScreen extends StatefulWidget {
  final String hymnalId;
  final int hymnNumber;
  final bool skipHistory;

  const HymnScreen({
    super.key,
    required this.hymnalId,
    required this.hymnNumber,
    this.skipHistory = false,
  });

  @override
  State<HymnScreen> createState() => _HymnScreenState();
}

class _HymnScreenState extends _HymnController {
  HymnLayout _layout(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.shortestSide < 600) return HymnLayout.phone;
    return size.width > size.height
        ? HymnLayout.tabletLandscape
        : HymnLayout.tabletPortrait;
  }

  @override
  Widget build(BuildContext context) {
    final hymn = _hymn;
    final hymns = _allHymns;
    final controller = _pageController;
    if (hymn == null || hymns == null || controller == null) {
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final layout = _layout(context);
    final hasAudio =
        _hasVersion(hymn, instrumental: true) ||
        _hasVersion(hymn, instrumental: false);

    return AppScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(context, layout, hymn, hymns.length),
            Expanded(
              child: ListenableBuilder(
                listenable: _settingsService,
                builder: (context, _) => PageView.builder(
                  controller: controller,
                  onPageChanged: _onPageChanged,
                  itemCount: hymns.length,
                  itemBuilder: (context, index) =>
                      _page(context, layout, hymns, index),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: hasAudio ? _audioBar(context, hymn) : null,
    );
  }

  /// Volver, (en tableta) "‹ Himno 1 de 614 ›" y la cápsula de acciones.
  Widget _header(
    BuildContext context,
    HymnLayout layout,
    Hymn hymn,
    int total,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = GlassTokens.of(context);
    final canPop = Navigator.of(context).canPop();
    final hasSheets = _hymnal?.hymnsSheetsFileName != null;
    final index = _allHymns!.indexOf(hymn);
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
            if (canPop)
              GlassIconButton(
                icon: Icons.chevron_left_rounded,
                semanticLabel: MaterialLocalizations.of(context)
                    .backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            Expanded(
              child: layout == HymnLayout.phone
                  ? const SizedBox()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: l10n.playerPreviousHymn,
                          onPressed: index > 0 ? () => _goTo(-1) : null,
                          icon: const Icon(Icons.chevron_left_rounded),
                          color: tokens.textPrimary,
                        ),
                        Text(
                          l10n.hymnOfTotal(hymn.number, total),
                          style: GlassTypography.listRow(
                            tokens.textPrimary,
                            selected: true,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.playerNextHymn,
                          onPressed: index < total - 1 ? () => _goTo(1) : null,
                          icon: const Icon(Icons.chevron_right_rounded),
                          color: tokens.textPrimary,
                        ),
                      ],
                    ),
            ),
            GlassPill(
              children: [
                GlassPillAction(
                  icon: Icons.text_fields_rounded,
                  semanticLabel: l10n.fontSize,
                  onPressed: _showFontSize,
                ),
                GlassPillAction(
                  icon: _isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  semanticLabel: _isFavorite
                      ? l10n.favoriteRemove
                      : l10n.favoriteAdd,
                  selected: _isFavorite,
                  color: _isFavorite ? tokens.favorite : null,
                  onPressed: _toggleFavorite,
                ),
                if (hasSheets)
                  GlassPillAction(
                    icon: Icons.library_music_rounded,
                    semanticLabel: l10n.sheetMusic,
                    onPressed: _openSheets,
                  ),
                GlassPillAction(
                  icon: Icons.ios_share_rounded,
                  semanticLabel: l10n.share,
                  onPressed: _shareHymn,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Una página: la tarjeta de letra (y en tableta vertical, "Siguiente
  /// himno").
  Widget _page(
    BuildContext context,
    HymnLayout layout,
    List<Hymn> hymns,
    int index,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final hymn = hymns[index];
    final section = _sectionOf(hymn.number);
    final next = index + 1 < hymns.length ? hymns[index + 1] : null;
    // En celular se ve el borde de las tarjetas vecinas como pista.
    final side = layout == HymnLayout.phone ? 6.0 : GlassMetrics.gapL;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(side, 4, side, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HymnLyricsCard(
                label: [l10n.hymnTitle(hymn.number), ?section].join(' · '),
                title: hymn.title,
                author: hymn.author,
                content: hymn.content,
                layout: layout,
                userFontSize: _settingsService.fontSize,
                onSelectionChanged: (text) => _selectedText = text,
                contextMenu: _selectionMenu,
              ),
              if (layout == HymnLayout.tabletPortrait && next != null) ...[
                const SizedBox(height: GlassMetrics.gapL),
                _NextHymnCard(
                  label: l10n.nextHymnCard,
                  hymn: next,
                  onTap: () => _goTo(1),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Abajo: Instrumental/Cantado y el botón tintado de reproducir de 64 dp.
  Widget _audioBar(BuildContext context, Hymn hymn) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = GlassTokens.of(context);
    final hasInstrumental = _hasVersion(hymn, instrumental: true);
    final hasSung = _hasVersion(hymn, instrumental: false);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GlassMetrics.screenMarginPhone,
          6,
          GlassMetrics.screenMarginPhone,
          10,
        ),
        child: GlassZone(
          child: ListenableBuilder(
            listenable: _audioService,
            builder: (context, _) {
              final playing = _isCurrentInPlayer && _audioService.isPlaying;
              return Row(
                children: [
                  Expanded(
                    child: hasInstrumental && hasSung
                        ? GlassSegmented<bool>(
                            height: 56,
                            segments: [
                              GlassSegment(
                                value: true,
                                label: l10n.instrumental,
                                icon: Icons.piano_rounded,
                              ),
                              GlassSegment(
                                value: false,
                                label: l10n.sung,
                                icon: Icons.mic_rounded,
                              ),
                            ],
                            selected: _instrumental,
                            onChanged: _selectVersion,
                          )
                        : Text(
                            hasInstrumental ? l10n.instrumental : l10n.sung,
                            style: GlassTypography.listRow(
                              tokens.textPrimary,
                              selected: true,
                            ),
                          ),
                  ),
                  const SizedBox(width: GlassMetrics.gapS),
                  LiquidPlayButton(
                    isPlaying: playing,
                    onPressed: _togglePlay,
                    playLabel: l10n.playerPlay,
                    pauseLabel: l10n.playerPause,
                    tint: tokens.buttonTint,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Tarjeta "Siguiente himno" bajo la letra (tableta vertical).
class _NextHymnCard extends StatelessWidget {
  const _NextHymnCard({
    required this.label,
    required this.hymn,
    required this.onTap,
  });

  final String label;
  final Hymn hymn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return SizedBox(
      height: 76,
      child: GlassCard(
        child: Semantics(
          container: true,
          button: true,
          label: '$label: ${hymn.number}. ${hymn.title}',
          onTap: onTap,
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: TextStyle(
                            fontFamily: GlassTypography.ui,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: .6,
                            color: tokens.accent,
                          ),
                        ),
                        Text(
                          '${hymn.number}. ${hymn.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: GlassTypography.content,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: tokens.textPrimary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/core/constants/app_assets.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
import 'package:hymnal_app/widgets/glass/glass_controls.dart';
import 'package:hymnal_app/widgets/glass/glass_icon_button.dart';
import 'package:hymnal_app/widgets/glass/glass_navigation_rail.dart';
import 'package:hymnal_app/widgets/glass/glass_pill.dart';
import 'package:hymnal_app/widgets/glass/glass_scope.dart';
import 'package:hymnal_app/widgets/glass/glass_segmented.dart';
import 'package:hymnal_app/widgets/glass/glass_zone.dart';
import 'package:hymnal_app/widgets/glass/lyrics_card.dart';

/// Catálogo de los componentes del sistema de diseño de cristal (Fase 2),
/// sobre el paisaje, con el ajuste "Cristal" en vivo.
///
/// Solo accesible desde Ajustes en modo debug.
class GlassCatalogScreen extends StatefulWidget {
  const GlassCatalogScreen({super.key});

  @override
  State<GlassCatalogScreen> createState() => _GlassCatalogScreenState();
}

enum _Order { numeric, alpha, thematic }

enum _Audio { instrumental, sung }

class _GlassCatalogScreenState extends State<GlassCatalogScreen> {
  _Order _order = _Order.numeric;
  _Audio _audio = _Audio.instrumental;
  ThemeMode _themeSample = ThemeMode.system;
  bool _favorite = false;
  bool _switchOn = true;
  double _fontSample = GlassTypography.defaultUserFontSize;
  int _railIndex = 0;
  Future<String?>? _stanza;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stanza ??= _loadFirstStanza(Localizations.localeOf(context).languageCode);
  }

  /// Primera estrofa del himno 1 en el idioma de la app (datos reales).
  static Future<String?> _loadFirstStanza(String language) async {
    const supported = ['es', 'en', 'pt', 'ru'];
    final code = supported.contains(language) ? language : 'es';
    try {
      final raw = await rootBundle.loadString(
        'assets/hymns/new_hymnal_$code.json',
      );
      final hymns = jsonDecode(raw) as List<dynamic>;
      final first = hymns.first as Map<String, dynamic>;
      final content = first['content'] as String;
      return content.split('\n\n').first.trim();
    } on Object {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = GlassTokens.of(context);
    final settings = GetIt.I.isRegistered<SettingsService>()
        ? GetIt.I<SettingsService>()
        : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        title: Text(l10n.glassCatalogTitle),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.backgroundImage, fit: BoxFit.cover),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                GlassMetrics.screenMarginPhone,
                8,
                GlassMetrics.screenMarginPhone,
                32,
              ),
              children: [
                if (settings != null) _tintSlider(l10n, settings),
                _section(l10n.glassCatalogButtons),
                GlassZone(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: GlassMetrics.gapS,
                        runSpacing: GlassMetrics.gapS,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          GlassIconButton(
                            icon: Icons.search_rounded,
                            semanticLabel: l10n.search,
                            onPressed: () {},
                          ),
                          GlassIconButton(
                            icon: Icons.search_rounded,
                            semanticLabel: l10n.search,
                            onPressed: () {},
                            bar: true,
                          ),
                          GlassIconButton(
                            icon: Icons.play_arrow_rounded,
                            semanticLabel: l10n.playerPlay,
                            onPressed: () {},
                            bar: true,
                            prominent: true,
                          ),
                          GlassPill(
                            children: [
                              GlassPillAction(
                                icon: Icons.ios_share_rounded,
                                semanticLabel: l10n.share,
                                onPressed: () {},
                              ),
                              GlassPillAction(
                                icon: _favorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                semanticLabel: l10n.favorites,
                                selected: _favorite,
                                color: _favorite ? tokens.favorite : null,
                                onPressed: () =>
                                    setState(() => _favorite = !_favorite),
                              ),
                              GlassPillAction(
                                icon: Icons.library_music_rounded,
                                semanticLabel: l10n.sheetMusic,
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                      _section(l10n.glassCatalogControls),
                      GlassSegmented<_Order>(
                        segments: [
                          GlassSegment(
                            value: _Order.numeric,
                            label: l10n.numeric,
                          ),
                          GlassSegment(value: _Order.alpha, label: l10n.alpha),
                          GlassSegment(
                            value: _Order.thematic,
                            label: l10n.thematic,
                          ),
                        ],
                        selected: _order,
                        onChanged: (v) => setState(() => _order = v),
                      ),
                      const SizedBox(height: GlassMetrics.gapS),
                      GlassSegmented<_Audio>(
                        segments: [
                          GlassSegment(
                            value: _Audio.instrumental,
                            label: l10n.instrumental,
                            icon: Icons.piano_rounded,
                          ),
                          GlassSegment(
                            value: _Audio.sung,
                            label: l10n.sung,
                            icon: Icons.mic_rounded,
                          ),
                        ],
                        selected: _audio,
                        onChanged: (v) => setState(() => _audio = v),
                      ),
                      const SizedBox(height: GlassMetrics.gapS),
                      GlassSegmented<ThemeMode>(
                        segments: [
                          GlassSegment(
                            value: ThemeMode.light,
                            label: l10n.themeLight,
                          ),
                          GlassSegment(
                            value: ThemeMode.dark,
                            label: l10n.themeDark,
                          ),
                          GlassSegment(
                            value: ThemeMode.system,
                            label: l10n.themeSystem,
                          ),
                        ],
                        selected: _themeSample,
                        onChanged: (v) => setState(() => _themeSample = v),
                      ),
                      const SizedBox(height: GlassMetrics.gapS),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.keepScreenOn,
                              style: GlassTypography.listRow(
                                tokens.textPrimary,
                              ),
                            ),
                          ),
                          GlassSwitch(
                            value: _switchOn,
                            semanticLabel: l10n.keepScreenOn,
                            onChanged: (v) => setState(() => _switchOn = v),
                          ),
                        ],
                      ),
                      Text(
                        l10n.fontSize,
                        style: GlassTypography.listRow(tokens.textPrimary),
                      ),
                      GlassSlider(
                        value: _fontSample,
                        min: 12,
                        max: 32,
                        divisions: 10,
                        label: _fontSample.round().toString(),
                        onChanged: (v) => setState(() => _fontSample = v),
                      ),
                      _section(l10n.glassCatalogNavigation),
                      GlassNavigationRail(
                        destinations: [
                          GlassRailDestination(
                            icon: Icons.home_rounded,
                            label: l10n.home,
                          ),
                          GlassRailDestination(
                            icon: Icons.format_list_bulleted_rounded,
                            label: l10n.lists,
                          ),
                          GlassRailDestination(
                            icon: Icons.favorite_rounded,
                            label: l10n.favorites,
                          ),
                          GlassRailDestination(
                            icon: Icons.settings_rounded,
                            label: l10n.settings,
                          ),
                        ],
                        selectedIndex: _railIndex,
                        onSelected: (i) => setState(() => _railIndex = i),
                      ),
                    ],
                  ),
                ),
                _section(l10n.glassCatalogLyrics),
                FutureBuilder<String?>(
                  future: _stanza,
                  builder: (context, snapshot) => LyricsCard(
                    child: Text(
                      snapshot.data ?? '',
                      style: GlassTypography.lyrics(
                        HymnLayout.phone,
                        tokens.textPrimary,
                        userFontSize: _fontSample,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tintSlider(AppLocalizations l10n, SettingsService settings) {
    final tokens = GlassTokens.of(context);
    final forced = GlassScope.of(context).forcedTint;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.glassTint,
            style: GlassTypography.listRow(tokens.textPrimary),
          ),
          GlassSlider(
            value: forced ? 1 : settings.glassTint,
            onChanged: forced ? null : settings.setGlassTint,
          ),
          Row(
            children: [
              Text(
                l10n.glassTransparent,
                style: GlassTypography.tabLabel(tokens.textSecondary),
              ),
              const Spacer(),
              Text(
                l10n.glassTinted,
                style: GlassTypography.tabLabel(tokens.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Text(
        GlassTypography.sectionText(title),
        style: GlassTypography.sectionLabel(tokens.textSecondary),
      ),
    );
  }
}

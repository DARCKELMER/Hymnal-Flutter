import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/core/utils/string_utils.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/data/repository/hymnal_repository.dart';
import 'package:hymnal_app/layers/domain/model/hymn.dart';
import 'package:hymnal_app/layers/domain/model/thematic_category.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_opener.dart';
import 'package:hymnal_app/layers/screens/lists/ambit_screen.dart';
import 'package:hymnal_app/services/history_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
import 'package:hymnal_app/widgets/glass/glass_hymn_list.dart';
import 'package:hymnal_app/widgets/glass/glass_segmented.dart';
import 'package:hymnal_app/widgets/glass/glass_zone.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

part 'lists_controller.dart';

/// Listas (lienzo, pantallas 2 y 9): encabezado con el himnario, control
/// segmentado Numérico / Alfabético / Temático y:
/// - Numérico y Alfabético: tarjeta de cristal con filas de 54 dp y un
///   índice lateral en cápsula.
/// - Temático: acordeones de cristal por tema con una grilla de secciones
///   (2 columnas en tableta, 1 en celular).
class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends _ListsController {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = GlassTokens.of(context);
    final hymnal = _settingsService.selectedHymnal;

    final Widget content;
    if (_hymns == null) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      // Las vistas quedan montadas: cambiar de vista no destruye ni vuelve
      // a crear el cristal (eso parpadeaba).
      final alpha = _mode == _ListMode.alpha;
      content = IndexedStack(
        index: _mode == _ListMode.thematic ? 1 : 0,
        sizing: StackFit.expand,
        // Cada vista con su propia capa de cristal: la oculta no se pinta
        // y su capa no dibuja nada (en una capa compartida, sus formas se
        // seguían dibujando como franjas sueltas).
        children: [
          GlassZone(
            child: _hymnList(
              alpha ? _alphabeticHymns! : _hymns!,
              alpha ? _alphabeticIndex : _numericIndex,
            ),
          ),
          GlassZone(child: _buildThematic(l10n)),
        ],
      );
    }

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GlassMetrics.screenMarginPhone,
          12,
          GlassMetrics.screenMarginPhone,
          0,
        ),
        child: GlassZone(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                hymnal?.name ?? '',
                style: GlassTypography.listRow(tokens.textSecondary)
                    .copyWith(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                l10n.lists,
                style: GlassTypography.screenTitle(tokens.textPrimary),
              ),
              const SizedBox(height: GlassMetrics.gapM),
              GlassSegmented<_ListMode>(
                segments: [
                  GlassSegment(value: _ListMode.numeric, label: l10n.numeric),
                  GlassSegment(value: _ListMode.alpha, label: l10n.alpha),
                  GlassSegment(value: _ListMode.thematic, label: l10n.thematic),
                ],
                selected: _mode,
                onChanged: (mode) => setState(() => _mode = mode),
              ),
              const SizedBox(height: GlassMetrics.gapM),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hymnList(List<Hymn> hymns, List<GlassIndexEntry> index) {
    return GlassHymnList(
      items: [
        for (final h in hymns) GlassHymnItem(number: h.number, title: h.title),
      ],
      hymnalId: _settingsService.selectedHymnal?.id,
      index: index,
      padding: const EdgeInsets.only(bottom: 8),
      onTap: (i) => _openHymn(hymns[i]),
    );
  }

  Widget _buildThematic(AppLocalizations l10n) {
    final themes = _thematicList ?? const <ThematicCategory>[];
    // 2 columnas en tableta y pantalla dividida, 1 en celular.
    final columns = MediaQuery.sizeOf(context).shortestSide >= 600 ? 2 : 1;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: themes.length,
      itemBuilder: (context, i) {
        final theme = themes[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: GlassMetrics.gapS),
          child: _ThemeCard(
            theme: theme,
            expanded: _expandedThemes.contains(i),
            columns: columns,
            subtitle: [
              l10n.sectionsCount(theme.ambits.length),
              if (theme.ambits.isNotEmpty)
                l10n
                    .hymnRange(theme.ambits.first.start, theme.ambits.last.end)
                    .toLowerCase(),
            ].join(' · '),
            rangeLabel: (a) => l10n.hymnRange(a.start, a.end),
            onToggle: () => _toggleTheme(i),
            onAmbit: (a) => _openAmbit(theme, a),
          ),
        );
      },
    );
  }
}

/// Acordeón de cristal de un tema: título, "5 secciones · himnos 1–52" y,
/// abierto, la grilla de secciones.
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.expanded,
    required this.columns,
    required this.subtitle,
    required this.rangeLabel,
    required this.onToggle,
    required this.onAmbit,
  });

  final ThematicCategory theme;
  final bool expanded;
  final int columns;
  final String subtitle;
  final String Function(Ambit ambit) rangeLabel;
  final VoidCallback onToggle;
  final ValueChanged<Ambit> onAmbit;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return LiquidGlass(
      shape: const LiquidRoundedSuperellipse(borderRadius: 24),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              container: true,
              button: true,
              expanded: expanded,
              label: '${theme.thematic}, $subtitle',
              onTap: onToggle,
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              theme.thematic,
                              style: GlassTypography.listRow(
                                tokens.textPrimary,
                                selected: true,
                              ).copyWith(fontSize: 17),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontFamily: GlassTypography.ui,
                                fontSize: 12,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: expanded ? .5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const gap = 10.0;
                          final width =
                              (constraints.maxWidth - gap * (columns - 1)) /
                              columns;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final ambit in theme.ambits)
                                SizedBox(
                                  width: width,
                                  child: _AmbitTile(
                                    name: ambit.name,
                                    range: rangeLabel(ambit),
                                    onTap: () => onAmbit(ambit),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sección de un tema: nombre y rango de himnos, en una tarjetita
/// translúcida (sin cristal propio: va dentro del acordeón de cristal).
class _AmbitTile extends StatelessWidget {
  const _AmbitTile({
    required this.name,
    required this.range,
    required this.onTap,
  });

  final String name;
  final String range;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      container: true,
      button: true,
      label: '$name, $range',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: dark ? const Color(0x24FFFFFF) : const Color(0xB3FFFFFF),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GlassTypography.listRow(
                    tokens.textPrimary,
                    selected: true,
                  ).copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  range,
                  style: TextStyle(
                    fontFamily: GlassTypography.ui,
                    fontSize: 12,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

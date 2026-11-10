import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_opener.dart';
import 'package:hymnal_app/services/history_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/widgets/app_scaffold.dart';
import 'package:hymnal_app/widgets/glass/glass_hymn_list.dart';
import 'package:hymnal_app/widgets/glass/glass_icon_button.dart';
import 'package:hymnal_app/widgets/glass/glass_screen_header.dart';
import 'package:hymnal_app/widgets/glass/glass_zone.dart';

part 'history_controller.dart';

/// Historial (lienzo 5.6): la misma lista de cristal que Listas, con el
/// himnario y la fecha en cada fila, y un botón para borrarlo.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends _HistoryController {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: _historyService,
      builder: (context, _) {
        final history = _historyService.history;
        return AppScaffold(
          body: SafeArea(
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
                    GlassScreenHeader(
                      title: l10n.history,
                      actions: [
                        if (history.isNotEmpty)
                          GlassIconButton(
                            icon: Icons.delete_sweep_outlined,
                            semanticLabel: l10n.clearHistory,
                            onPressed: _clearHistory,
                          ),
                      ],
                    ),
                    const SizedBox(height: GlassMetrics.gapM),
                    Expanded(
                      child: history.isEmpty
                          ? GlassEmptyState(
                              icon: Icons.history_rounded,
                              title: l10n.noHistoryYet,
                            )
                          : GlassHymnList(
                              items: [
                                for (final e in history)
                                  GlassHymnItem(
                                    number: e.hymnNumber,
                                    title: e.title,
                                    subtitle:
                                        '${_getHymnalName(e.hymnalId)} · '
                                        '${_formatDate(e.openedAt)}',
                                    hymnalId: e.hymnalId,
                                  ),
                              ],
                              padding: const EdgeInsets.only(bottom: 8),
                              onTap: (i) => _openHymn(
                                history[i].hymnalId,
                                history[i].hymnNumber,
                                history[i].title,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

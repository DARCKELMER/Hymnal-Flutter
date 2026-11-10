import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/domain/model/favorite_hymn.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_opener.dart';
import 'package:hymnal_app/services/favorites_service.dart';
import 'package:hymnal_app/services/history_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/widgets/glass/glass_hymn_list.dart';
import 'package:hymnal_app/widgets/glass/glass_screen_header.dart';
import 'package:hymnal_app/widgets/glass/glass_zone.dart';

part 'favorites_controller.dart';

/// Favoritos (lienzo 5.6): la misma lista de cristal que Listas. Se
/// reordena arrastrando (pulsación larga o el asa) y se quita deslizando
/// a la izquierda, con confirmación.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends _FavoritesController {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: Listenable.merge([_settingsService, _favoritesService]),
      builder: (context, _) {
        final favorites = _favoritesService.favorites;
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
                  GlassScreenHeader(title: l10n.favorites),
                  const SizedBox(height: GlassMetrics.gapM),
                  Expanded(
                    child: favorites.isEmpty
                        ? GlassEmptyState(
                            icon: Icons.favorite_border_rounded,
                            title: l10n.noFavoritesYet,
                            subtitle: l10n.addHymnsToFavorites,
                          )
                        : GlassHymnList(
                            items: [
                              for (final f in favorites)
                                GlassHymnItem(
                                  number: f.hymnNumber,
                                  title: f.title,
                                  subtitle: _getHymnalName(f.hymnalId),
                                  hymnalId: f.hymnalId,
                                ),
                            ],
                            padding: const EdgeInsets.only(bottom: 8),
                            onTap: (i) => _onFavoriteTapped(favorites[i]),
                            onReorder: _favoritesService.reorderFavorites,
                            confirmRemove: (i) => _confirmDismiss(favorites[i]),
                            onRemove: (i) => _onDismissed(favorites[i]),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

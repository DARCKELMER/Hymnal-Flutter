import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/services/favorites_service.dart';
import 'package:hymnal_app/services/history_service.dart';
import 'package:hymnal_app/layers/domain/model/favorite_hymn.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_screen.dart';
import 'package:hymnal_app/widgets/hymn_list_tile.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';

part 'favorites_controller.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends _FavoritesController {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: Listenable.merge([_settingsService, _favoritesService]),
      builder: (context, child) {
        final favorites = _favoritesService.favorites;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            toolbarHeight: MediaQuery.of(context).orientation == Orientation.landscape ? 40 : null,
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            titleTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            title: Text(l10n.favorites),
          ),
          body: favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noFavoritesYet,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.addHymnsToFavorites,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: favorites.length,
                  onReorderItem: _favoritesService.reorderFavorites,
                  itemBuilder: (context, index) {
                    final favorite = favorites[index];
                    return Dismissible(
                      key: ValueKey(favorite),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (_) => _confirmDismiss(favorite),
                      onDismissed: (_) => _onDismissed(favorite),
                      child: HymnListTile(
                        number: favorite.hymnNumber,
                        title: favorite.title,
                        subtitle: _getHymnalName(favorite.hymnalId),
                        trailing: const Icon(Icons.drag_handle),
                        onTap: () => _onFavoriteTapped(favorite),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

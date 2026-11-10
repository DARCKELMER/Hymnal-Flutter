import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/layers/data/repository/favorites_repository.dart';
import 'package:hymnal_app/layers/domain/model/favorite_hymn.dart';

class FavoritesService extends ChangeNotifier {
  final FavoritesRepository _repository = GetIt.I<FavoritesRepository>();

  List<FavoriteHymn> _favorites = [];
  bool _isLoading = false;

  List<FavoriteHymn> get favorites => _favorites;
  bool get isLoading => _isLoading;

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    _favorites = await _repository.getFavorites();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addFavorite(
    String hymnalId,
    int hymnNumber,
    String title,
  ) async {
    final favorite = FavoriteHymn(
      hymnalId: hymnalId,
      hymnNumber: hymnNumber,
      title: title,
      addedAt: DateTime.now(),
      orderIndex: _favorites.length,
    );

    await _repository.addFavorite(favorite);
    await loadFavorites();
  }

  Future<void> removeFavorite(String hymnalId, int hymnNumber) async {
    await _repository.removeFavorite(hymnalId, hymnNumber);
    await loadFavorites();
  }

  Future<void> clearFavorites() async {
    await _repository.clearFavorites();
    await loadFavorites();
  }

  Future<bool> isFavorite(String hymnalId, int hymnNumber) async {
    return await _repository.isFavorite(hymnalId, hymnNumber);
  }

  Future<void> toggleFavorite(
    String hymnalId,
    int hymnNumber,
    String title,
  ) async {
    final isFav = await isFavorite(hymnalId, hymnNumber);
    if (isFav) {
      await removeFavorite(hymnalId, hymnNumber);
    } else {
      await addFavorite(hymnalId, hymnNumber, title);
    }
  }

  /// Mueve el favorito de [oldIndex] a [newIndex].
  ///
  /// [newIndex] ya viene ajustado para la lista sin el elemento movido
  /// (semántica de `ReorderableListView.onReorderItem`).
  Future<void> reorderFavorites(int oldIndex, int newIndex) async {
    final item = _favorites.removeAt(oldIndex);
    _favorites.insert(newIndex, item);

    for (int i = 0; i < _favorites.length; i++) {
      _favorites[i] = FavoriteHymn(
        hymnalId: _favorites[i].hymnalId,
        hymnNumber: _favorites[i].hymnNumber,
        title: _favorites[i].title,
        addedAt: _favorites[i].addedAt,
        orderIndex: i,
      );
    }

    await _repository.reorderFavorites(_favorites);
    notifyListeners();
  }
}

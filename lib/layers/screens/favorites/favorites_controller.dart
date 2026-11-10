part of 'favorites_screen.dart';

abstract class _FavoritesController extends State<FavoritesScreen> {
  final SettingsService _settingsService = GetIt.I<SettingsService>();
  final HistoryService _historyService = GetIt.I<HistoryService>();
  final FavoritesService _favoritesService = GetIt.I<FavoritesService>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _favoritesService.loadFavorites();
    });
  }

  String _getHymnalName(String hymnalId) {
    final hymnal = _settingsService.hymnals.firstWhere(
      (h) => h.id == hymnalId,
      orElse: () => _settingsService.hymnals.first,
    );
    return hymnal.name;
  }

  Future<void> _onFavoriteTapped(FavoriteHymn favorite) async {
    await _historyService.addToHistory(
      favorite.hymnalId,
      favorite.hymnNumber,
      favorite.title,
    );
    if (mounted) {
      HymnOpener.open(
        context,
        hymnalId: favorite.hymnalId,
        hymnNumber: favorite.hymnNumber,
      );
    }
  }

  Future<bool?> _confirmDismiss(FavoriteHymn favorite) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeFavoriteTitle),
        content: Text(l10n.removeFavorite(favorite.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
  }

  void _onDismissed(FavoriteHymn favorite) {
    _favoritesService.removeFavorite(favorite.hymnalId, favorite.hymnNumber);
  }
}

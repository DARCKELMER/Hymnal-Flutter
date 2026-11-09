import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Últimas búsquedas del usuario (las más recientes primero), guardadas en
/// SharedPreferences. Se muestran con el campo de búsqueda vacío.
class RecentSearchesService extends ChangeNotifier {
  static const String _key = 'recentSearches';

  /// Cuántas se recuerdan.
  static const int limit = 8;

  List<String> _items = const [];
  bool _loaded = false;

  List<String> get items => _items;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _items = prefs.getStringList(_key) ?? const [];
    _loaded = true;
    notifyListeners();
  }

  /// Agrega [query] al principio (sin duplicados, sin distinguir
  /// mayúsculas).
  Future<void> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    await load();
    final lower = q.toLowerCase();
    _items = [
      q,
      ..._items.where((i) => i.toLowerCase() != lower),
    ].take(limit).toList();
    notifyListeners();
    await _save();
  }

  Future<void> remove(String query) async {
    await load();
    _items = _items.where((i) => i != query).toList();
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _items);
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un paisaje de fondo del catálogo (`assets/backgrounds/backgrounds.json`).
@immutable
class Background {
  const Background({
    required this.id,
    required this.names,
    required this.dark,
    this.author,
    this.site,
  });

  factory Background.fromJson(Map<String, dynamic> json) => Background(
    id: json['id'] as String,
    names: (json['name'] as Map<String, dynamic>).cast<String, String>(),
    dark: json['dark'] as bool? ?? false,
    author: json['author'] as String?,
    site: json['site'] as String?,
  );

  final String id;
  final Map<String, String> names;

  /// Foto oscura (de noche): el texto claro se lee mejor sobre ella.
  final bool dark;
  final String? author;
  final String? site;

  String get asset => 'assets/backgrounds/$id.webp';
  String get thumbAsset => 'assets/backgrounds/thumbs/$id.webp';
  ImageProvider get image => AssetImage(asset);
  ImageProvider get thumb => AssetImage(thumbAsset);

  /// Nombre en el idioma dado (o en inglés).
  String name(String languageCode) => names[languageCode] ?? names['en'] ?? id;

  /// Crédito de la foto ("Rafael Peier · Unsplash"), o `null`.
  String? get credit {
    final parts = [?author, ?site];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// Cada cuánto cambia el fondo en modo automático.
enum BackgroundFrequency { onOpen, perHymn, every5min }

/// Fondo de la app: el paisaje elegido y el cambio automático (al abrir,
/// con cada himno o cada 5 minutos), guardados en `SharedPreferences`.
class BackgroundService extends ChangeNotifier {
  static const String _keySelected = 'background_selected';
  static const String _keyAuto = 'background_auto';
  static const String _keyFrequency = 'background_frequency';
  static const Duration autoInterval = Duration(minutes: 5);

  List<Background> _backgrounds = const [];
  String? _defaultId;
  String? _selectedId;
  bool _autoChange = false;
  BackgroundFrequency _frequency = BackgroundFrequency.onOpen;
  Timer? _timer;
  bool _initialized = false;

  List<Background> get backgrounds => _backgrounds;
  bool get autoChange => _autoChange;
  BackgroundFrequency get frequency => _frequency;
  bool get isReady => _backgrounds.isNotEmpty;

  /// El fondo actual (`null` mientras no se carga el catálogo).
  Background? get current {
    if (_backgrounds.isEmpty) return null;
    for (final b in _backgrounds) {
      if (b.id == _selectedId) return b;
    }
    for (final b in _backgrounds) {
      if (b.id == _defaultId) return b;
    }
    return _backgrounds.first;
  }

  /// El que viene después del actual (para precargarlo).
  Background? get next {
    final now = current;
    if (now == null) return null;
    final i = _backgrounds.indexOf(now);
    return _backgrounds[(i + 1) % _backgrounds.length];
  }

  /// Lee el catálogo y las preferencias. En modo automático "al abrir",
  /// pasa al siguiente paisaje.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final raw = await rootBundle.loadString(
        'assets/backgrounds/backgrounds.json',
      );
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _defaultId = json['default'] as String?;
      _backgrounds = [
        for (final b in json['backgrounds'] as List<dynamic>)
          Background.fromJson(b as Map<String, dynamic>),
      ];
    } catch (e) {
      debugPrint('No se pudo leer el catálogo de fondos: $e');
      _backgrounds = const [];
    }
    final prefs = await SharedPreferences.getInstance();
    _selectedId = prefs.getString(_keySelected);
    _autoChange = prefs.getBool(_keyAuto) ?? false;
    _frequency = BackgroundFrequency.values.firstWhere(
      (f) => f.name == prefs.getString(_keyFrequency),
      orElse: () => BackgroundFrequency.onOpen,
    );
    if (_autoChange && _frequency == BackgroundFrequency.onOpen) {
      await showNext();
    }
    _restartTimer();
    notifyListeners();
  }

  /// Elige un paisaje (desde la galería).
  Future<void> select(String id) async {
    if (id == current?.id) return;
    _selectedId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelected, id);
  }

  /// Pasa al siguiente paisaje ("Cambiar paisaje" o el modo automático).
  Future<void> showNext() async {
    final upcoming = next;
    if (upcoming != null) await select(upcoming.id);
  }

  Future<void> setAutoChange(bool value) async {
    _autoChange = value;
    _restartTimer();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAuto, value);
  }

  Future<void> setFrequency(BackgroundFrequency value) async {
    _frequency = value;
    _restartTimer();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFrequency, value.name);
  }

  /// Se abrió un himno: en modo "cada himno", cambia el paisaje.
  void onHymnShown() {
    if (_autoChange && _frequency == BackgroundFrequency.perHymn) {
      showNext();
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = null;
    if (_autoChange && _frequency == BackgroundFrequency.every5min) {
      _timer = Timer.periodic(autoInterval, (_) => showNext());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

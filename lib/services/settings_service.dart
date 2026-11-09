import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/layers/data/repository/hymnal_repository.dart';
import 'package:hymnal_app/layers/data/repository/settings_repository.dart';
import 'package:hymnal_app/layers/domain/model/hymnal.dart';

class SettingsService extends ChangeNotifier {
  final HymnalRepository _hymnalRepository = GetIt.I<HymnalRepository>();
  final SettingsRepository _settingsRepository = GetIt.I<SettingsRepository>();

  List<Hymnal> _hymnals = [];
  Hymnal? _selectedHymnal;
  double _fontSize = 16.0;
  String _themeMode = 'system';
  bool _keepScreenOn = false;
  bool _showBackgroundImage = false;
  double _glassTint = SettingsRepository.defaultGlassTint;
  bool _isLoading = true;

  List<Hymnal> get hymnals => _hymnals;
  Hymnal? get selectedHymnal => _selectedHymnal;
  double get fontSize => _fontSize;
  String get themeMode => _themeMode;
  bool get keepScreenOn => _keepScreenOn;
  bool get showBackgroundImage => _showBackgroundImage;

  /// Tinte del cristal (ajuste "Cristal"), de 0 a 1.
  double get glassTint => _glassTint;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _hymnals = await _hymnalRepository.getHymnals();

    final savedHymnalId = await _settingsRepository.getSelectedHymnalId();
    if (savedHymnalId != null) {
      _selectedHymnal = _hymnals.firstWhere(
        (h) => h.id == savedHymnalId,
        orElse: () => _hymnals.first,
      );
    } else {
      // First launch: Auto-select based on language
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      final langCode = locale.languageCode;

      debugPrint('[SettingsService] First launch detected. Locale: $langCode');

      // Selection Rules: Auto-select first hymnbook matching the language code
      final match = _hymnals
          .where((h) => h.twoLetterIsoLanguageName == langCode)
          .firstOrNull;

      _selectedHymnal = _hymnals.firstWhere(
        (h) => h.id == match?.id,
        orElse: () => _hymnals.first,
      );

      debugPrint(
        '[SettingsService] Auto-selected hymnal: ${_selectedHymnal?.id}',
      );

      // Persist the auto-selected choice
      if (_selectedHymnal != null) {
        await _settingsRepository.setSelectedHymnalId(_selectedHymnal!.id);
      }
    }

    _fontSize = await _settingsRepository.getFontSize();
    _themeMode = await _settingsRepository.getThemeMode();
    _keepScreenOn = await _settingsRepository.getKeepScreenOn();
    _showBackgroundImage = await _settingsRepository.getShowBackgroundImage();
    _glassTint = await _settingsRepository.getGlassTint();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectHymnal(String hymnalId) async {
    _selectedHymnal = _hymnals.firstWhere((h) => h.id == hymnalId);
    await _settingsRepository.setSelectedHymnalId(hymnalId);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    await _settingsRepository.setFontSize(size);
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    await _settingsRepository.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setKeepScreenOn(bool value) async {
    _keepScreenOn = value;
    await _settingsRepository.setKeepScreenOn(value);
    notifyListeners();
  }

  Future<void> setShowBackgroundImage(bool value) async {
    _showBackgroundImage = value;
    await _settingsRepository.setShowBackgroundImage(value);
    notifyListeners();
  }

  Future<void> setGlassTint(double value) async {
    _glassTint = value.clamp(0.0, 1.0);
    // Se avisa antes de guardar para que el deslizador responda al instante.
    notifyListeners();
    await _settingsRepository.setGlassTint(_glassTint);
  }

  List<Hymnal> getHymnalsByLanguage(String languageCode) {
    return _hymnals
        .where((h) => h.twoLetterIsoLanguageName == languageCode)
        .toList();
  }
}

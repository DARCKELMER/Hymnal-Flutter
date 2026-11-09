import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const String _selectedHymnalKey = 'selectedHymnal';
  static const String _fontSizeKey = 'fontSize';
  static const String _themeModeKey = 'themeMode';
  static const String _keepScreenOnKey = 'keepScreenOn';
  static const String _showBackgroundImageKey = 'showBackgroundImage';
  static const String _glassTintKey = 'glassTint';

  /// Tinte del cristal por defecto: casi transparente.
  static const double defaultGlassTint = .1;

  Future<String?> getSelectedHymnalId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedHymnalKey);
  }

  Future<void> setSelectedHymnalId(String hymnalId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedHymnalKey, hymnalId);
  }

  Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 16.0;
  }

  Future<void> setFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, size);
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
  }

  Future<bool> getKeepScreenOn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keepScreenOnKey) ?? false;
  }

  Future<void> setKeepScreenOn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepScreenOnKey, value);
  }

  Future<bool> getShowBackgroundImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showBackgroundImageKey) ?? true;
  }

  Future<void> setShowBackgroundImage(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showBackgroundImageKey, value);
  }

  /// Tinte del cristal, de 0 (transparente) a 1 (tintado).
  Future<double> getGlassTint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_glassTintKey) ?? defaultGlassTint;
  }

  Future<void> setGlassTint(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_glassTintKey, value);
  }
}

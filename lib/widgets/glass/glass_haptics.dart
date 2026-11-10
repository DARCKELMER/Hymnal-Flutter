import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Vibraciones de las barras de cristal.
///
/// En celular: un "clic" suave al cruzar un destino y un toque ligero al
/// asentarse. En tableta (lado corto ≥ 600 dp) se usan vibraciones de tipo
/// tecla: muchas tabletas (p. ej. Galaxy Tab) tienen un motor básico que
/// ignora el clic suave, y la barra quedaba sin vibración.
abstract final class GlassHaptics {
  static bool _isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;

  /// Al cruzar o elegir un destino.
  static void tick(BuildContext context) {
    if (_isTablet(context)) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  /// Al asentarse la gota en un destino.
  static void settle(BuildContext context) {
    if (_isTablet(context)) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }
}

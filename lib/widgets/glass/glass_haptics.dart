import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Vibraciones de las barras de cristal.
///
/// En celular: las del sistema (un "clic" suave al cruzar un destino y un
/// toque ligero al asentarse). En tableta (lado corto ≥ 600 dp) van
/// **directo al motor** por un canal propio (ver `MainActivity.kt`): muchas
/// tabletas (p. ej. Galaxy Tab) ignoran la vibración táctil del sistema y
/// la barra quedaba sin vibrar.
abstract final class GlassHaptics {
  static const MethodChannel _channel = MethodChannel('hymnal/haptics');

  static bool _isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;

  static bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Al cruzar o elegir un destino.
  static void tick(BuildContext context) {
    if (_android && _isTablet(context)) {
      _motor('tick', HapticFeedback.lightImpact);
    } else {
      HapticFeedback.selectionClick();
    }
  }

  /// Al asentarse la gota en un destino.
  static void settle(BuildContext context) {
    if (_android && _isTablet(context)) {
      _motor('settle', HapticFeedback.mediumImpact);
    } else {
      HapticFeedback.lightImpact();
    }
  }

  /// Vibra con el motor; si el canal no existe (pruebas), la del sistema.
  static void _motor(String method, Future<void> Function() fallback) {
    _channel.invokeMethod<void>(method).catchError((Object _) => fallback());
  }
}

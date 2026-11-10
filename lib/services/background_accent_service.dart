import 'package:flutter/widgets.dart';
import 'package:hymnal_app/core/constants/app_assets.dart';
import 'package:hymnal_app/utils/vivid_color.dart';

/// Color más vivo del fondo de la app, ya ajustado para cristal con ícono
/// blanco (`dropColorFrom`). Lo usan el mini reproductor (agua de
/// progreso, teñido) y los controles activos.
///
/// Vale `null` hasta calcularse (en segundo plano); mientras tanto los
/// componentes usan el color de acento del tema. Al cambiar de paisaje se
/// recalcula; cada color calculado se guarda para no repetirlo.
class BackgroundAccentService extends ValueNotifier<Color?> {
  BackgroundAccentService() : super(null);

  final Map<String, Color> _cache = {};
  String? _pending;

  /// Calcula el color de [image] (identificado por [key]). Si llega otro
  /// pedido mientras calcula, gana el último.
  Future<void> load({
    ImageProvider image = const AssetImage(AppAssets.backgroundImage),
    String key = AppAssets.backgroundImage,
  }) async {
    final cached = _cache[key];
    if (cached != null) {
      _pending = key;
      value = cached;
      return;
    }
    _pending = key;
    final vivid = await vividColorFromImage(image);
    if (vivid == null) return;
    final color = dropColorFrom(vivid);
    _cache[key] = color;
    if (_pending == key) value = color;
  }
}

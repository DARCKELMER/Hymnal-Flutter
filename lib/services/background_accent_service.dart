import 'package:flutter/widgets.dart';
import 'package:hymnal_app/core/constants/app_assets.dart';
import 'package:hymnal_app/utils/vivid_color.dart';

/// Color más vivo del fondo de la app, ya ajustado para cristal con ícono
/// blanco (`dropColorFrom`). Lo usan el mini reproductor (agua de
/// progreso, teñido) y los controles activos.
///
/// Vale `null` hasta calcularse (una vez, en segundo plano al arrancar);
/// mientras tanto los componentes usan el color de acento del tema.
class BackgroundAccentService extends ValueNotifier<Color?> {
  BackgroundAccentService() : super(null);

  bool _loading = false;

  /// Calcula el color del fondo actual. Seguro de llamar varias veces.
  Future<void> load({
    ImageProvider image = const AssetImage(AppAssets.backgroundImage),
  }) async {
    if (_loading || value != null) return;
    _loading = true;
    try {
      final vivid = await vividColorFromImage(image);
      if (vivid != null) value = dropColorFrom(vivid);
    } finally {
      _loading = false;
    }
  }
}

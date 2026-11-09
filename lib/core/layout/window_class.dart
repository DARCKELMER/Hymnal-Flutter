import 'package:flutter/widgets.dart';

/// Clase de ventana según el **ancho disponible** (no el del dispositivo),
/// así la pantalla dividida se resuelve sola:
///
/// | Clase      | Condición                          | Navegación       |
/// |------------|------------------------------------|------------------|
/// | compacta   | ancho < 600                        | barra inferior   |
/// | mediana    | 600 ≤ ancho < 840, o alto < 600    | barra lateral    |
/// | expandida  | ancho ≥ 840 y alto ≥ 600           | lateral + detalle|
enum WindowClass {
  compact,
  medium,
  expanded;

  static WindowClass fromSize(Size size) {
    if (size.width < 600) return compact;
    if (size.width >= 840 && size.height >= 600) return expanded;
    return medium;
  }

  /// Usa la barra lateral en vez de la inferior.
  bool get usesRail => this != compact;

  /// Muestra la lista y el himno a la vez.
  bool get showsDetail => this == expanded;

  /// Ancho máximo del contenido en una columna (mediana).
  static const double mediumContentWidth = 600;

  /// Ancho de la lista en la vista expandida.
  static const double listWidth = 380;

  /// Ancho máximo del himno (y del mini reproductor) en la vista expandida.
  static const double detailMaxWidth = 640;
}

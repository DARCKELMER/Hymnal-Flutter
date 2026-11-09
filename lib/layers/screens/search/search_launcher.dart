import 'package:flutter/widgets.dart';

/// Permite a las pantallas de pestañas (p. ej. el botón "Buscar" de Inicio)
/// abrir la búsqueda integrada en la barra de cristal.
class SearchLauncher extends InheritedWidget {
  const SearchLauncher({required this.open, required super.child, super.key});

  final VoidCallback open;

  /// La acción de abrir la búsqueda, o `null` fuera de la pantalla
  /// principal.
  static VoidCallback? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SearchLauncher>()?.open;

  @override
  bool updateShouldNotify(SearchLauncher oldWidget) => open != oldWidget.open;
}

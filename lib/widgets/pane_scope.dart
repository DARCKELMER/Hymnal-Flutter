import 'package:flutter/widgets.dart';

/// Marca una pantalla como **incrustada en un panel** (p. ej. el himno a la
/// derecha en tableta, o el Historial en la barra lateral): `AppScaffold`
/// no dibuja el fondo ni la zona de cristal inferior, porque ya los pone la
/// pantalla principal.
class PaneScope extends InheritedWidget {
  const PaneScope({required super.child, super.key});

  static bool isEmbedded(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PaneScope>() != null;

  @override
  bool updateShouldNotify(PaneScope oldWidget) => false;
}

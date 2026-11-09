import 'package:flutter/material.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_screen.dart';

/// Abre un himno desde cualquier lista.
typedef OpenHymn =
    void Function(String hymnalId, int hymnNumber, {bool skipHistory});

/// Punto único para abrir un himno. En la vista expandida (tableta) la
/// pantalla principal lo pone a la derecha **sin navegar**; en las demás se
/// abre como pantalla normal.
class HymnOpener extends InheritedWidget {
  const HymnOpener({required this.onOpen, required super.child, super.key});

  final OpenHymn? onOpen;

  static void open(
    BuildContext context, {
    required String hymnalId,
    required int hymnNumber,
    bool skipHistory = false,
  }) {
    final onOpen = context.getInheritedWidgetOfExactType<HymnOpener>()?.onOpen;
    if (onOpen != null) {
      onOpen(hymnalId, hymnNumber, skipHistory: skipHistory);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/hymn'),
        builder: (_) => HymnScreen(
          hymnalId: hymnalId,
          hymnNumber: hymnNumber,
          skipHistory: skipHistory,
        ),
      ),
    );
  }

  @override
  bool updateShouldNotify(HymnOpener oldWidget) => onOpen != oldWidget.onOpen;
}

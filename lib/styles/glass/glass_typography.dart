import 'package:flutter/material.dart';

/// Distribución de pantalla que cambia los tamaños de la letra del himno.
enum HymnLayout { phone, tabletLandscape, tabletPortrait }

/// Tipografía del rediseño (fuentes empaquetadas, ver `pubspec.yaml`):
///
/// - **Inter** para la interfaz.
/// - **Literata** para el contenido del himno.
///
/// El tamaño de letra que el usuario elige en Ajustes escala solo la letra
/// del himno ([lyrics]), no la interfaz.
abstract final class GlassTypography {
  static const String ui = 'Inter';
  static const String content = 'Literata';

  /// Tamaño de letra por defecto en Ajustes; el elegido / este = escala.
  static const double defaultUserFontSize = 16;

  /// Título de pantalla: 34/700 con −2 % de interletra.
  static TextStyle screenTitle(Color color) => TextStyle(
    fontFamily: ui,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 34 * -.02,
    color: color,
  );

  /// Fila de lista: 16/500 (600 si está seleccionada).
  static TextStyle listRow(Color color, {bool selected = false}) => TextStyle(
    fontFamily: ui,
    fontSize: 16,
    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
    color: color,
  );

  /// Etiqueta de sección: 13/700. El texto va en mayúsculas: usa
  /// [sectionText].
  static TextStyle sectionLabel(Color color) => TextStyle(
    fontFamily: ui,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: .4,
    color: color,
  );

  /// Texto de una etiqueta de sección, en mayúsculas.
  static String sectionText(String text) => text.toUpperCase();

  /// Etiqueta de pestaña: 11.
  static TextStyle tabLabel(Color color, {bool selected = false}) => TextStyle(
    fontFamily: ui,
    fontSize: 11,
    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
    color: color,
  );

  /// Título del himno: 28/600 en celular, 30 en tableta horizontal y 34 en
  /// tableta vertical.
  static TextStyle hymnTitle(HymnLayout layout, Color color) => TextStyle(
    fontFamily: content,
    fontSize: switch (layout) {
      HymnLayout.phone => 28,
      HymnLayout.tabletLandscape => 30,
      HymnLayout.tabletPortrait => 34,
    },
    fontWeight: FontWeight.w600,
    color: color,
  );

  /// Letra del himno: 19/1.6 en celular, 18/1.55 en tableta horizontal y
  /// 22/1.6 en tableta vertical, multiplicada por la escala del usuario.
  static TextStyle lyrics(
    HymnLayout layout,
    Color color, {
    double userFontSize = defaultUserFontSize,
  }) {
    final (size, height) = switch (layout) {
      HymnLayout.phone => (19.0, 1.6),
      HymnLayout.tabletLandscape => (18.0, 1.55),
      HymnLayout.tabletPortrait => (22.0, 1.6),
    };
    return TextStyle(
      fontFamily: content,
      fontSize: size * userFontSize / defaultUserFontSize,
      height: height,
      color: color,
    );
  }
}

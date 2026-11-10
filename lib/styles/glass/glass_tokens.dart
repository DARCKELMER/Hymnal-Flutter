import 'package:flutter/material.dart';

/// Colores del rediseño Liquid Glass para el tema claro y el oscuro.
///
/// Se registran como extensión del tema (`ThemeData.extensions`), así que
/// cambian solos con el modo claro/oscuro: `GlassTokens.of(context)`.
@immutable
class GlassTokens extends ThemeExtension<GlassTokens> {
  const GlassTokens({
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.buttonTint,
    required this.favorite,
    required this.selected,
    required this.vivid,
  });

  /// Texto principal.
  final Color textPrimary;

  /// Texto secundario.
  final Color textSecondary;

  /// Texto e íconos activos.
  final Color accent;

  /// Tinte de los botones principales (cristal tintado).
  final Color buttonTint;

  /// Favorito activo.
  final Color favorite;

  /// Pestaña u opción seleccionada.
  final Color selected;

  /// Acento **vivo** para lo que está bajo la gota de agua de las barras
  /// (el azul del laboratorio): en tema oscuro, un azul brillante en vez del
  /// lila pálido de [accent], para que la gota no se vea apagada.
  final Color vivid;

  static const light = GlassTokens(
    textPrimary: Color(0xFF0E1A2B),
    textSecondary: Color(0xFF26344A),
    accent: Color(0xFF1F4FD1),
    buttonTint: Color(0xD61F4FD1), // 84 %
    favorite: Color(0xFFC2410C),
    selected: Color(0x94FFFFFF), // blanco al 58 %
    vivid: Color(0xFF1F4FD1),
  );

  static const dark = GlassTokens(
    textPrimary: Color(0xFFF2F5FA),
    textSecondary: Color(0xFFC5CEDD),
    accent: Color(0xFFA9C1FF),
    buttonTint: Color(0xD14A72EC), // 82 %
    favorite: Color(0xFFFDBA74),
    selected: Color(0x29FFFFFF), // blanco al 16 %
    vivid: Color(0xFF6B8EFF),
  );

  /// Tokens del tema actual (claros si el tema no los registró).
  static GlassTokens of(BuildContext context) =>
      Theme.of(context).extension<GlassTokens>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  GlassTokens copyWith({
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? buttonTint,
    Color? favorite,
    Color? selected,
    Color? vivid,
  }) {
    return GlassTokens(
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      buttonTint: buttonTint ?? this.buttonTint,
      favorite: favorite ?? this.favorite,
      selected: selected ?? this.selected,
      vivid: vivid ?? this.vivid,
    );
  }

  @override
  GlassTokens lerp(GlassTokens? other, double t) {
    if (other == null) return this;
    return GlassTokens(
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      buttonTint: Color.lerp(buttonTint, other.buttonTint, t)!,
      favorite: Color.lerp(favorite, other.favorite, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      vivid: Color.lerp(vivid, other.vivid, t)!,
    );
  }
}

/// Medidas del rediseño: radios, márgenes, separaciones y áreas táctiles.
abstract final class GlassMetrics {
  /// Radio de una cápsula: la mitad de su altura.
  static double capsuleRadius(double height) => height / 2;

  static const double cardRadius = 28;
  static const double lyricsCardRadius = 32;
  static const double lyricsCardRadiusTablet = 34;
  static const double thumbnailRadius = 18;

  static const double screenMarginPhone = 20;
  static const double screenMarginTablet = 24;

  static const double gapXs = 10;
  static const double gapS = 12;
  static const double gapM = 14;
  static const double gapL = 16;

  /// Área táctil mínima.
  static const double minTouchTarget = 48;

  /// Botón circular suelto y botón dentro de una barra.
  static const double iconButton = 48;
  static const double barButton = 64;

  /// Alto de la barra de pestañas y del mini reproductor.
  static const double tabBarHeight = 64;
  static const double miniPlayerHeight = 60;

  /// Ancho de la barra lateral en tableta: el mismo grosor que la barra
  /// de pestañas del celular (es la misma barra, girada).
  static const double navigationRailWidth = 64;
}

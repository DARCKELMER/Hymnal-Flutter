import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Cristal "agua brillante": parte del preset Clear de iOS 27 con un bisel
/// más ancho y profundo (más refracción en el borde) y un reflejo especular
/// más intenso, para que se vea como agua sobre el fondo en vez de mate.
///
/// [tintAmount] va de 0 (transparente) a 1 (tintado).
LiquidGlassSettings waterGlassSettings(double tintAmount) =>
    LiquidGlassSettings.ios27Clear(tintAmount: tintAmount).copyWith(
      refractionHeight: 26,
      refractionAmount: 72,
      highlight: 0.9,
      contourStrength: 0.45,
    );

/// Tinte mínimo de la tarjeta de letra: la letra debe leerse sobre
/// cualquier paisaje, sin importar el ajuste "Cristal" del usuario.
const double lyricsMinTint = .85;

/// Cristal de la tarjeta de letra: siempre muy tintado.
LiquidGlassSettings lyricsGlassSettings(double tintAmount) =>
    waterGlassSettings(tintAmount < lyricsMinTint ? lyricsMinTint : tintAmount);

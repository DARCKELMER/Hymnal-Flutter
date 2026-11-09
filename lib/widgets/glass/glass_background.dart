import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/core/constants/app_assets.dart';
import 'package:hymnal_app/services/background_accent_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Fondo general de la app, pensado para que el cristal tenga algo que
/// refractar:
///
/// - Con [showImage]: el paisaje a pantalla completa y un **velo** en
///   degradado detrás del texto (claro en tema claro; azul noche en tema
///   oscuro, como de noche). Más denso arriba, donde están los títulos y
///   las listas, y más suave abajo, donde flota el cristal.
/// - Sin imagen: un degradado suave con el color vivo del paisaje (en vez
///   de un color liso).
class GlassBackground extends StatelessWidget {
  const GlassBackground({required this.showImage, super.key});

  final bool showImage;

  /// Velo sobre el paisaje (de arriba hacia abajo) según el brillo.
  static List<Color> veil(Brightness brightness) =>
      brightness == Brightness.dark
      ? const [Color(0xA60B1220), Color(0x800B1220), Color(0x660B1220)]
      : const [Color(0x73FFFFFF), Color(0x4DFFFFFF), Color(0x33FFFFFF)];

  /// Degradado sin imagen a partir del color vivo del paisaje.
  static List<Color> plainGradient(Color seed, Brightness brightness) {
    final hct = Hct.fromInt(seed.toARGB32());
    Color tone(double t, double chroma) =>
        Color(Hct.from(hct.hue, chroma, t).toInt());
    return brightness == Brightness.dark
        ? [tone(18, 24), tone(8, 12)]
        : [tone(95, 18), tone(86, 30)];
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (showImage) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.backgroundImage, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: veil(brightness),
              ),
            ),
          ),
        ],
      );
    }
    final accent = GetIt.I.isRegistered<BackgroundAccentService>()
        ? GetIt.I<BackgroundAccentService>()
        : null;
    final fallback = GlassTokens.of(context).accent;
    return ListenableBuilder(
      listenable: accent ?? ValueNotifier<Color?>(null),
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: plainGradient(accent?.value ?? fallback, brightness),
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

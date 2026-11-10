import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/core/constants/app_assets.dart';
import 'package:hymnal_app/services/background_accent_service.dart';
import 'package:hymnal_app/services/background_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Fondo general de la app, pensado para que el cristal tenga algo que
/// refractar:
///
/// - Con [showImage]: el paisaje elegido (`BackgroundService`) a pantalla
///   completa; al cambiar, se funde en 1,2 s con un leve zoom de 1.03 a
///   1.0. Encima, un **velo** en
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

  /// Duración del cambio de paisaje.
  static const Duration transition = Duration(milliseconds: 1200);

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
          const _Landscape(),
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

/// El paisaje actual, con fundido y zoom suave al cambiar.
class _Landscape extends StatefulWidget {
  const _Landscape();

  @override
  State<_Landscape> createState() => _LandscapeState();
}

class _LandscapeState extends State<_Landscape> {
  BackgroundService? get _service => GetIt.I.isRegistered<BackgroundService>()
      ? GetIt.I<BackgroundService>()
      : null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheNext();
  }

  /// Precarga el siguiente paisaje para que el cambio no espere.
  void _precacheNext() {
    final next = _service?.next;
    if (next != null) precacheImage(next.image, context).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    return ListenableBuilder(
      listenable: service ?? ChangeNotifier(),
      builder: (context, _) {
        final background = service?.current;
        final image =
            background?.image ?? const AssetImage(AppAssets.backgroundImage);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _precacheNext();
        });
        return AnimatedSwitcher(
          duration: GlassBackground.transition,
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          layoutBuilder: (current, previous) =>
              Stack(fit: StackFit.expand, children: [...previous, ?current]),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.03, end: 1).animate(animation),
              child: child,
            ),
          ),
          child: Image(
            key: ValueKey(background?.id),
            image: image,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        );
      },
    );
  }
}

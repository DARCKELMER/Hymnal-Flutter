import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/core/constants/app_assets.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/widgets/glass/glass_dock.dart';
import 'package:hymnal_app/widgets/glass/glass_tab_bar.dart';

/// Estructura común de las pantallas: fondo, contenido y, abajo, la zona
/// de cristal ([GlassDock]) con el mini reproductor y la barra de
/// pestañas ([tabBar]).
///
/// La zona de cristal va dentro del cuerpo, así queda siempre justo encima
/// de [bottomNavigationBar] (p. ej. los botones de audio del himno) o del
/// borde inferior seguro. El contenido reserva su alto para no quedar
/// debajo.
class AppScaffold extends StatefulWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;

  /// Barra inferior normal (sin cristal), debajo de la zona de cristal.
  final Widget? bottomNavigationBar;

  /// Barra de pestañas de cristal (pantalla principal).
  final GlassTabBar? tabBar;
  final bool showPlayer;
  final bool resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.tabBar,
    this.showPlayer = true,
    this.resizeToAvoidBottomInset = true,
  });

  /// Margen entre la zona de cristal y el borde inferior.
  static const double dockMargin = 12;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  @override
  Widget build(BuildContext context) {
    final settingsService = GetIt.I<SettingsService>();
    final audioService = GetIt.I<AudioService>();

    return AnimatedBuilder(
      animation: Listenable.merge([settingsService, audioService]),
      builder: (context, child) {
        final theme = Theme.of(context);
        final hasPlayer = widget.showPlayer && audioService.currentHymn != null;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value:
              theme.appBarTheme.systemOverlayStyle ??
              (theme.brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark),
          child: Stack(
            children: [
              Container(color: Theme.of(context).scaffoldBackgroundColor),
              if (settingsService.showBackgroundImage)
                Positioned.fill(
                  child: Image.asset(
                    AppAssets.backgroundImage,
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.15),
                  ),
                ),
              Scaffold(
                backgroundColor: Colors.transparent,
                appBar: widget.appBar,
                body: _DockedBody(
                  hasTabBar: widget.tabBar != null,
                  hasPlayer: hasPlayer,
                  dock: widget.tabBar == null && !widget.showPlayer
                      ? null
                      : GlassDock(
                          tabBar: widget.tabBar,
                          showPlayer: widget.showPlayer,
                        ),
                  child: widget.body,
                ),
                bottomNavigationBar: widget.bottomNavigationBar,
                resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Contenido con la zona de cristal flotando abajo.
class _DockedBody extends StatelessWidget {
  const _DockedBody({
    required this.child,
    required this.dock,
    required this.hasTabBar,
    required this.hasPlayer,
  });

  final Widget child;
  final Widget? dock;
  final bool hasTabBar;
  final bool hasPlayer;

  @override
  Widget build(BuildContext context) {
    final dock = this.dock;
    if (dock == null) return child;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final reserved = GlassDock.reservedHeight(
      hasTabBar: hasTabBar,
      hasPlayer: hasPlayer,
    );
    // Con el teclado abierto la zona de cristal se aparta hacia abajo
    // (sin desmontarse, para no volver a crear el cristal).
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Stack(
      children: [
        Positioned.fill(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: reserved > 0,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: reserved > 0
                    ? reserved + AppScaffold.dockMargin + safeBottom
                    : 0,
              ),
              child: child,
            ),
          ),
        ),
        Positioned(
          left: GlassMetrics.screenMarginPhone,
          right: GlassMetrics.screenMarginPhone,
          bottom: AppScaffold.dockMargin + safeBottom,
          child: AnimatedSlide(
            offset: keyboardOpen ? const Offset(0, 2) : Offset.zero,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: IgnorePointer(ignoring: keyboardOpen, child: dock),
          ),
        ),
      ],
    );
  }
}

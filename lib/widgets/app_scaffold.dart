import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/widgets/glass/glass_background.dart';
import 'package:hymnal_app/widgets/glass/glass_dock.dart';
import 'package:hymnal_app/widgets/glass/glass_tab_bar.dart';
import 'package:hymnal_app/widgets/pane_scope.dart';

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

  /// Barra de cristal bajo el mini reproductor (pantalla principal): la
  /// de pestañas o, en tableta, la de búsqueda.
  final Widget? tabBar;

  /// Alto que ocupa [tabBar] en reposo (0 si se pliega, como la búsqueda
  /// de tableta).
  final double tabBarHeight;

  /// Márgenes laterales de la zona de cristal (p. ej. para centrarla sobre
  /// el área del himno en tableta) y su ancho máximo.
  final EdgeInsets? dockInsets;
  final double? dockMaxWidth;
  final bool showPlayer;
  final bool resizeToAvoidBottomInset;

  /// Con el teclado abierto, la zona de cristal sube sobre él en vez de
  /// apartarse (p. ej. mientras se escribe en la búsqueda de la barra).
  final bool dockAboveKeyboard;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.tabBar,
    this.tabBarHeight = GlassTabBar.height,
    this.dockInsets,
    this.dockMaxWidth,
    this.showPlayer = true,
    this.resizeToAvoidBottomInset = true,
    this.dockAboveKeyboard = false,
  });

  /// Margen entre la zona de cristal y el borde inferior.
  static const double dockMargin = 12;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  @override
  Widget build(BuildContext context) {
    // Incrustada en un panel: la pantalla principal ya pone el fondo y la
    // zona de cristal.
    if (PaneScope.isEmbedded(context)) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: widget.appBar,
        body: widget.body,
        bottomNavigationBar: widget.bottomNavigationBar,
        resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      );
    }
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
              Positioned.fill(
                child: GlassBackground(
                  showImage: settingsService.showBackgroundImage,
                ),
              ),
              Scaffold(
                backgroundColor: Colors.transparent,
                appBar: widget.appBar,
                body: _DockedBody(
                  tabBarHeight: widget.tabBar == null ? 0 : widget.tabBarHeight,
                  insets: widget.dockInsets,
                  maxWidth: widget.dockMaxWidth,
                  hasPlayer: hasPlayer,
                  dockAboveKeyboard: widget.dockAboveKeyboard,
                  dock: widget.tabBar == null && !widget.showPlayer
                      ? null
                      : GlassDock(
                          tabBar: widget.tabBar,
                          tabBarHeight: widget.tabBarHeight,
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
    required this.tabBarHeight,
    required this.hasPlayer,
    required this.dockAboveKeyboard,
    this.insets,
    this.maxWidth,
  });

  final Widget child;
  final Widget? dock;
  final double tabBarHeight;
  final bool hasPlayer;
  final EdgeInsets? insets;
  final double? maxWidth;
  final bool dockAboveKeyboard;

  @override
  Widget build(BuildContext context) {
    final dock = this.dock;
    if (dock == null) return child;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final reserved = GlassDock.reservedHeight(
      tabBarHeight: tabBarHeight,
      hasPlayer: hasPlayer,
    );
    final insets =
        this.insets ??
        const EdgeInsets.symmetric(horizontal: GlassMetrics.screenMarginPhone);
    final maxWidth = this.maxWidth;
    // Con el teclado abierto la zona de cristal se aparta hacia abajo
    // (sin desmontarse, para no volver a crear el cristal).
    final keyboardOpen =
        MediaQuery.viewInsetsOf(context).bottom > 0 && !dockAboveKeyboard;
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
          left: insets.left,
          right: insets.right,
          bottom: AppScaffold.dockMargin + safeBottom,
          child: AnimatedSlide(
            offset: keyboardOpen ? const Offset(0, 2) : Offset.zero,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: IgnorePointer(
              ignoring: keyboardOpen,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth ?? double.infinity,
                  ),
                  child: dock,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

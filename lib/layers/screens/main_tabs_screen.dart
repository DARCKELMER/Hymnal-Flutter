import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/core/layout/window_class.dart';
import 'package:hymnal_app/layers/domain/model/hymn.dart';
import 'package:hymnal_app/layers/screens/home/home_screen.dart';
import 'package:hymnal_app/layers/screens/history/history_screen.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_opener.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_screen.dart';
import 'package:hymnal_app/layers/screens/lists/lists_screen.dart';
import 'package:hymnal_app/layers/screens/favorites/favorites_screen.dart';
import 'package:hymnal_app/layers/screens/search/search_launcher.dart';
import 'package:hymnal_app/layers/screens/search/search_panel.dart';
import 'package:hymnal_app/layers/screens/settings/settings_screen.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
import 'package:hymnal_app/widgets/app_scaffold.dart';
import 'package:hymnal_app/widgets/glass/glass_icon_button.dart';
import 'package:hymnal_app/widgets/glass/glass_navigation_rail.dart';
import 'package:hymnal_app/widgets/glass/glass_tab_bar.dart';
import 'package:hymnal_app/widgets/glass/glass_zone.dart';
import 'package:hymnal_app/widgets/glass/loupe_tab_bar/loupe_tab_bar.dart';
import 'package:hymnal_app/widgets/pane_scope.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';

part 'main_tabs_controller.dart';

/// Pantalla principal, adaptable según el ancho de la ventana
/// ([WindowClass]):
///
/// - **Compacta** (celular, pantalla dividida): barra de pestañas de
///   cristal abajo; la lupa se transforma en el buscador.
/// - **Mediana**: barra lateral de cristal y el contenido en una columna
///   centrada (máx. 600 dp).
/// - **Expandida**: barra lateral, lista (380 dp) y el himno a la derecha
///   (máx. 640 dp) **sin navegar**.
class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({super.key});

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends _MainTabsController {
  /// Ancho que ocupa la barra lateral con sus márgenes.
  static const double _railColumnWidth =
      GlassMetrics.navigationRailWidth + GlassMetrics.gapS * 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final windowClass = WindowClass.fromSize(MediaQuery.sizeOf(context));
    _onWindowClass(windowClass);

    final search = GlassTabSearch(
      controller: _searchController,
      focusNode: _searchFocus,
      open: _searchOpen,
      onOpen: _openSearch,
      onClose: _closeSearch,
      hint: l10n.searchHint,
      cancelLabel: l10n.cancel,
    );

    final Widget scaffold;
    if (!windowClass.usesRail) {
      scaffold = AppScaffold(
        resizeToAvoidBottomInset: true,
        // Mientras se busca, el campo (en la barra) sube sobre el teclado.
        dockAboveKeyboard: _searchOpen,
        body: _contentWithSearch(),
        // Barra de pestañas de cristal con la gota de agua; la lupa se
        // transforma en el campo de búsqueda.
        tabBar: GlassTabBar(
          tabs: [
            BottomBarTab(icon: Icons.home_rounded, label: l10n.home),
            BottomBarTab(
              icon: Icons.format_list_bulleted_rounded,
              label: l10n.lists,
            ),
            BottomBarTab(icon: Icons.favorite_rounded, label: l10n.favorites),
            BottomBarTab(icon: Icons.settings_rounded, label: l10n.settings),
          ],
          selectedIndex: math.max(
            0,
            _MainTabsController._compactTabs.indexOf(_dest),
          ),
          onSelected: (i) => _select(_MainTabsController._compactTabs[i]),
          searchLabel: l10n.search,
          search: search,
        ),
      );
    } else {
      final expanded = windowClass.showsDetail;
      // La zona de cristal inferior (reproductor y búsqueda) va centrada
      // sobre el contenido: el himno en expandida, la columna en mediana.
      final contentLeft =
          _railColumnWidth + (expanded ? WindowClass.listWidth : 0);
      scaffold = AppScaffold(
        resizeToAvoidBottomInset: true,
        dockAboveKeyboard: _searchOpen,
        tabBar: GlassTabBar(
          tabs: const [],
          selectedIndex: 0,
          onSelected: (_) {},
          searchLabel: l10n.search,
          search: search,
        ),
        tabBarHeight: 0,
        dockInsets: EdgeInsets.only(
          left: contentLeft + GlassMetrics.screenMarginTablet,
          right: GlassMetrics.screenMarginTablet,
        ),
        dockMaxWidth: WindowClass.detailMaxWidth,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _railColumn(context, l10n),
            if (expanded) ...[
              SizedBox(width: WindowClass.listWidth, child: _listPane()),
              Expanded(child: _detailPane(l10n)),
            ] else
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: WindowClass.mediumContentWidth,
                    ),
                    child: _contentWithSearch(),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return PopScope(
      // Atrás con la búsqueda abierta: la cierra en vez de salir.
      canPop: !_searchOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSearch();
      },
      child: SearchLauncher(
        open: _openSearch,
        child: HymnOpener(
          onOpen: windowClass.showsDetail ? _openInDetail : null,
          child: scaffold,
        ),
      ),
    );
  }

  /// Las pantallas de los destinos (con su estado conservado) y, encima,
  /// los resultados de la búsqueda.
  Widget _contentWithSearch() {
    return Stack(
      children: [
        IndexedStack(
          index: _Dest.values.indexOf(_dest),
          children: [for (final d in _Dest.values) _screen(d)],
        ),
        if (_searchPanelMounted)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_searchOpen,
              child: AnimatedOpacity(
                opacity: _searchOpen ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                onEnd: () {
                  if (!_searchOpen && mounted) {
                    setState(() => _searchPanelMounted = false);
                  }
                },
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      GlassMetrics.screenMarginPhone,
                      8,
                      GlassMetrics.screenMarginPhone,
                      0,
                    ),
                    child: SearchPanel(
                      controller: _searchController,
                      onOpenHymn: _openHymnFromSearch,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _screen(_Dest dest) {
    return KeyedSubtree(
      key: _screenKeys[dest],
      child: switch (dest) {
        _Dest.home => const HomeScreen(),
        _Dest.lists => const ListsScreen(),
        _Dest.favorites => const FavoritesScreen(),
        // El Historial se abre como pantalla; aquí va incrustado.
        _Dest.history => const PaneScope(child: HistoryScreen()),
        _Dest.settings => const SettingsScreen(),
      },
    );
  }

  /// Barra lateral: insignia del himnario, destinos y, al fondo, Buscar.
  Widget _railColumn(BuildContext context, AppLocalizations l10n) {
    final padding = MediaQuery.paddingOf(context);
    final available =
        MediaQuery.sizeOf(context).height -
        padding.vertical -
        GlassMetrics.gapS * 2;
    const search = GlassMetrics.barButton + GlassMetrics.gapL;
    const destinations = 5;
    // Con poca altura (celular girado) los destinos se compactan y, si aún
    // no alcanza, se omite la insignia.
    var withHeader = true;
    var itemHeight =
        (available - search - GlassNavigationRail.headerHeight - 12) /
        destinations;
    if (itemHeight < 48) {
      withHeader = false;
      itemHeight = (available - search - 12) / destinations;
    }
    itemHeight = itemHeight.clamp(44.0, GlassNavigationRail.defaultItemHeight);

    return SafeArea(
      right: false,
      child: Padding(
        padding: const EdgeInsets.all(GlassMetrics.gapS),
        child: GlassZone(
          child: Column(
            children: [
              GlassNavigationRail(
                header: withHeader ? const _HymnalBadge() : null,
                itemHeight: itemHeight,
                destinations: [
                  GlassRailDestination(
                    icon: Icons.home_rounded,
                    label: l10n.home,
                  ),
                  GlassRailDestination(
                    icon: Icons.format_list_bulleted_rounded,
                    label: l10n.lists,
                  ),
                  GlassRailDestination(
                    icon: Icons.favorite_rounded,
                    label: l10n.favorites,
                  ),
                  GlassRailDestination(
                    icon: Icons.history_rounded,
                    label: l10n.history,
                  ),
                  GlassRailDestination(
                    icon: Icons.settings_rounded,
                    label: l10n.settings,
                  ),
                ],
                selectedIndex: _Dest.values.indexOf(_dest),
                onSelected: (i) => _select(_Dest.values[i]),
              ),
              const Spacer(),
              GlassIconButton(
                icon: Icons.search_rounded,
                semanticLabel: l10n.search,
                onPressed: _searchOpen ? _closeSearch : _openSearch,
                bar: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Columna de la lista con su propia pila de navegación: lo que se abre
  /// desde la lista (p. ej. una categoría temática) se queda en la columna.
  Widget _listPane() {
    return PaneScope(
      child: _ListPaneScope(
        content: _contentWithSearch(),
        child: NavigatorPopHandler<Object?>(
          onPopWithResult: (_) => _listNavigatorKey.currentState?.maybePop(),
          child: Navigator(
            key: _listNavigatorKey,
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (context) => _ListPaneScope.contentOf(context),
            ),
          ),
        ),
      ),
    );
  }

  /// El himno elegido, a la derecha (máx. 640 dp), sin navegar.
  Widget _detailPane(AppLocalizations l10n) {
    final tokens = GlassTokens.of(context);
    return ValueListenableBuilder<_SelectedHymn?>(
      valueListenable: _selectedHymn,
      builder: (context, selected, _) {
        if (selected == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.library_music_rounded,
                  size: 48,
                  color: tokens.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.selectHymnPrompt,
                  style: GlassTypography.listRow(tokens.textSecondary),
                ),
              ],
            ),
          );
        }
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: WindowClass.detailMaxWidth,
            ),
            child: PaneScope(
              child: HymnScreen(
                key: ValueKey('${selected.hymnalId}#${selected.number}'),
                hymnalId: selected.hymnalId,
                hymnNumber: selected.number,
                skipHistory: selected.skipHistory,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Lleva el contenido de la columna de la lista a la ruta inicial de su
/// [Navigator] (las rutas se construyen una vez; este widget heredado las
/// actualiza cuando cambia el contenido).
class _ListPaneScope extends InheritedWidget {
  const _ListPaneScope({required this.content, required super.child});

  final Widget content;

  static Widget contentOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ListPaneScope>()!.content;

  @override
  bool updateShouldNotify(_ListPaneScope oldWidget) => true;
}

/// Insignia del himnario elegido (p. ej. "ES") arriba de la barra lateral.
class _HymnalBadge extends StatelessWidget {
  const _HymnalBadge();

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final settings = GetIt.I<SettingsService>();
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final hymnal = settings.selectedHymnal;
        final code = (hymnal?.twoLetterIsoLanguageName ?? '').toUpperCase();
        return Semantics(
          label: hymnal?.name,
          excludeSemantics: true,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tokens.selected,
              border: Border.all(color: const Color(0x47FFFFFF)),
            ),
            child: Text(
              code,
              style: TextStyle(
                fontFamily: GlassTypography.ui,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: tokens.accent,
              ),
            ),
          ),
        );
      },
    );
  }
}

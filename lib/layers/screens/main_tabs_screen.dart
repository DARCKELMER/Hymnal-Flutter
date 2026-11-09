import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/layers/domain/model/hymn.dart';
import 'package:hymnal_app/layers/screens/home/home_screen.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_screen.dart';
import 'package:hymnal_app/layers/screens/lists/lists_screen.dart';
import 'package:hymnal_app/layers/screens/favorites/favorites_screen.dart';
import 'package:hymnal_app/layers/screens/search/search_launcher.dart';
import 'package:hymnal_app/layers/screens/search/search_panel.dart';
import 'package:hymnal_app/layers/screens/settings/settings_screen.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/widgets/app_scaffold.dart';
import 'package:hymnal_app/widgets/glass/glass_tab_bar.dart';
import 'package:hymnal_app/widgets/glass/loupe_tab_bar/loupe_tab_bar.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';

part 'main_tabs_controller.dart';

class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({super.key});

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends _MainTabsController {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      // Atrás con la búsqueda abierta: la cierra en vez de salir.
      canPop: !_searchOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSearch();
      },
      child: SearchLauncher(
        open: _openSearch,
        child: AppScaffold(
          resizeToAvoidBottomInset: true,
          // Mientras se busca, el campo (en la barra) sube sobre el teclado.
          dockAboveKeyboard: _searchOpen,
          body: Stack(
            children: [
              IndexedStack(index: _currentIndex, children: _screens),
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
          ),
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
            selectedIndex: _currentIndex,
            onSelected: _onTabTapped,
            searchLabel: l10n.search,
            search: GlassTabSearch(
              controller: _searchController,
              focusNode: _searchFocus,
              open: _searchOpen,
              onOpen: _openSearch,
              onClose: _closeSearch,
              hint: l10n.searchHint,
              cancelLabel: l10n.cancel,
            ),
          ),
        ),
      ),
    );
  }
}

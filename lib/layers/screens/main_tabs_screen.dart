import 'package:flutter/material.dart';
import 'package:hymnal_app/layers/screens/home/home_screen.dart';
import 'package:hymnal_app/layers/screens/lists/lists_screen.dart';
import 'package:hymnal_app/layers/screens/favorites/favorites_screen.dart';
import 'package:hymnal_app/layers/screens/search/search_screen.dart';
import 'package:hymnal_app/layers/screens/settings/settings_screen.dart';
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

    return AppScaffold(
      resizeToAvoidBottomInset: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      // Barra de pestañas de cristal con la gota de agua y la lupa.
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
        onSearch: _openSearch,
        searchLabel: l10n.search,
      ),
    );
  }
}

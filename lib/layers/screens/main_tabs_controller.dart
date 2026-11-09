part of 'main_tabs_screen.dart';

abstract class _MainTabsController extends State<MainTabsScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ListsScreen(),
    const FavoritesScreen(),
    const SettingsScreen(),
  ];

  /// Búsqueda integrada en la barra (la lupa se transforma en el campo).
  bool _searchOpen = false;

  /// El panel de resultados sigue montado mientras se desvanece al cerrar.
  bool _searchPanelMounted = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openSearch() {
    if (_searchOpen) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _searchOpen = true;
      _searchPanelMounted = true;
    });
  }

  void _closeSearch() {
    if (!_searchOpen) return;
    _searchFocus.unfocus();
    _searchController.clear();
    setState(() => _searchOpen = false);
  }

  /// Abre un himno de los resultados (la búsqueda queda abierta al volver).
  void _openHymnFromSearch(Hymn hymn) {
    final hymnalId = GetIt.I<SettingsService>().selectedHymnal?.id;
    if (hymnalId == null) return;
    _searchFocus.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/hymn'),
        builder: (_) => HymnScreen(hymnalId: hymnalId, hymnNumber: hymn.number),
      ),
    );
  }
}

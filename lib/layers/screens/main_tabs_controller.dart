part of 'main_tabs_screen.dart';

/// Destinos de la navegación principal. La barra inferior (celular) muestra
/// todos menos Historial; la barra lateral (tableta), todos.
enum _Dest { home, lists, favorites, history, settings }

/// Himno elegido para el panel derecho (vista expandida).
typedef _SelectedHymn = ({String hymnalId, int number, bool skipHistory});

abstract class _MainTabsController extends State<MainTabsScreen> {
  static const List<_Dest> _compactTabs = [
    _Dest.home,
    _Dest.lists,
    _Dest.favorites,
    _Dest.settings,
  ];

  _Dest _dest = _Dest.home;

  /// Claves para conservar el estado de cada pantalla al cambiar de diseño
  /// (girar, pantalla dividida).
  final Map<_Dest, GlobalKey> _screenKeys = {
    for (final d in _Dest.values) d: GlobalKey(debugLabel: 'pantalla-$d'),
  };

  /// Pila de navegación de la columna de la lista (vista expandida).
  final GlobalKey<NavigatorState> _listNavigatorKey = GlobalKey();

  /// Himno abierto a la derecha en la vista expandida.
  final ValueNotifier<_SelectedHymn?> _selectedHymn = ValueNotifier(null);

  WindowClass? _lastWindowClass;

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
    _selectedHymn.dispose();
    super.dispose();
  }

  /// Ajustes al cambiar de clase de ventana (girar, redimensionar).
  void _onWindowClass(WindowClass windowClass) {
    final last = _lastWindowClass;
    _lastWindowClass = windowClass;
    if (last == null || last == windowClass) return;
    // Historial no está en la barra inferior.
    if (!windowClass.usesRail && _dest == _Dest.history) _dest = _Dest.home;
    // De expandida a otra con un himno abierto: se abre como pantalla.
    final selected = _selectedHymn.value;
    if (last.showsDetail && !windowClass.showsDetail && selected != null) {
      // Fuera de la construcción: avisar ahora al panel (que se está
      // desmontando) fallaría.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _selectedHymn.value = null;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/hymn'),
            builder: (_) => HymnScreen(
              hymnalId: selected.hymnalId,
              hymnNumber: selected.number,
              skipHistory: true,
            ),
          ),
        );
      });
    }
  }

  void _select(_Dest dest) {
    if (dest == _dest) return;
    setState(() => _dest = dest);
  }

  /// Abre el himno a la derecha (vista expandida).
  void _openInDetail(String hymnalId, int number, {bool skipHistory = false}) {
    _selectedHymn.value = (
      hymnalId: hymnalId,
      number: number,
      skipHistory: skipHistory,
    );
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
    if (_lastWindowClass?.showsDetail ?? false) {
      _openInDetail(hymnalId, hymn.number);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/hymn'),
        builder: (_) => HymnScreen(hymnalId: hymnalId, hymnNumber: hymn.number),
      ),
    );
  }
}

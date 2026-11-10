part of 'player_screen.dart';

abstract class _PlayerController extends State<PlayerScreen> {
  final AudioService _audioService = GetIt.I<AudioService>();
  final SettingsService _settingsService = GetIt.I<SettingsService>();
  final FavoritesService _favoritesService = GetIt.I<FavoritesService>();

  bool _isFavorite = false;

  /// Himnos y temas del himnario que suena (siguiente himno y sección).
  List<Hymn> _hymns = const [];
  List<ThematicCategory> _thematic = const [];
  String? _loadedHymnalId;

  /// Versiones disponibles del himno que suena.
  bool _hasInstrumental = true;
  bool _hasSung = true;
  int? _versionsHymn;

  @override
  void initState() {
    super.initState();

    _audioService.addListener(_checkFavorite);
    _favoritesService.addListener(_checkFavorite);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFavorite();
    });
  }

  @override
  void dispose() {
    _audioService.removeListener(_checkFavorite);
    _favoritesService.removeListener(_checkFavorite);
    super.dispose();
  }

  /// Carga los himnos y temas del himnario que suena (una vez por
  /// himnario).
  Future<void> _loadHymnalData() async {
    final hymnal = _audioService.currentHymnal;
    if (hymnal == null || hymnal.id == _loadedHymnalId) return;
    _loadedHymnalId = hymnal.id;
    final repository = GetIt.I<HymnalRepository>();
    final hymns = await repository.getHymns(hymnal.id);
    List<ThematicCategory> thematic;
    try {
      thematic = await repository.getThematicList(hymnal.id);
    } catch (_) {
      thematic = const [];
    }
    if (!mounted || _loadedHymnalId != hymnal.id) return;
    setState(() {
      _hymns = hymns;
      _thematic = thematic;
    });
  }

  /// El himno que sigue al actual (o `null` si es el último).
  Hymn? _nextAfter(Hymn hymn) {
    final i = _hymns.indexWhere((h) => h.number == hymn.number);
    return i >= 0 && i + 1 < _hymns.length ? _hymns[i + 1] : null;
  }

  /// Sección temática del himno (p. ej. "Adoración y alabanza").
  String? _sectionOf(int number) {
    for (final theme in _thematic) {
      for (final ambit in theme.ambits) {
        if (number >= ambit.start && number <= ambit.end) return ambit.name;
      }
    }
    return null;
  }

  /// Qué versiones (instrumental / cantada) tiene el himno que suena.
  Future<void> _loadVersions() async {
    final hymn = _audioService.currentHymn;
    if (hymn == null || hymn.number == _versionsHymn) return;
    _versionsHymn = hymn.number;
    final instrumental = await _audioService.versionUrl(instrumental: true);
    final sung = await _audioService.versionUrl(instrumental: false);
    if (!mounted || _versionsHymn != hymn.number) return;
    setState(() {
      _hasInstrumental = instrumental != null;
      _hasSung = sung != null;
    });
  }

  /// Velocidad siguiente: 1× → 2× → 3× → 1×.
  void _cycleSpeed() {
    final next = _audioService.speed.round() % 3 + 1;
    _audioService.setSpeed(next.toDouble());
  }

  /// Ver letra: la abre quien abrió el reproductor (en tableta, a la
  /// derecha); si no, como pantalla.
  void _viewLyrics() {
    final hymn = _audioService.currentHymn;
    final hymnal = _audioService.currentHymnal;
    if (hymn == null || hymnal == null) return;
    final open = widget.onOpenLyrics;
    if (open != null) {
      open();
    } else {
      _openHymnPage(context, hymnal.id, hymn.number);
    }
  }

  Future<void> _checkFavorite() async {
    _loadHymnalData();
    _loadVersions();
    final hymn = _audioService.currentHymn;
    final hymnal = _audioService.currentHymnal;

    if (hymn != null && hymnal != null) {
      final isFav = await _favoritesService.isFavorite(hymnal.id, hymn.number);
      if (mounted && isFav != _isFavorite) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final hymn = _audioService.currentHymn;
    final hymnal = _audioService.currentHymnal;

    if (hymn != null && hymnal != null) {
      await _favoritesService.toggleFavorite(
        hymnal.id,
        hymn.number,
        hymn.title,
      );
      await _checkFavorite();
    }
  }

  void _shareHymn() {
    final l10n = AppLocalizations.of(context)!;
    final hymn = _audioService.currentHymn;
    final hymnal = _audioService.currentHymnal;

    if (hymn != null) {
      final text = '''${hymn.title}

${hymn.content}''';

      final message = AppLinks.getShareMessage(
        text,
        l10n.sharedFromApp(AppLinks.appStoreUrl, AppLinks.playStoreUrl),
        hymnNumber: hymn.number.toString(),
        hymnTitle: hymnal!.name,
      );
      SharePlus.instance.share(ShareParams(text: message));
    }
  }

  void _openHymnPage(BuildContext context, String hymnalId, int hymnNumber) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/hymn'),
        builder: (_) => HymnScreen(
          hymnalId: hymnalId,
          hymnNumber: hymnNumber,
          skipHistory: true,
        ),
      ),
      (route) {
        return route.settings.name != '/hymn' &&
            route.settings.name != '/player';
      },
    );
  }
}

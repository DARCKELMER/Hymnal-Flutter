part of 'hymn_screen.dart';

abstract class _HymnController extends State<HymnScreen> {
  final HymnalRepository _repository = GetIt.I<HymnalRepository>();
  final SettingsService _settingsService = GetIt.I<SettingsService>();
  final FavoritesService _favoritesService = GetIt.I<FavoritesService>();
  final HistoryService _historyService = GetIt.I<HistoryService>();
  final AudioService _audioService = GetIt.I<AudioService>();

  Hymnal? _hymnal;
  Hymn? _hymn;
  MusicSettings? _musicSettings;
  PageController? _pageController;
  List<Hymn>? _allHymns;
  bool _isFavorite = false;

  /// Temas del himnario (para la etiqueta "HIMNO 1 · ADORACIÓN …").
  List<ThematicCategory> _thematic = const [];

  /// Versión elegida en la barra de audio.
  bool _instrumental = true;

  /// Texto seleccionado en la letra (copiar / compartir).
  String? _selectedText;

  @override
  void initState() {
    super.initState();

    _favoritesService.addListener(_onFavoritesChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _onFavoritesChanged() {
    if (_hymn != null && mounted) {
      _favoritesService.isFavorite(widget.hymnalId, _hymn!.number).then((
        isFav,
      ) {
        if (mounted && isFav != _isFavorite) {
          setState(() {
            _isFavorite = isFav;
          });
        }
      });
    }
  }

  Future<void> _loadData() async {
    final hymnals = await _repository.getHymnals();
    _hymnal = hymnals.firstWhere((h) => h.id == widget.hymnalId);

    _allHymns = await _repository.getHymns(widget.hymnalId);
    _hymn = _allHymns!.firstWhere((h) => h.number == widget.hymnNumber);

    try {
      _thematic = await _repository.getThematicList(widget.hymnalId);
    } catch (_) {
      _thematic = const [];
    }

    try {
      _musicSettings = await _repository.getMusicSettings(widget.hymnalId);
    } catch (_) {
      // Settings unavailable (e.g. offline on first launch).
      // Music controls will be hidden; the hymn is still usable.
      _musicSettings = null;
    }

    _isFavorite = await _favoritesService.isFavorite(
      widget.hymnalId,
      widget.hymnNumber,
    );

    // Versión inicial: la que suena si es este himno; si no, instrumental
    // cuando existe.
    _instrumental = _isCurrentInPlayer
        ? _audioService.isInstrumental
        : _hasVersion(_hymn!, instrumental: true) ||
              !_hasVersion(_hymn!, instrumental: false);

    _notifyHymnShown();

    final initialPage = _allHymns!.indexWhere(
      (h) => h.number == widget.hymnNumber,
    );
    _pageController = PageController(initialPage: initialPage);

    // Only add to history if not skipped
    if (!widget.skipHistory) {
      await _historyService.addToHistory(
        widget.hymnalId,
        _hymn!.number,
        _hymn!.title,
      );
    }

    if (_settingsService.keepScreenOn) {
      try {
        await WakelockPlus.enable();
      } catch (e) {
        debugPrint('Warning: Failed to enable wakelock: $e');
      }
    }

    if (mounted) setState(() {});
  }

  /// Modo automático "cada himno": cambia el paisaje.
  void _notifyHymnShown() {
    if (GetIt.I.isRegistered<BackgroundService>()) {
      GetIt.I<BackgroundService>().onHymnShown();
    }
  }

  Future<void> _onPageChanged(int index) async {
    final hymn = _allHymns![index];
    _notifyHymnShown();
    setState(() {
      _hymn = hymn;
    });

    // Only add to history if not skipped
    if (!widget.skipHistory) {
      await _historyService.addToHistory(
        widget.hymnalId,
        hymn.number,
        hymn.title,
      );
    }

    _isFavorite = await _favoritesService.isFavorite(
      widget.hymnalId,
      hymn.number,
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleFavorite() async {
    await _favoritesService.toggleFavorite(
      widget.hymnalId,
      _hymn!.number,
      _hymn!.title,
    );

    _isFavorite = await _favoritesService.isFavorite(
      widget.hymnalId,
      _hymn!.number,
    );

    if (mounted) setState(() {});
  }

  Future<void> _shareHymn() async {
    final l10n = AppLocalizations.of(context)!;
    final text = '''${_hymn!.title}

${_hymn!.content}''';

    final message = AppLinks.getShareMessage(
      text,
      l10n.sharedFromApp(AppLinks.appStoreUrl, AppLinks.playStoreUrl),
      hymnNumber: _hymn!.number.toString(),
      hymnTitle: _hymnal!.name,
    );
    await SharePlus.instance.share(ShareParams(text: message));
  }

  void _openSheets() {
    if (_hymnal?.hymnsSheetsFileName == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SheetsScreen(hymnal: _hymnal!, hymnNumber: _hymn!.number),
      ),
    );
  }

  Future<void> _playAudio({bool instrumental = true}) async {
    final url = instrumental
        ? _musicSettings?.getInstrumentalUrl(_hymn!.number)
        : _musicSettings?.getSungUrl(_hymn!.number);

    if (url != null) {
      try {
        await _audioService.playHymn(
          _hymnal!,
          _hymn!,
          url,
          instrumental: instrumental,
        );
      } catch (e) {
        debugPrint('Failed to play audio: $e');
      }
    }
  }

  /// Nombre de la sección temática del himno (p. ej. "Adoración y
  /// alabanza"), o `null` si no está en ninguna.
  String? _sectionOf(int number) {
    for (final theme in _thematic) {
      for (final ambit in theme.ambits) {
        if (number >= ambit.start && number <= ambit.end) return ambit.name;
      }
    }
    return null;
  }

  bool _hasVersion(Hymn hymn, {required bool instrumental}) =>
      (instrumental
          ? _musicSettings?.getInstrumentalUrl(hymn.number)
          : _musicSettings?.getSungUrl(hymn.number)) !=
      null;

  /// Si el himno abierto es el que está cargado en el reproductor.
  bool get _isCurrentInPlayer =>
      _hymn != null &&
      _audioService.currentHymn?.number == _hymn!.number &&
      _audioService.currentHymnal?.id == widget.hymnalId &&
      !_audioService.isDismissing;

  /// Reproducir / pausar en la versión elegida.
  Future<void> _togglePlay() async {
    final hymn = _hymn;
    if (hymn == null) return;
    // La versión elegida puede no existir: usa la que haya.
    var instrumental = _instrumental;
    if (!_hasVersion(hymn, instrumental: instrumental)) {
      instrumental = !instrumental;
    }
    if (_isCurrentInPlayer) {
      if (_audioService.isInstrumental != instrumental) {
        await _audioService.switchVersion(instrumental: instrumental);
      } else {
        await _audioService.togglePlayPause();
      }
      return;
    }
    await _playAudio(instrumental: instrumental);
  }

  /// Cambia la versión; si este himno ya suena, sigue en el mismo punto.
  Future<void> _selectVersion(bool instrumental) async {
    setState(() => _instrumental = instrumental);
    if (_isCurrentInPlayer && _audioService.isInstrumental != instrumental) {
      await _audioService.switchVersion(instrumental: instrumental);
    }
  }

  /// Himno anterior (-1) o siguiente (+1).
  void _goTo(int delta) {
    final controller = _pageController;
    final hymns = _allHymns;
    if (controller == null || hymns == null || !controller.hasClients) return;
    final page = (controller.page ?? 0).round() + delta;
    if (page < 0 || page >= hymns.length) return;
    controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  /// "Aa": tamaño de la letra (escala solo la letra del himno).
  void _showFontSize() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListenableBuilder(
        listenable: _settingsService,
        builder: (context, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.fontSize,
                  style: const TextStyle(
                    fontFamily: GlassTypography.ui,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    const Text('A', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: GlassSlider(
                        value: _settingsService.fontSize,
                        min: 12,
                        max: 32,
                        divisions: 10,
                        label: _settingsService.fontSize.round().toString(),
                        onChanged: _settingsService.setFontSize,
                      ),
                    ),
                    const Text('A', style: TextStyle(fontSize: 26)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Menú al seleccionar texto de la letra: copiar y compartir.
  Widget _selectionMenu(
    BuildContext context,
    SelectableRegionState selectableRegionState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final selected = _selectedText ?? '';
    final shareText = AppLinks.getShareMessage(
      selected,
      l10n.sharedFromApp(AppLinks.appStoreUrl, AppLinks.playStoreUrl),
    );
    return AdaptiveTextSelectionToolbar(
      anchors: selectableRegionState.contextMenuAnchors,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.copy, size: 18),
          label: Text(l10n.copy),
          onPressed: selected.isEmpty
              ? null
              : () {
                  Clipboard.setData(ClipboardData(text: shareText));
                  ContextMenuController.removeAny();
                },
        ),
        TextButton.icon(
          icon: const Icon(Icons.share, size: 18),
          label: Text(l10n.share),
          onPressed: selected.isEmpty
              ? null
              : () {
                  ContextMenuController.removeAny();
                  SharePlus.instance.share(ShareParams(text: shareText));
                },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _favoritesService.removeListener(_onFavoritesChanged);
    try {
      WakelockPlus.disable();
    } catch (e) {
      debugPrint('Warning: Failed to disable wakelock: $e');
    }
    _pageController?.dispose();
    super.dispose();
  }
}

part of 'sheets_screen.dart';

abstract class _SheetsController extends State<SheetsScreen> {
  final AudioService _audioService = GetIt.I<AudioService>();

  List<String> _sheetUrls = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  /// Encabezado y cápsula inferior visibles (un toque en la partitura los
  /// oculta para leer a pantalla completa).
  bool _chromeVisible = true;

  /// El himno (título y audio) y su música.
  Hymn? _hymn;
  MusicSettings? _musicSettings;

  /// Zoom por página: controlador y escala "ajustada" (100 %).
  final List<PhotoViewController> _zoom = [];
  final Map<int, double> _baseScale = {};
  final List<StreamSubscription<PhotoViewControllerValue>> _zoomSubs = [];

  late final PageController _pageController = PageController();

  void _toggleChrome() {
    if (mounted) setState(() => _chromeVisible = !_chromeVisible);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSheets();
      _loadHymn();
    });
  }

  @override
  void dispose() {
    for (final s in _zoomSubs) {
      s.cancel();
    }
    for (final c in _zoom) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadHymn() async {
    final repository = GetIt.I<HymnalRepository>();
    try {
      final hymns = await repository.getHymns(widget.hymnal.id);
      final hymn = hymns.where((h) => h.number == widget.hymnNumber);
      MusicSettings? music;
      try {
        music = await repository.getMusicSettings(widget.hymnal.id);
      } catch (_) {
        music = null; // Sin conexión: sin audio.
      }
      if (!mounted) return;
      setState(() {
        _hymn = hymn.isEmpty ? null : hymn.first;
        _musicSettings = music;
      });
    } catch (e) {
      debugPrint('No se pudo cargar el himno: $e');
    }
  }

  Future<void> _loadSheets() async {
    final l10n = AppLocalizations.of(context)!;
    if (widget.hymnal.hymnsSheetsFileName == null) {
      if (mounted) {
        setState(() {
          _errorMessage = l10n.noSheetMusicAvailable;
          _isLoading = false;
        });
      }
      return;
    }

    final baseName = widget.hymnal.hymnsSheetsFileName!.replaceAll(
      '###',
      widget.hymnNumber.toString().padLeft(3, '0'),
    );

    final urls = <String>[];

    // Check for base sheet
    final baseUrl = 'assets/musicSheets/$baseName';
    if (await _assetExists(baseUrl)) {
      urls.add(baseUrl);
    }

    // Check for additional pages
    for (int i = 1; i <= 6; i++) {
      final extraName = baseName.replaceAll('.png', '_$i.png');
      final extraUrl = 'assets/musicSheets/$extraName';
      if (await _assetExists(extraUrl)) {
        urls.add(extraUrl);
      }
    }

    if (!mounted) return;
    for (var i = 0; i < urls.length; i++) {
      final controller = PhotoViewController();
      _zoom.add(controller);
      _zoomSubs.add(
        controller.outputStateStream.listen((value) {
          final scale = value.scale;
          if (scale == null || !mounted) return;
          // La primera escala que calcula PhotoView es la "ajustada".
          _baseScale.putIfAbsent(i, () => scale);
          if (i == _currentIndex) setState(() {});
        }),
      );
    }
    setState(() {
      _sheetUrls = urls;
      _isLoading = false;
      if (urls.isEmpty) {
        _errorMessage = l10n.noSheetMusicFound(widget.hymnNumber);
      }
    });
  }

  Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _onPageChanged(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  /// Zoom de la página actual en % (100 = ajustada a la pantalla).
  int get _zoomPercent {
    if (_currentIndex >= _zoom.length) return 100;
    final base = _baseScale[_currentIndex];
    final scale = _zoom[_currentIndex].scale;
    if (base == null || scale == null || base == 0) return 100;
    return (scale / base * 100).round();
  }

  /// Acercar (factor > 1) o alejar (< 1), entre 100 % y 400 %.
  void _zoomBy(double factor) {
    if (_currentIndex >= _zoom.length) return;
    final base = _baseScale[_currentIndex];
    final controller = _zoom[_currentIndex];
    final scale = controller.scale;
    if (base == null || scale == null) return;
    controller.scale = (scale * factor).clamp(base, base * 4);
    if (controller.scale == base) controller.position = Offset.zero;
  }

  /// URL del audio de este himno en la versión pedida.
  String? _urlFor({required bool instrumental}) => instrumental
      ? _musicSettings?.getInstrumentalUrl(widget.hymnNumber)
      : _musicSettings?.getSungUrl(widget.hymnNumber);

  bool get _hasAudio =>
      _urlFor(instrumental: true) != null ||
      _urlFor(instrumental: false) != null;

  /// Si este himno es el que está en el reproductor.
  bool get _isCurrent =>
      _audioService.currentHymn?.number == widget.hymnNumber &&
      _audioService.currentHymnal?.id == widget.hymnal.id &&
      !_audioService.isDismissing;

  /// Reproducir / pausar este himno (instrumental si existe).
  Future<void> _togglePlay() async {
    if (_isCurrent) {
      await _audioService.togglePlayPause();
      return;
    }
    final hymn = _hymn;
    if (hymn == null) return;
    final instrumental = _urlFor(instrumental: true) != null;
    final url = _urlFor(instrumental: instrumental);
    if (url == null) return;
    try {
      await _audioService.playHymn(
        widget.hymnal,
        hymn,
        url,
        instrumental: instrumental,
      );
    } catch (e) {
      debugPrint('Failed to play audio: $e');
    }
  }
}

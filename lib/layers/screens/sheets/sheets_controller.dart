part of 'sheets_screen.dart';

/// Recursos empaquetados (se consulta una sola vez por ejecución).
Future<Set<String>>? _assetsCache;

Future<Set<String>> _bundledAssets() =>
    _assetsCache ??= AssetManifest.loadFromAssetBundle(rootBundle)
        .then((manifest) => manifest.listAssets().toSet());

/// Tamaño en píxeles de una imagen (sin dibujarla).
Future<Size> _imageSize(ImageProvider provider) {
  final completer = Completer<Size>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      if (!completer.isCompleted) {
        completer.complete(
          Size(info.image.width.toDouble(), info.image.height.toDouble()),
        );
      }
      stream.removeListener(listener);
    },
    onError: (error, _) {
      if (!completer.isCompleted) completer.completeError(error);
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return completer.future;
}

abstract class _SheetsController extends State<SheetsScreen> {
  final AudioService _audioService = GetIt.I<AudioService>();

  /// Paisajes ("Cambiar paisaje"); puede faltar en pruebas.
  final BackgroundService? _backgrounds =
      GetIt.I.isRegistered<BackgroundService>()
      ? GetIt.I<BackgroundService>()
      : null;

  List<String> _sheetUrls = [];

  /// Tamaño de cada página (en píxeles de la imagen).
  List<Size> _sizes = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  /// Encabezado y cápsula inferior visibles (un toque en la partitura los
  /// oculta para leer a pantalla completa).
  bool _chromeVisible = true;

  /// El himno (título y audio) y su música.
  Hymn? _hymn;
  MusicSettings? _musicSettings;

  /// Zoom y desplazamiento de las páginas.
  final TransformationController _transform = TransformationController();

  /// Tamaño del área visible y, de cada fila de páginas, su borde
  /// superior (para saber qué página se está leyendo).
  Size _viewport = Size.zero;
  List<double> _rowTops = const [];
  int _perRow = 1;

  /// Punto del doble toque (para acercar ahí).
  Offset? _doubleTapAt;

  void _toggleChrome() {
    if (mounted) setState(() => _chromeVisible = !_chromeVisible);
  }

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSheets();
      _loadHymn();
    });
  }

  @override
  void dispose() {
    _transform
      ..removeListener(_onTransform)
      ..dispose();
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
    final fileName = widget.hymnal.hymnsSheetsFileName;
    if (fileName == null) {
      if (mounted) {
        setState(() {
          _errorMessage = l10n.noSheetMusicAvailable;
          _isLoading = false;
        });
      }
      return;
    }

    final baseName = fileName.replaceAll(
      '###',
      widget.hymnNumber.toString().padLeft(3, '0'),
    );
    final extension = baseName.substring(baseName.lastIndexOf('.'));
    final assets = await _bundledAssets();

    // La página principal y las adicionales (_1, _2, …).
    final urls = <String>[
      for (final name in [
        baseName,
        for (var i = 1; i <= 6; i++)
          baseName.replaceAll(extension, '_$i$extension'),
      ])
        if (assets.contains('assets/musicSheets/$name'))
          'assets/musicSheets/$name',
    ];

    final sizes = <Size>[];
    for (final url in urls) {
      try {
        sizes.add(await _imageSize(AssetImage(url)));
      } catch (_) {
        sizes.add(const Size(1275, 1650));
      }
    }

    if (!mounted) return;
    setState(() {
      _sheetUrls = urls;
      _sizes = sizes;
      _isLoading = false;
      if (urls.isEmpty) {
        _errorMessage = l10n.noSheetMusicFound(widget.hymnNumber);
      }
    });
  }

  double get _scale => _transform.value.getMaxScaleOnAxis();

  /// La página que se está leyendo: la fila cuyo borde superior está por
  /// encima de un tercio de la pantalla. (El % del zoom también cambia, así
  /// que siempre se redibuja.)
  void _onTransform() {
    if (!mounted) return;
    var page = _currentIndex;
    if (_rowTops.isNotEmpty) {
      final scale = _scale;
      final y = -_transform.value.getTranslation().y / scale;
      final reading = y + _viewport.height / scale / 3;
      var row = 0;
      for (var i = 0; i < _rowTops.length; i++) {
        if (_rowTops[i] <= reading) row = i;
      }
      page = (row * _perRow).clamp(0, _sheetUrls.length - 1);
    }
    setState(() => _currentIndex = page);
  }

  /// Zoom en % (100 = ajustada a la pantalla).
  int get _zoomPercent => (_scale * 100).round();

  /// Acercar (factor > 1) o alejar (< 1) alrededor de [focus] (por
  /// defecto, el centro), entre 100 % y 400 %.
  void _zoomBy(double factor, {Offset? focus}) {
    final scale = _scale;
    final target = (scale * factor).clamp(1.0, 4.0);
    if (target <= 1.0001) {
      // Al 100 % vuelve a la columna (sin desplazamiento lateral).
      final y = _transform.value.getTranslation().y / scale;
      _transform.value = Matrix4.identity()..translateByDouble(0, y, 0, 1);
      return;
    }
    final ratio = target / scale;
    final c = focus ?? _viewport.center(Offset.zero);
    _transform.value = Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(ratio, ratio, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1)
      ..multiply(_transform.value);
  }

  /// Doble toque: acerca al 200 % donde se tocó, o vuelve al 100 %.
  void _onDoubleTap() {
    if (_scale > 1.05) {
      _zoomBy(1 / _scale);
    } else {
      _zoomBy(2, focus: _doubleTapAt);
    }
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

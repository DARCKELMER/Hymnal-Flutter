part of 'lists_screen.dart';

/// Vista de la lista.
enum _ListMode { numeric, alpha, thematic }

abstract class _ListsController extends State<ListsScreen> {
  final HymnalRepository _repository = GetIt.I<HymnalRepository>();
  final SettingsService _settingsService = GetIt.I<SettingsService>();
  final HistoryService _historyService = GetIt.I<HistoryService>();

  _ListMode _mode = _ListMode.numeric;

  List<Hymn>? _hymns;
  List<Hymn>? _alphabeticHymns;
  List<GlassIndexEntry> _numericIndex = const [];
  List<GlassIndexEntry> _alphabeticIndex = const [];
  List<ThematicCategory>? _thematicList;

  /// Temas abiertos en la vista temática.
  final Set<int> _expandedThemes = {};
  String? _lastHymnalId;

  @override
  void initState() {
    super.initState();
    _settingsService.addListener(_onSettingsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (_lastHymnalId == _settingsService.selectedHymnal?.id) return;
    setState(() {
      _hymns = null;
      _alphabeticHymns = null;
      _thematicList = null;
      _expandedThemes.clear();
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final hymnal = _settingsService.selectedHymnal;
    if (hymnal == null) return;
    _lastHymnalId = hymnal.id;

    final hymns = await _repository.getHymns(hymnal.id);
    final thematic = await _repository.getThematicList(hymnal.id);
    if (!mounted || _lastHymnalId != hymnal.id) return;

    // Alfabético: por la primera letra (sin signos) y luego por título.
    String normalizeTitle(String s) => StringUtils.normalize(
      s.trim().replaceFirst(RegExp(r'^[^\p{L}\p{N}]+', unicode: true), ''),
    );
    final alphabetic = List<Hymn>.from(hymns)
      ..sort((a, b) {
        final byLetter = _firstLetter(a.title).compareTo(_firstLetter(b.title));
        if (byLetter != 0) return byLetter;
        return normalizeTitle(a.title).compareTo(normalizeTitle(b.title));
      });

    setState(() {
      _hymns = hymns;
      _alphabeticHymns = alphabetic;
      _numericIndex = _buildNumericIndex(hymns);
      _alphabeticIndex = _buildAlphabeticIndex(alphabetic);
      _thematicList = thematic;
    });
  }

  /// Índice numérico del lienzo: 1, 100, 200 … (salta al primer himno con
  /// ese número o mayor).
  static List<GlassIndexEntry> _buildNumericIndex(List<Hymn> hymns) {
    if (hymns.isEmpty) return const [];
    final last = hymns.map((h) => h.number).reduce(math.max);
    final entries = <GlassIndexEntry>[];
    for (var n = 0; n <= last; n += 100) {
      final target = math.max(n, 1);
      final i = hymns.indexWhere((h) => h.number >= target);
      if (i >= 0) entries.add((label: '$target', itemIndex: i));
    }
    return entries;
  }

  /// Índice alfabético: cada letra presente y su primer himno.
  List<GlassIndexEntry> _buildAlphabeticIndex(List<Hymn> hymns) {
    final entries = <GlassIndexEntry>[];
    String? previous;
    for (final (i, hymn) in hymns.indexed) {
      final letter = _firstLetter(hymn.title);
      if (letter != previous) {
        entries.add((label: letter, itemIndex: i));
        previous = letter;
      }
    }
    return entries;
  }

  String _firstLetter(String title) {
    final norm = StringUtils.normalize(title);
    for (var i = 0; i < norm.length; i++) {
      final char = norm[i].toUpperCase();
      if (RegExp(r'\p{L}', unicode: true).hasMatch(char)) return char;
    }
    return '#';
  }

  void _toggleTheme(int index) {
    setState(() {
      if (!_expandedThemes.remove(index)) _expandedThemes.add(index);
    });
  }

  void _openAmbit(ThematicCategory category, Ambit ambit) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AmbitScreen(
          category: category.thematic,
          ambit: ambit,
          hymns: _hymns!
              .where((h) => h.number >= ambit.start && h.number <= ambit.end)
              .toList(),
        ),
      ),
    );
  }

  Future<void> _openHymn(Hymn hymn) async {
    final hymnal = _settingsService.selectedHymnal!;
    await _historyService.addToHistory(hymnal.id, hymn.number, hymn.title);
    if (!mounted) return;
    HymnOpener.open(context, hymnalId: hymnal.id, hymnNumber: hymn.number);
  }
}

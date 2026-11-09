part of 'lists_screen.dart';

abstract class _ListsController extends State<ListsScreen> {
  final HymnalRepository _repository = GetIt.I<HymnalRepository>();
  final SettingsService _settingsService = GetIt.I<SettingsService>();
  final HistoryService _historyService = GetIt.I<HistoryService>();

  List<Hymn>? _hymns;
  List<ThematicCategory>? _thematicList;
  List<Hymn>? _alphabeticHymns;
  List<String>? _alphabeticIndexBarData;
  List<NumericHymn>? _numericHymns;
  List<String>? _numericIndexBarData;
  String? _lastHymnalId;

  @override
  void initState() {
    super.initState();

    _settingsService.addListener(_onSettingsChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (_lastHymnalId != _settingsService.selectedHymnal?.id) {
      setState(() {
        _hymns = null;
        _thematicList = null;
        _alphabeticHymns = null;
        _alphabeticIndexBarData = null;
        _numericHymns = null;
        _numericIndexBarData = null;
      });
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final hymnal = _settingsService.selectedHymnal;
    if (hymnal == null) return;

    _lastHymnalId = hymnal.id;

    final hymns = await _repository.getHymns(hymnal.id);
    final thematic = await _repository.getThematicList(hymnal.id);

    // Pre-calculate sorted list and index bar data for Alphabetic tab
    final alphabeticHymns = List<Hymn>.from(hymns)
      ..sort((a, b) {
        final tagA = _getFirstLetter(a.title);
        final tagB = _getFirstLetter(b.title);
        final comparison = tagA.compareTo(tagB);
        if (comparison != 0) return comparison;

        String normalizeTitle(String s) {
          var t = s.trim();
          t = t.replaceFirst(RegExp(r'^[^A-Za-z0-9]+'), '');
          return t.toLowerCase();
        }

        return normalizeTitle(a.title).compareTo(normalizeTitle(b.title));
      });

    SuspensionUtil.setShowSuspensionStatus(alphabeticHymns);

    final presentTags = <String>{};
    for (final hymn in alphabeticHymns) {
      presentTags.add(hymn.getSuspensionTag());
    }
    final List<String> alphabeticIndexBarData = presentTags.where((t) => t != '#').toList()
      ..sort((a, b) {
        final na = StringUtils.normalize(a);
        final nb = StringUtils.normalize(b);
        return na.compareTo(nb);
      });
    if (presentTags.contains('#')) alphabeticIndexBarData.add('#');

    // Pre-calculate numeric list and index bar data
    final interval = 50;
    int itemCount = hymns.length;
    final List<int> numericIndices = [];
    int k = 0;
    while (true) {
      final int i = k == 0 ? 0 : k * interval - 1;
      if (i >= itemCount) break;
      numericIndices.add(i);
      k++;
    }
    if (numericIndices.isEmpty || numericIndices.last < itemCount - 1) {
      numericIndices.add(itemCount - 1);
    }

    final numericHymns = <NumericHymn>[];
    int currentStep = 0;
    for (int i = 0; i < itemCount; i++) {
      if (currentStep < numericIndices.length - 1 && i >= numericIndices[currentStep + 1]) {
        currentStep++;
      }
      final tagIndex = numericIndices[currentStep];
      final tagLabel = (tagIndex + 1).toString();
      numericHymns.add(NumericHymn(hymn: hymns[i], numericTag: tagLabel));
    }

    SuspensionUtil.setShowSuspensionStatus(numericHymns);
    final numericIndexBarData = numericIndices.map((i) => (i + 1).toString()).toList();

    if (mounted) {
      setState(() {
        _hymns = hymns;
        _thematicList = thematic;
        _alphabeticHymns = alphabeticHymns;
        _alphabeticIndexBarData = alphabeticIndexBarData;
        _numericHymns = numericHymns;
        _numericIndexBarData = numericIndexBarData;
      });
    }
  }

  String _getFirstLetter(String title) {
    final norm = StringUtils.normalize(title);
    if (norm.isEmpty) return '#';
    for (int i = 0; i < norm.length; i++) {
      final char = norm[i].toUpperCase();
      if (RegExp(r'\p{L}', unicode: true).hasMatch(char)) {
        return char;
      }
    }
    return '#';
  }

  Future<void> _openHymn(Hymn hymn) async {
    final hymnal = _settingsService.selectedHymnal!;
    await _historyService.addToHistory(hymnal.id, hymn.number, hymn.title);

    if (mounted) {
      HymnOpener.open(
      context,
      hymnalId: hymnal.id,
      hymnNumber: hymn.number,
    );
    }
  }
}

class NumericHymn implements ISuspensionBean {
  final Hymn hymn;
  final String numericTag;
  bool _isShowSuspension = false;

  NumericHymn({required this.hymn, required this.numericTag});

  @override
  String getSuspensionTag() => numericTag;

  @override
  bool get isShowSuspension => _isShowSuspension;

  @override
  set isShowSuspension(bool value) => _isShowSuspension = value;
}

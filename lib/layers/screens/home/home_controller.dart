part of 'home_screen.dart';

abstract class _HomeController extends State<HomeScreen> {
  final SettingsService _settingsService = GetIt.I<SettingsService>();
  final HistoryService _historyService = GetIt.I<HistoryService>();
  final HymnalRepository _repository = GetIt.I<HymnalRepository>();

  /// Teclado físico (tableta): números, retroceso y Enter.
  final FocusNode _keysFocus = FocusNode(debugLabel: 'teclado-inicio');

  /// Número escrito con el teclado numérico de cristal.
  String _number = '';

  /// Himnos del himnario elegido (para la vista previa del título).
  Map<int, Hymn> _hymnsByNumber = const {};
  String? _loadedHymnalId;

  /// Cuántas cifras admite el número (los himnarios llegan a cientos).
  static const int _maxDigits = 4;

  @override
  void initState() {
    super.initState();
    _settingsService.addListener(_loadHymns);
    _loadHymns();
  }

  @override
  void dispose() {
    _settingsService.removeListener(_loadHymns);
    _keysFocus.dispose();
    super.dispose();
  }

  /// Carga los himnos del himnario elegido (al abrir y al cambiarlo).
  Future<void> _loadHymns() async {
    final hymnal = _settingsService.selectedHymnal;
    if (hymnal == null || hymnal.id == _loadedHymnalId) return;
    _loadedHymnalId = hymnal.id;
    final hymns = await _repository.getHymns(hymnal.id);
    if (!mounted || _loadedHymnalId != hymnal.id) return;
    setState(() => _hymnsByNumber = {for (final h in hymns) h.number: h});
  }

  /// Himno del número escrito (`null` si no existe o no hay número).
  Hymn? get _previewHymn {
    final number = int.tryParse(_number);
    return number == null ? null : _hymnsByNumber[number];
  }

  void _typeDigit(int digit) {
    if (_number.length >= _maxDigits) return;
    // Sin ceros a la izquierda.
    if (_number.isEmpty && digit == 0) return;
    setState(() => _number += '$digit');
  }

  void _deleteDigit() {
    if (_number.isEmpty) return;
    setState(() => _number = _number.substring(0, _number.length - 1));
  }

  void _clearNumber() {
    if (_number.isEmpty) return;
    setState(() => _number = '');
  }

  /// Teclado físico: 0–9, retroceso, Supr y Enter.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final char = event.character;
    if (char != null && RegExp(r'^\d$').hasMatch(char)) {
      _typeDigit(int.parse(char));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace) {
      _deleteDigit();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete) {
      _clearNumber();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _openHymn();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _openHymn() async {
    final hymnal = _settingsService.selectedHymnal;
    final hymn = _previewHymn;
    if (hymnal == null || hymn == null) return;
    await _historyService.addToHistory(hymnal.id, hymn.number, hymn.title);
    if (!mounted) return;
    HymnOpener.open(context, hymnalId: hymnal.id, hymnNumber: hymn.number);
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
    );
  }

  Future<void> _showHymnalSelector() async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.selectHymnal,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._settingsService.hymnals.map((hymnal) {
                        final isSelected =
                            hymnal.id == _settingsService.selectedHymnal?.id;
                        return ListTile(
                          leading: Text(
                            hymnal.twoLetterIsoLanguageName.toUpperCase(),
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                          title: Text(hymnal.name),
                          subtitle: Text('${hymnal.year} • ${hymnal.detail}'),
                          trailing: isSelected ? const Icon(Icons.check) : null,
                          onTap: () {
                            _settingsService.selectHymnal(hymnal.id);
                            Navigator.pop(context);
                          },
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

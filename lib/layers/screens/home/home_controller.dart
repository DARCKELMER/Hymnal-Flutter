part of 'home_screen.dart';

abstract class _HomeController extends State<HomeScreen> {
  // Imports are handled by the part file
  final TextEditingController _numberController = TextEditingController();
  final SettingsService _settingsService = GetIt.I<SettingsService>();
  final HistoryService _historyService = GetIt.I<HistoryService>();
  final FocusNode _numberFocusNode = FocusNode();

  @override
  void dispose() {
    _numberController.dispose();
    _numberFocusNode.dispose();
    super.dispose();
  }

  void _unfocusKeyboard() {
    _numberFocusNode.unfocus();
  }

  Future<void> _openHymn() async {
    final numberText = _numberController.text.trim();
    if (numberText.isEmpty) {
      _numberFocusNode.requestFocus();
      return;
    }

    final number = int.tryParse(numberText);
    if (number == null || number <= 0) {
      _showError(AppLocalizations.of(context)!.invalidHymnNumber);
      return;
    }

    final hymnal = _settingsService.selectedHymnal;
    if (hymnal == null) {
      _showError(AppLocalizations.of(context)!.hymnalNotSelected);
      return;
    }

    final hymn = await GetIt.I<HymnalRepository>().getHymnByNumber(hymnal.id, number);
    if (!mounted) return;

    if (hymn == null) {
      _showError(AppLocalizations.of(context)!.hymnNotFound);
      return;
    }

    await _historyService.addToHistory(hymnal.id, hymn.number, hymn.title);
    if (!mounted) return;

    HymnOpener.open(
      context,
      hymnalId: hymnal.id,
      hymnNumber: hymn.number,
    );
  }

  Future<void> _showHymnalSelector() async {
    showModalBottomSheet(
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._settingsService.hymnals.map((hymnal) {
                        final isSelected = hymnal.id == _settingsService.selectedHymnal?.id;
                        return ListTile(
                          leading: Text(
                            hymnal.twoLetterIsoLanguageName.toUpperCase(),
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Theme.of(context).colorScheme.primary : null,
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

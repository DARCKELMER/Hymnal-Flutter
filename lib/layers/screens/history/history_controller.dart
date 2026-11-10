part of 'history_screen.dart';

abstract class _HistoryController extends State<HistoryScreen> {
  final HistoryService _historyService = GetIt.I<HistoryService>();
  final SettingsService _settingsService = GetIt.I<SettingsService>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _historyService.loadHistory();
    });
  }

  Future<void> _openHymn(String hymnalId, int hymnNumber, String title) async {
    // Don't add to history when opening from history
    if (mounted) {
      HymnOpener.open(
        context,
        hymnalId: hymnalId,
        hymnNumber: hymnNumber,
        skipHistory: true,
      );
    }
  }

  Future<void> _clearHistory() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearHistory),
        content: Text(l10n.clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.clear),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.clearHistory();
    }
  }

  String _getHymnalName(String hymnalId) {
    final hymnal = _settingsService.hymnals.firstWhere(
      (h) => h.id == hymnalId,
      orElse: () => _settingsService.hymnals.first,
    );
    return hymnal.name;
  }

  /// Fecha en el formato del idioma (p. ej. "10 nov 2026").
  String _formatDate(DateTime date) =>
      MaterialLocalizations.of(context).formatMediumDate(date);
}

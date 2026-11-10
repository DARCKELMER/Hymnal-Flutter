part of 'ambit_screen.dart';

abstract class _AmbitController extends State<AmbitScreen> {
  final SettingsService _settingsService = GetIt.I<SettingsService>();
  final HistoryService _historyService = GetIt.I<HistoryService>();

  Future<void> _onHymnTapped(Hymn hymn) async {
    await _historyService.addToHistory(
      _settingsService.selectedHymnal!.id,
      hymn.number,
      hymn.title,
    );
    if (mounted) {
      HymnOpener.open(
        context,
        hymnalId: _settingsService.selectedHymnal!.id,
        hymnNumber: hymn.number,
      );
    }
  }
}

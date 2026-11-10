import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/layers/data/repository/history_repository.dart';
import 'package:hymnal_app/layers/domain/model/hymn_history_entry.dart';

class HistoryService extends ChangeNotifier {
  final HistoryRepository _repository = GetIt.I<HistoryRepository>();

  List<HymnHistoryEntry> _history = [];
  bool _isLoading = false;

  List<HymnHistoryEntry> get history => _history;
  bool get isLoading => _isLoading;

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    _history = await _repository.getHistory();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addToHistory(
    String hymnalId,
    int hymnNumber,
    String title,
  ) async {
    final entry = HymnHistoryEntry(
      hymnalId: hymnalId,
      hymnNumber: hymnNumber,
      title: title,
      openedAt: DateTime.now(),
    );

    await _repository.addToHistory(entry);
    await loadHistory();
  }

  Future<void> clearHistory() async {
    await _repository.clearHistory();
    await loadHistory();
  }
}

import 'package:flutter/material.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_opener.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/services/history_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/widgets/app_scaffold.dart';

import 'package:hymnal_app/l10n/generated/app_localizations.dart';

part 'history_controller.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends _HistoryController {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _historyService,
      builder: (context, child) {
        final history = _historyService.history;

        return AppScaffold(
          appBar: AppBar(
            toolbarHeight: MediaQuery.of(context).orientation == Orientation.landscape ? 40 : null,
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            titleTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            title: Text(l10n.history),
            actions: [
              if (history.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: _clearHistory,
                ),
            ],
          ),
          body: history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noHistoryYet,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6),
                        child: Text(
                          '${entry.hymnNumber}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(entry.title),
                      subtitle: Text(
                        '${_getHymnalName(entry.hymnalId)} • ${_formatDate(entry.openedAt)}',
                      ),
                      onTap: () => _openHymn(
                        entry.hymnalId,
                        entry.hymnNumber,
                        entry.title,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

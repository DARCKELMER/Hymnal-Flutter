import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/core/utils/search_match.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/data/repository/hymnal_repository.dart';
import 'package:hymnal_app/layers/domain/model/hymn.dart';
import 'package:hymnal_app/services/recent_searches_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
import 'package:hymnal_app/widgets/glass/glass_card.dart';

/// Resultados de la búsqueda integrada en la barra, sobre el paisaje en una
/// tarjeta de cristal legible.
///
/// - Campo vacío: las búsquedas recientes (o una ayuda si no hay).
/// - Con texto: resultados ordenados por relevancia (número exacto
///   primero), sin tildes ni mayúsculas, con lo buscado resaltado en el
///   título y en un fragmento de la letra.
class SearchPanel extends StatefulWidget {
  const SearchPanel({
    required this.controller,
    required this.onOpenHymn,
    super.key,
  });

  final TextEditingController controller;

  /// Abrir un himno de los resultados.
  final void Function(Hymn hymn) onOpenHymn;

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  final HymnalRepository _repository = GetIt.I<HymnalRepository>();
  final SettingsService _settings = GetIt.I<SettingsService>();
  final RecentSearchesService _recent = GetIt.I<RecentSearchesService>();

  List<Hymn> _results = const [];
  String _query = '';
  bool _loading = false;
  Timer? _debounce;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onQueryChanged);
    _recent.load();
    _onQueryChanged();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onQueryChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = widget.controller.text.trim();
    if (query == _query) return;
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _query = '';
        _results = const [];
        _loading = false;
      });
      return;
    }
    // Espera a que deje de escribir un momento.
    _debounce = Timer(const Duration(milliseconds: 150), () => _search(query));
  }

  Future<void> _search(String query) async {
    final hymnalId = _settings.selectedHymnal?.id;
    if (hymnalId == null) return;
    final id = ++_requestId;
    setState(() => _loading = true);
    final results = await _repository.searchHymns(hymnalId, query);
    if (!mounted || id != _requestId) return;
    setState(() {
      _query = query;
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final typing = widget.controller.text.trim().isNotEmpty;

    final Widget content;
    if (!typing) {
      content = ListenableBuilder(
        listenable: _recent,
        builder: (context, _) => _recent.items.isEmpty
            ? _Message(icon: Icons.search_rounded, text: l10n.searchEmptyHint)
            : _RecentList(
                items: _recent.items,
                onPick: (q) => widget.controller.value = TextEditingValue(
                  text: q,
                  selection: TextSelection.collapsed(offset: q.length),
                ),
                onRemove: _recent.remove,
              ),
      );
    } else if (_results.isEmpty && !_loading && _query.isNotEmpty) {
      content = _Message(
        icon: Icons.search_off_rounded,
        text: l10n.noHymnsFound,
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            text: l10n.searchResultsCount(_results.length),
            loading: _loading,
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: _results.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                indent: 72,
                endIndent: 16,
                color: tokens.textPrimary.withValues(alpha: .1),
              ),
              itemBuilder: (context, i) => _ResultRow(
                hymn: _results[i],
                query: _query,
                onTap: () {
                  _recent.add(_query);
                  widget.onOpenHymn(_results[i]);
                },
              ),
            ),
          ),
        ],
      );
    }

    return GlassCard(child: content);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.text, this.loading = false});

  final String text;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              GlassTypography.sectionText(text),
              style: GlassTypography.sectionLabel(tokens.textSecondary),
            ),
          ),
          if (loading)
            SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: tokens.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: tokens.textSecondary),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GlassTypography.listRow(tokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({
    required this.items,
    required this.onPick,
    required this.onRemove,
  });

  final List<String> items;
  final ValueChanged<String> onPick;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        _Header(text: l10n.recentSearches),
        for (final item in items)
          Semantics(
            container: true,
            button: true,
            label: item,
            onTap: () => onPick(item),
            child: InkWell(
              onTap: () => onPick(item),
              child: SizedBox(
                height: GlassMetrics.minTouchTarget + 4,
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    Icon(
                      Icons.history_rounded,
                      size: 20,
                      color: tokens.textSecondary,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ExcludeSemantics(
                        child: Text(
                          item,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GlassTypography.listRow(tokens.textPrimary),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.removeRecentSearch,
                      onPressed: () => onRemove(item),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.hymn,
    required this.query,
    required this.onTap,
  });

  final Hymn hymn;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final titleStyle = GlassTypography.listRow(tokens.textPrimary);
    final snippetStyle = TextStyle(
      fontFamily: GlassTypography.ui,
      fontSize: 13,
      height: 1.35,
      color: tokens.textSecondary,
    );
    final mark = TextStyle(
      color: tokens.accent,
      fontWeight: FontWeight.w700,
      backgroundColor: tokens.accent.withValues(alpha: .14),
    );
    final snippet = SearchMatch.snippet(hymn.content, query);
    final numberMatches = hymn.number.toString() == query.trim();

    return Semantics(
      container: true,
      button: true,
      label: '${hymn.number}. ${hymn.title}',
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: numberMatches
                      ? tokens.accent.withValues(alpha: .18)
                      : tokens.selected,
                ),
                child: Text(
                  '${hymn.number}',
                  style: TextStyle(
                    fontFamily: GlassTypography.ui,
                    fontSize: hymn.number > 99 ? 13 : 15,
                    fontWeight: FontWeight.w700,
                    color: tokens.accent,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      highlight(
                        hymn.title,
                        SearchMatch.ranges(hymn.title, query),
                        titleStyle,
                        mark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text.rich(
                      highlight(
                        snippet.text,
                        snippet.ranges,
                        snippetStyle,
                        mark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Texto con los [ranges] resaltados con [mark].
@visibleForTesting
TextSpan highlight(
  String text,
  List<(int, int)> ranges,
  TextStyle base,
  TextStyle mark,
) {
  if (ranges.isEmpty) return TextSpan(text: text, style: base);
  final spans = <TextSpan>[];
  var at = 0;
  for (final (start, end) in ranges) {
    if (start < at || end > text.length) continue;
    if (start > at) spans.add(TextSpan(text: text.substring(at, start)));
    spans.add(TextSpan(text: text.substring(start, end), style: mark));
    at = end;
  }
  if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
  return TextSpan(style: base, children: spans);
}

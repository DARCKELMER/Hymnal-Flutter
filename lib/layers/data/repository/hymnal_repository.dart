import 'package:hymnal_app/core/utils/string_utils.dart';

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/core/constants/app_assets.dart';
import 'package:hymnal_app/layers/data/repository/remote_settings_repository.dart';
import 'package:hymnal_app/layers/domain/model/hymn.dart';
import 'package:hymnal_app/layers/domain/model/hymnal.dart';
import 'package:hymnal_app/layers/domain/model/thematic_category.dart';
import 'package:hymnal_app/layers/domain/model/music_settings.dart';

abstract class HymnalRepository {
  Future<List<Hymnal>> getHymnals();
  Future<List<Hymn>> getHymns(String hymnalId);
  Future<List<ThematicCategory>> getThematicList(String hymnalId);
  Future<MusicSettings?> getMusicSettings(String hymnalId);
  Future<Hymn?> getHymnByNumber(String hymnalId, int number);
  Future<List<Hymn>> searchHymns(String hymnalId, String query);
}

class HymnalRepositoryImpl implements HymnalRepository {
  List<Hymnal>? _cachedHymnals;
  final Map<String, List<Hymn>> _cachedHymns = {};
  final Map<String, List<ThematicCategory>> _cachedThematicLists = {};

  @override
  Future<List<Hymnal>> getHymnals() async {
    if (_cachedHymnals != null) return _cachedHymnals!;

    final jsonString = await rootBundle.loadString(AppAssets.infoConstants);
    final List<dynamic> jsonList = json.decode(jsonString);
    _cachedHymnals = jsonList.map((e) => Hymnal.fromJson(e)).toList();
    return _cachedHymnals!;
  }

  @override
  Future<List<Hymn>> getHymns(String hymnalId) async {
    if (_cachedHymns.containsKey(hymnalId)) return _cachedHymns[hymnalId]!;

    final hymnals = await getHymnals();
    final hymnal = hymnals.firstWhere((h) => h.id == hymnalId);

    final jsonString = await rootBundle.loadString(
      'assets/hymns/${hymnal.hymnsFileName}',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    final hymns = jsonList.map((e) => Hymn.fromJson(e)).toList();

    _cachedHymns[hymnalId] = hymns;
    return hymns;
  }

  @override
  Future<List<ThematicCategory>> getThematicList(String hymnalId) async {
    if (_cachedThematicLists.containsKey(hymnalId)) {
      return _cachedThematicLists[hymnalId]!;
    }

    final hymnals = await getHymnals();
    final hymnal = hymnals.firstWhere((h) => h.id == hymnalId);

    final jsonString = await rootBundle.loadString(
      'assets/hymns/${hymnal.thematicHymnsFileName}',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    final thematicList = jsonList
        .map((e) => ThematicCategory.fromJson(e))
        .toList();

    _cachedThematicLists[hymnalId] = thematicList;
    return thematicList;
  }

  @override
  Future<MusicSettings?> getMusicSettings(String hymnalId) async {
    final remoteRepo = GetIt.I<RemoteSettingsRepository>();

    // If settings are already cached, return immediately.
    final cached = remoteRepo.getMusicSettingsForHymnal(hymnalId);
    if (cached != null) return cached;

    // Otherwise, attempt to fetch from the network.
    await remoteRepo.fetchSettings();
    return remoteRepo.getMusicSettingsForHymnal(hymnalId);
  }

  @override
  Future<Hymn?> getHymnByNumber(String hymnalId, int number) async {
    final hymns = await getHymns(hymnalId);
    try {
      return hymns.firstWhere((h) => h.number == number);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Hymn>> searchHymns(String hymnalId, String query) async {
    final hymns = await getHymns(hymnalId);
    final normalizedQuery = StringUtils.normalize(query);

    if (normalizedQuery.isEmpty && query.isNotEmpty) {
      // If query only contains special chars, still try to match originally
      final lowerQuery = query.toLowerCase();
      return hymns.where((hymn) {
        return hymn.title.toLowerCase().contains(lowerQuery) ||
            hymn.content.toLowerCase().contains(lowerQuery) ||
            hymn.number.toString().contains(lowerQuery);
      }).toList();
    }

    final matches = hymns.where((hymn) {
      return hymn.normalizedTitle.contains(normalizedQuery) ||
          hymn.normalizedContent.contains(normalizedQuery) ||
          hymn.number.toString().contains(normalizedQuery);
    }).toList();
    return rankSearchResults(matches, normalizedQuery);
  }
}

/// Ordena los resultados por relevancia (orden estable; a igual relevancia,
/// por número):
/// 1. número exacto ("120" → himno 120),
/// 2. números que empiezan así ("12" → 120, 121…),
/// 3. títulos que empiezan con lo buscado,
/// 4. títulos que lo contienen,
/// 5. números que lo contienen,
/// 6. el resto (coincide en la letra).
List<Hymn> rankSearchResults(List<Hymn> hymns, String normalizedQuery) {
  final q = normalizedQuery;
  final digits = RegExp(r'^\d+$').hasMatch(q);
  int rank(Hymn h) {
    final n = h.number.toString();
    if (digits && n == q) return 0;
    if (digits && n.startsWith(q)) return 1;
    if (h.normalizedTitle.startsWith(q)) return 2;
    if (h.normalizedTitle.contains(q)) return 3;
    if (n.contains(q)) return 4;
    return 5;
  }

  final ranked = [for (final h in hymns) (rank(h), h)];
  ranked.sort((a, b) {
    final byRank = a.$1.compareTo(b.$1);
    return byRank != 0 ? byRank : a.$2.number.compareTo(b.$2.number);
  });
  return [for (final r in ranked) r.$2];
}

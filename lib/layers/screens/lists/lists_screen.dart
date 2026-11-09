import 'package:flutter/material.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_opener.dart';
import 'package:get_it/get_it.dart';
import 'package:azlistview/azlistview.dart';
import 'package:hymnal_app/layers/data/repository/hymnal_repository.dart';
import 'package:hymnal_app/layers/domain/model/hymn.dart';
import 'package:hymnal_app/layers/domain/model/thematic_category.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/services/history_service.dart';
import 'package:hymnal_app/layers/screens/lists/ambit_screen.dart';
import 'package:hymnal_app/widgets/hymn_list_tile.dart';

import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/core/utils/string_utils.dart';

part 'lists_controller.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends _ListsController {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.numeric, icon: const Icon(Icons.format_list_numbered)),
              Tab(text: l10n.alpha, icon: const Icon(Icons.sort_by_alpha)),
              Tab(text: l10n.thematic, icon: const Icon(Icons.category)),
            ],
          ),
        ),
        body: _hymns == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildNumericList(),
                  _buildAlphabeticList(),
                  _buildThematicList(),
                ],
              ),
      ),
    );
  }

  Widget _buildNumericList() {
    if (_numericHymns == null || _numericIndexBarData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AzListView(
      data: _numericHymns!,
      itemCount: _numericHymns!.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) {
        final hymn = _numericHymns![index].hymn;
        return HymnListTile(
          number: hymn.number,
          title: hymn.title,
          onTap: () => _openHymn(hymn),
        );
      },
      indexBarData: _numericIndexBarData!,
      indexBarItemHeight: 18,
      indexBarMargin: const EdgeInsets.only(right: 4),
      susItemBuilder: (context, index) {
        final numericHymn = _numericHymns![index];
        if (!numericHymn.isShowSuspension) {
          return const SizedBox.shrink();
        }
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.centerLeft,
          child: Text(
            numericHymn.getSuspensionTag(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
      susItemHeight: 32,
      indexHintBuilder: (context, hint) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            hint,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlphabeticList() {
    if (_alphabeticHymns == null || _alphabeticIndexBarData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AzListView(
      data: _alphabeticHymns!,
      itemCount: _alphabeticHymns!.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) {
        final hymn = _alphabeticHymns![index];
        return HymnListTile(
          number: hymn.number,
          title: hymn.title,
          onTap: () => _openHymn(hymn),
        );
      },
      indexBarData: _alphabeticIndexBarData!,
      indexBarItemHeight: 18,
      indexBarMargin: const EdgeInsets.only(right: 4),
      susItemBuilder: (context, index) {
        final hymn = _alphabeticHymns![index];
        if (!hymn.isShowSuspension) {
          return const SizedBox.shrink();
        }
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.centerLeft,
          child: Text(
            hymn.getSuspensionTag(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
      susItemHeight: 32,
      indexHintBuilder: (context, hint) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            hint,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildThematicList() {
    if (_thematicList == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _thematicList!.length,
      itemBuilder: (context, index) {
        final category = _thematicList![index];
        return ExpansionTile(
          title: Text(
            category.thematic,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          children: category.ambits.map((ambit) {
            return ListTile(
              dense: true,
              title: Text(ambit.name),
              subtitle: Text(AppLocalizations.of(context)!.hymnRange(ambit.start, ambit.end)),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AmbitScreen(
                    category: category.thematic,
                    ambit: ambit,
                    hymns: _hymns!
                        .where((h) => h.number >= ambit.start && h.number <= ambit.end)
                        .toList(),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

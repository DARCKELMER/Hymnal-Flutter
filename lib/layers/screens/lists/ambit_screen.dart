import 'package:flutter/material.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_opener.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/layers/domain/model/thematic_category.dart';
import 'package:hymnal_app/layers/domain/model/hymn.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/services/history_service.dart';
import 'package:hymnal_app/widgets/app_scaffold.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
import 'package:hymnal_app/widgets/glass/glass_hymn_list.dart';

part 'ambit_controller.dart';

class AmbitScreen extends StatefulWidget {
  final String category;
  final Ambit ambit;
  final List<Hymn> hymns;

  const AmbitScreen({
    super.key,
    required this.category,
    required this.ambit,
    required this.hymns,
  });

  @override
  State<AmbitScreen> createState() => _AmbitScreenState();
}

class _AmbitScreenState extends _AmbitController {
  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return AppScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: tokens.textPrimary,
        centerTitle: false,
        titleTextStyle: GlassTypography.listRow(
          tokens.textPrimary,
          selected: true,
        ).copyWith(fontSize: 20),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category,
              style: TextStyle(
                fontFamily: GlassTypography.ui,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tokens.textSecondary,
              ),
            ),
            Text(widget.ambit.name),
          ],
        ),
      ),
      // La misma lista de cristal que Listas.
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          GlassMetrics.screenMarginPhone,
          8,
          GlassMetrics.screenMarginPhone,
          0,
        ),
        child: GlassHymnList(
          items: [
            for (final h in widget.hymns)
              GlassHymnItem(number: h.number, title: h.title),
          ],
          hymnalId: _settingsService.selectedHymnal?.id,
          padding: const EdgeInsets.only(bottom: 8),
          onTap: (i) => _onHymnTapped(widget.hymns[i]),
        ),
      ),
    );
  }
}

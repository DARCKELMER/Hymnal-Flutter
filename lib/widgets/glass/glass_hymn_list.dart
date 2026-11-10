import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
import 'package:hymnal_app/widgets/glass/glass_card.dart';
import 'package:hymnal_app/widgets/glass/glass_haptics.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Un himno en una [GlassHymnList].
@immutable
class GlassHymnItem {
  const GlassHymnItem({
    required this.number,
    required this.title,
    this.subtitle,
  });

  final int number;
  final String title;
  final String? subtitle;
}

/// Una entrada del índice lateral: texto y la fila a la que salta.
typedef GlassIndexEntry = ({String label, int itemIndex});

/// Lista de himnos del lienzo (Listas, Favoritos, Historial, secciones):
/// una tarjeta de cristal legible con filas de 54 dp (insignia circular de
/// 36 dp con el número y el título). Si el himno está sonando, su insignia
/// va tintada y aparece un ecualizador. Con [index], una cápsula de cristal
/// de 34 dp a la derecha para saltar (tocar o arrastrar).
///
/// Debe ir dentro de una zona de cristal (`GlassZone`) si lleva índice.
class GlassHymnList extends StatefulWidget {
  const GlassHymnList({
    required this.items,
    required this.onTap,
    this.hymnalId,
    this.index,
    this.trailingBuilder,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final List<GlassHymnItem> items;
  final ValueChanged<int> onTap;

  /// Himnario de la lista: para marcar el himno que está sonando.
  final String? hymnalId;
  final List<GlassIndexEntry>? index;

  /// Algo al final de cada fila (p. ej. quitar de favoritos).
  final Widget? Function(int index)? trailingBuilder;
  final EdgeInsets padding;

  /// Alto de cada fila.
  static const double rowHeight = 54;

  /// Ancho del índice lateral.
  static const double indexWidth = 34;

  @override
  State<GlassHymnList> createState() => _GlassHymnListState();
}

class _GlassHymnListState extends State<GlassHymnList> {
  final ScrollController _scroll = ScrollController();
  int _lastIndexEntry = -1;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Salta a la entrada del índice bajo [dy] (posición en el índice).
  void _jumpTo(double dy, double height) {
    final entries = widget.index!;
    final i = (dy / height * entries.length).floor().clamp(
      0,
      entries.length - 1,
    );
    if (i == _lastIndexEntry) return;
    _lastIndexEntry = i;
    GlassHaptics.tick(context);
    final offset = entries[i].itemIndex * GlassHymnList.rowHeight;
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(math.min(offset, _scroll.position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final audio = GetIt.I.isRegistered<AudioService>()
        ? GetIt.I<AudioService>()
        : null;
    final list = GlassCard(
      child: ListenableBuilder(
        listenable: audio ?? ChangeNotifier(),
        builder: (context, _) {
          final playing =
              audio != null &&
                  audio.currentHymnal?.id == widget.hymnalId &&
                  !audio.isDismissing
              ? audio.currentHymn?.number
              : null;
          return ListView.builder(
            controller: _scroll,
            padding: widget.padding,
            itemCount: widget.items.length,
            itemExtent: GlassHymnList.rowHeight,
            itemBuilder: (context, i) {
              final item = widget.items[i];
              return GlassHymnRow(
                item: item,
                playing: playing == item.number,
                showDivider: i < widget.items.length - 1,
                trailing: widget.trailingBuilder?.call(i),
                onTap: () => widget.onTap(i),
              );
            },
          );
        },
      ),
    );
    final index = widget.index;
    if (index == null || index.isEmpty) return list;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: list),
        const SizedBox(width: 8),
        // Índice lateral: cápsula de cristal de 34 dp.
        LayoutBuilder(
          builder: (context, constraints) {
            final height = math.min(
              constraints.maxHeight,
              index.length * 28.0 + 16,
            );
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _jumpTo(d.localPosition.dy - 8, height - 16),
              onVerticalDragUpdate: (d) =>
                  _jumpTo(d.localPosition.dy - 8, height - 16),
              onVerticalDragEnd: (_) => _lastIndexEntry = -1,
              onTapUp: (_) => _lastIndexEntry = -1,
              child: SizedBox(
                width: GlassHymnList.indexWidth,
                height: height,
                child: LiquidGlass(
                  shape: const LiquidRoundedSuperellipse(
                    borderRadius: GlassHymnList.indexWidth / 2,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final entry in index)
                          Text(
                            entry.label,
                            style: TextStyle(
                              fontFamily: GlassTypography.ui,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: tokens.textPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Fila de 54 dp: insignia circular de 36 dp con el número, título (y
/// subtítulo opcional). Si suena, la insignia va tintada con un
/// ecualizador.
class GlassHymnRow extends StatelessWidget {
  const GlassHymnRow({
    required this.item,
    required this.onTap,
    this.playing = false,
    this.showDivider = true,
    this.trailing,
    super.key,
  });

  final GlassHymnItem item;
  final VoidCallback onTap;
  final bool playing;
  final bool showDivider;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final subtitle = item.subtitle;
    return Semantics(
      container: true,
      button: true,
      label: '${item.number}. ${item.title}',
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: showDivider
                ? Border(
                    bottom: BorderSide(
                      color: tokens.textPrimary.withValues(alpha: .08),
                    ),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: playing ? tokens.buttonTint : tokens.selected,
                      border: Border.all(color: const Color(0x4DFFFFFF)),
                    ),
                    child: Text(
                      '${item.number}',
                      style: TextStyle(
                        fontFamily: GlassTypography.ui,
                        fontSize: item.number > 99 ? 12 : 14,
                        fontWeight: FontWeight.w700,
                        color: playing ? Colors.white : tokens.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GlassTypography.listRow(
                            tokens.textPrimary,
                            selected: playing,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: GlassTypography.ui,
                              fontSize: 12,
                              color: tokens.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (playing)
                  Icon(
                    Icons.graphic_eq_rounded,
                    size: 20,
                    color: tokens.accent,
                  ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

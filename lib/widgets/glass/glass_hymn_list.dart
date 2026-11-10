import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
import 'package:hymnal_app/widgets/glass/glass_card.dart';
import 'package:hymnal_app/widgets/glass/loupe_tab_bar/loupe_tab_bar.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Un himno en una [GlassHymnList].
@immutable
class GlassHymnItem {
  const GlassHymnItem({
    required this.number,
    required this.title,
    this.subtitle,
    this.hymnalId,
  });

  final int number;
  final String title;
  final String? subtitle;

  /// Himnario del himno, si la lista mezcla himnarios (Favoritos,
  /// Historial). Si no, se usa el de la lista.
  final String? hymnalId;
}

/// Una entrada del índice lateral: texto y la fila a la que salta.
typedef GlassIndexEntry = ({String label, int itemIndex});

/// Lista de himnos del lienzo (Listas, Favoritos, Historial, secciones):
/// una tarjeta de cristal legible con filas de 54 dp (insignia circular de
/// 36 dp con el número y el título). Si el himno está sonando, su insignia
/// va tintada y aparece un ecualizador. Con [index], a la derecha la misma
/// barra del menú con la gota (34 dp, vertical): la lista avanza mientras
/// se arrastra la gota.
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
    this.onReorder,
    this.confirmRemove,
    this.onRemove,
    super.key,
  }) : assert(
         onReorder == null || index == null,
         'Una lista que se reordena no lleva índice',
       );

  final List<GlassHymnItem> items;
  final ValueChanged<int> onTap;

  /// Himnario de la lista: para marcar el himno que está sonando.
  final String? hymnalId;
  final List<GlassIndexEntry>? index;

  /// Algo al final de cada fila (p. ej. quitar de favoritos).
  final Widget? Function(int index)? trailingBuilder;
  final EdgeInsets padding;

  /// Si se da, las filas se reordenan arrastrando (pulsación larga en la
  /// fila, o al instante desde el asa a la derecha).
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// Si se da [onRemove], las filas se quitan deslizando hacia la
  /// izquierda; [confirmRemove] puede pedir confirmación.
  final Future<bool?> Function(int index)? confirmRemove;
  final ValueChanged<int>? onRemove;

  /// Alto de cada fila.
  static const double rowHeight = 54;

  /// Ancho del índice lateral.
  static const double indexWidth = 34;

  /// Alto de cada entrada del índice.
  static const double indexSlot = 30;

  @override
  State<GlassHymnList> createState() => _GlassHymnListState();
}

class _GlassHymnListState extends State<GlassHymnList> {
  final ScrollController _scroll = ScrollController();

  /// Entrada del índice del tramo visible (la gota del índice va ahí).
  int _visibleEntry = 0;

  /// Mientras se arrastra la gota del índice, el desplazamiento no la
  /// mueve (la mueve el dedo).
  bool _indexDriving = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(GlassHymnList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Otra lista (p. ej. de Numérico a Alfabético): vuelve arriba sin
    // recrear la tarjeta de cristal. (Las filas se reconstruyen en cada
    // redibujado; el índice de cada vista es estable.)
    final switched =
        !identical(oldWidget.index, widget.index) ||
        oldWidget.items.length != widget.items.length;
    if (switched) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
      _visibleEntry = 0;
    }
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// La gota del índice sigue al tramo visible al desplazar la lista.
  void _onScroll() {
    final index = widget.index;
    if (_indexDriving || index == null || index.isEmpty) return;
    final first = (_scroll.offset / GlassHymnList.rowHeight).floor();
    var entry = 0;
    for (final (i, e) in index.indexed) {
      if (e.itemIndex <= first) entry = i;
    }
    if (entry != _visibleEntry) setState(() => _visibleEntry = entry);
  }

  /// Salta al tramo de la entrada [i] del índice.
  void _jumpToEntry(int i) {
    final index = widget.index!;
    if (!_scroll.hasClients) return;
    final offset = index[i].itemIndex * GlassHymnList.rowHeight;
    _scroll.jumpTo(math.min(offset, _scroll.position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
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
          final playingHymnal = audio?.currentHymnal?.id;
          Widget row(int i) {
            final item = widget.items[i];
            final reorder = widget.onReorder != null;
            Widget child = GlassHymnRow(
              item: item,
              playing:
                  playing == item.number ||
                  (item.hymnalId != null &&
                      item.hymnalId == playingHymnal &&
                      audio?.isDismissing == false &&
                      audio?.currentHymn?.number == item.number),
              showDivider: i < widget.items.length - 1,
              trailing: reorder
                  ? ReorderableDragStartListener(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.drag_handle_rounded,
                          color: GlassTokens.of(context).textSecondary,
                        ),
                      ),
                    )
                  : widget.trailingBuilder?.call(i),
              onTap: () => widget.onTap(i),
            );
            if (reorder) {
              child = ReorderableDelayedDragStartListener(
                index: i,
                child: child,
              );
            }
            final onRemove = widget.onRemove;
            if (onRemove != null) {
              child = Dismissible(
                key: ValueKey(('remove', item.hymnalId, item.number)),
                direction: DismissDirection.endToStart,
                background: const _RemoveBackground(),
                confirmDismiss: widget.confirmRemove == null
                    ? null
                    : (_) async => await widget.confirmRemove!(i) ?? false,
                onDismissed: (_) => onRemove(i),
                child: child,
              );
            }
            return KeyedSubtree(
              key: ValueKey((item.hymnalId, item.number)),
              child: child,
            );
          }

          final onReorder = widget.onReorder;
          if (onReorder != null) {
            return ReorderableListView.builder(
              scrollController: _scroll,
              padding: widget.padding,
              itemCount: widget.items.length,
              itemExtent: GlassHymnList.rowHeight,
              buildDefaultDragHandles: false,
              onReorderItem: onReorder,
              proxyDecorator: (child, _, animation) =>
                  _DragProxy(animation: animation, child: child),
              itemBuilder: (context, i) => row(i),
            );
          }
          return ListView.builder(
            controller: _scroll,
            padding: widget.padding,
            itemCount: widget.items.length,
            itemExtent: GlassHymnList.rowHeight,
            itemBuilder: (context, i) => row(i),
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
        // Índice lateral: la misma barra del menú con la gota, girada, de
        // 34 dp. La lista avanza mientras se arrastra la gota.
        LayoutBuilder(
          builder: (context, constraints) {
            final height = math.min(
              constraints.maxHeight,
              index.length * GlassHymnList.indexSlot,
            );
            return SizedBox(
              width: GlassHymnList.indexWidth,
              height: height,
              child: Listener(
                onPointerDown: (_) => _indexDriving = true,
                onPointerUp: (_) => _indexDriving = false,
                onPointerCancel: (_) => _indexDriving = false,
                child: RotatedBox(
                  quarterTurns: 1,
                  child: LiquidGlassBlendGroup(
                    child: LoupeTabBar(
                      tabs: [
                        for (final e in index) BottomBarTab(label: e.label),
                      ],
                      selectedIndex: _visibleEntry.clamp(0, index.length - 1),
                      onHover: _jumpToEntry,
                      onSelected: (i) {
                        _visibleEntry = i;
                        _jumpToEntry(i);
                      },
                      height: GlassHymnList.indexWidth,
                      tint: GlassTokens.of(context).vivid,
                      restingDrop: true,
                      restingIconScale: 1.04,
                      labelFontSize: 10,
                      contentQuarterTurns: 3,
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

/// Fondo al deslizar para quitar: rojo con un ícono de borrar.
class _RemoveBackground extends StatelessWidget {
  const _RemoveBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: const Color(0xE6D93025),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
    );
  }
}

/// La fila que se arrastra: flota sobre una cápsula clara con sombra.
class _DragProxy extends StatelessWidget {
  const _DragProxy({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeOut.transform(animation.value);
        return Transform.scale(
          scale: 1 + .03 * t,
          child: Material(
            color: dark ? const Color(0xE61B2333) : const Color(0xF2FFFFFF),
            elevation: 8 * t,
            shadowColor: const Color(0x66000000),
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

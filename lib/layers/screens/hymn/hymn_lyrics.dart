import 'package:flutter/material.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
import 'package:hymnal_app/widgets/glass/lyrics_card.dart';

/// Una estrofa de la letra.
@immutable
class Stanza {
  const Stanza({required this.lines, this.number, this.header});

  /// Número de la estrofa ("1." en el texto), si lo tiene.
  final int? number;

  /// Encabezado sin número (p. ej. "Coro"), si lo tiene.
  final String? header;
  final List<String> lines;
}

/// Encabezados de coro en los cuatro idiomas.
final RegExp _chorusHeader = RegExp(
  r'^(coro|chorus|refrain|refr[aã]o|estribillo|припев)\s*:?$',
  caseSensitive: false,
  unicode: true,
);

/// Divide la letra en estrofas (separadas por una línea en blanco). La
/// línea "1." pasa a ser el número de la estrofa (se muestra en una
/// insignia y se quita del texto); "Coro" pasa a ser su encabezado.
List<Stanza> parseStanzas(String content) {
  final stanzas = <Stanza>[];
  for (final block in content.trim().split(RegExp(r'\n\s*\n'))) {
    final lines = block
        .split('\n')
        .map((l) => l.trimRight())
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) continue;
    final first = lines.first.trim();
    final numbered = RegExp(r'^(\d+)\.$').firstMatch(first);
    if (numbered != null) {
      stanzas.add(
        Stanza(number: int.parse(numbered[1]!), lines: lines.sublist(1)),
      );
    } else if (_chorusHeader.hasMatch(first)) {
      stanzas.add(Stanza(header: first, lines: lines.sublist(1)));
    } else {
      stanzas.add(Stanza(lines: lines));
    }
  }
  return stanzas;
}

/// Autores en una línea ("Letra: … · Música: …").
String? authorsLine(String? author) {
  final parts = (author ?? '')
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  return parts.isEmpty ? null : parts.join(' · ');
}

/// Tarjeta de letra del himno (lienzo, pantalla 3): etiqueta "HIMNO 1 ·
/// ADORACIÓN Y ALABANZA" en el color de acento, título en Literata,
/// autores y estrofas con una insignia tintada de 28 dp con su número.
/// El texto se puede seleccionar (copiar / compartir con [contextMenu]).
class HymnLyricsCard extends StatelessWidget {
  const HymnLyricsCard({
    required this.label,
    required this.title,
    required this.content,
    required this.layout,
    required this.userFontSize,
    this.author,
    this.onSelectionChanged,
    this.contextMenu,
    super.key,
  });

  final String label;
  final String title;
  final String content;
  final String? author;
  final HymnLayout layout;

  /// Tamaño de letra de Ajustes (escala solo la letra).
  final double userFontSize;
  final ValueChanged<String?>? onSelectionChanged;
  final SelectableRegionContextMenuBuilder? contextMenu;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final lyrics = GlassTypography.lyrics(
      layout,
      tokens.textPrimary,
      userFontSize: userFontSize,
    );
    final authors = authorsLine(author);
    final stanzas = parseStanzas(content);
    final badge = (lyrics.fontSize ?? 19) * 1.45;

    return LyricsCard(
      tablet: layout != HymnLayout.phone,
      child: SelectionArea(
        onSelectionChanged: (content) =>
            onSelectionChanged?.call(content?.plainText),
        contextMenuBuilder: contextMenu,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: GlassTypography.ui,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: .6,
                color: tokens.accent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GlassTypography.hymnTitle(layout, tokens.textPrimary),
            ),
            if (authors != null) ...[
              const SizedBox(height: 6),
              Text(
                authors,
                style: TextStyle(
                  fontFamily: GlassTypography.ui,
                  fontSize: 12,
                  color: tokens.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 18),
            for (final stanza in stanzas) ...[
              _StanzaView(stanza: stanza, style: lyrics, badgeSize: badge),
              SizedBox(height: (lyrics.fontSize ?? 19) * 1.1),
            ],
          ],
        ),
      ),
    );
  }
}

class _StanzaView extends StatelessWidget {
  const _StanzaView({
    required this.stanza,
    required this.style,
    required this.badgeSize,
  });

  final Stanza stanza;
  final TextStyle style;
  final double badgeSize;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final number = stanza.number;
    final header = stanza.header;
    final text = Text(stanza.lines.join('\n'), style: style);
    // Sin número: tal cual. El coro, con su encabezado, en cursiva y
    // sangrado.
    if (number == null) {
      if (header == null) return text;
      return Padding(
        padding: EdgeInsets.only(left: badgeSize * .6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              header,
              style: style.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: tokens.accent,
              ),
            ),
            Text(
              stanza.lines.join('\n'),
              style: style.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Insignia tintada con el número (no se selecciona como texto).
        SelectionContainer.disabled(
          child: Container(
            width: badgeSize,
            height: badgeSize,
            margin: EdgeInsets.only(right: badgeSize * .45),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tokens.buttonTint,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                fontFamily: GlassTypography.ui,
                fontSize: badgeSize * .5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Expanded(child: text),
      ],
    );
  }
}

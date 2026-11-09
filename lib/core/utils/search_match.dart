import 'dart:math' as math;

/// Coincidencias de búsqueda sin tildes ni mayúsculas, para resaltar lo
/// buscado en el texto **original** (con sus tildes).
abstract final class SearchMatch {
  static const _accents = 'áàâãäéèêëíìîïóòôõöúùûüçñё';
  static const _plain = 'aaaaaeeeeiiiiooooouuuucnе';

  /// Pliega [text] a minúsculas sin tildes **conservando la longitud**
  /// (un carácter por cada carácter), para que las posiciones de una
  /// coincidencia valgan también en el texto original.
  static String fold(String text) {
    final out = StringBuffer();
    for (final c in text.split('')) {
      var l = c.toLowerCase();
      if (l.length != 1) l = c; // p. ej. 'İ': no cambia la longitud
      final i = _accents.indexOf(l);
      out.write(i >= 0 ? _plain[i] : l);
    }
    return out.toString();
  }

  /// Rangos `(inicio, fin)` de todas las apariciones de [query] en [text],
  /// sin tildes ni mayúsculas y sin solaparse.
  static List<(int, int)> ranges(String text, String query) {
    final q = fold(query.trim().replaceAll(RegExp(r'\s+'), ' '));
    if (q.isEmpty) return const [];
    final t = fold(text);
    final found = <(int, int)>[];
    var from = 0;
    while (true) {
      final i = t.indexOf(q, from);
      if (i < 0) break;
      found.add((i, i + q.length));
      from = i + q.length;
    }
    return found;
  }

  /// Fragmento de [content] alrededor de la primera aparición de [query]
  /// (en una sola línea, con "…" si se recorta) y sus rangos resaltados.
  /// Sin coincidencia, el comienzo del texto.
  static ({String text, List<(int, int)> ranges}) snippet(
    String content,
    String query, {
    int radius = 40,
  }) {
    final flat = content.replaceAll(RegExp(r'\s'), ' ');
    final all = ranges(flat, query);
    if (all.isEmpty) {
      final end = math.min(flat.length, radius * 2);
      return (
        text: flat.substring(0, end).trim() + (end < flat.length ? '…' : ''),
        ranges: const [],
      );
    }
    final (first, firstEnd) = all.first;
    var start = math.max(0, first - radius);
    var end = math.min(flat.length, firstEnd + radius + radius ~/ 2);
    // Corta en un espacio para no partir palabras.
    if (start > 0) {
      final space = flat.indexOf(' ', start);
      if (space >= 0 && space < first) start = space + 1;
    }
    if (end < flat.length) {
      final space = flat.lastIndexOf(' ', end);
      if (space > firstEnd) end = space;
    }
    final prefix = start > 0 ? '…' : '';
    final suffix = end < flat.length ? '…' : '';
    final shift = prefix.length - start;
    return (
      text: prefix + flat.substring(start, end) + suffix,
      ranges: [
        for (final (s, e) in all)
          if (s >= start && e <= end) (s + shift, e + shift),
      ],
    );
  }
}

class StringUtils {
  /// Normalizes text for search purposes.
  /// 1. Converts to lowercase.
  /// 2. Removes accents/diacritics.
  /// 3. Removes punctuation and special characters.
  /// 4. Trims and collapses whitespaces.
  static String normalize(String text) {
    if (text.isEmpty) return '';

    // Convert to lowercase
    String normalized = text.toLowerCase();

    // Remove common accents/diacritics
    // (ё → е: en ruso suele escribirse sin los puntos).
    const accents = 'áàâãäéèêëíìîïóòôõöúùûüçñё';
    const without = 'aaaaaeeeeiiiiooooouuuucnе';
    for (int i = 0; i < accents.length; i++) {
      normalized = normalized.replaceAll(accents[i], without[i]);
    }

    // Remove punctuation and special characters
    // \p{L} matches any letter from any language
    // \p{N} matches any number
    // \s matches whitespace
    // We keep letters, numbers and spaces. Strip everything else.
    normalized = normalized.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '');

    // Collapse multiple spaces and trim
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalized;
  }
}

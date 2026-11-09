import 'package:flutter_test/flutter_test.dart';
import 'package:hymnal_app/core/utils/search_match.dart';
import 'package:hymnal_app/core/utils/string_utils.dart';
import 'package:hymnal_app/layers/data/repository/hymnal_repository.dart';
import 'package:hymnal_app/layers/domain/model/hymn.dart';
import 'package:hymnal_app/services/recent_searches_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Hymn _hymn(int number, String title, [String content = '']) => Hymn(
  number: number,
  title: title,
  content: content,
  normalizedTitle: StringUtils.normalize(title),
  normalizedContent: StringUtils.normalize(content),
);

void main() {
  group('Orden de resultados', () {
    test('el número exacto va primero, luego los que empiezan así', () {
      final hymns = [
        _hymn(12, 'Doce'),
        _hymn(112, 'Ciento doce'),
        _hymn(120, 'Ciento veinte'),
        _hymn(212, 'Doscientos doce'),
      ];
      final ranked = rankSearchResults(hymns, '12');
      expect(ranked.map((h) => h.number), [12, 120, 112, 212]);
    });

    test('título que empieza > título que contiene > letra', () {
      final hymns = [
        _hymn(1, 'Santo, santo, santo', 'Señor omnipotente'),
        _hymn(2, 'Alabad al Señor', ''),
        _hymn(3, 'Señor, mi Dios', ''),
      ];
      final ranked = rankSearchResults(hymns, 'senor');
      expect(ranked.map((h) => h.number), [3, 2, 1]);
    });
  });

  group('Sin tildes ni mayúsculas', () {
    test('normaliza español, portugués y ruso', () {
      expect(StringUtils.normalize('SEÑOR, ¡Canción!'), 'senor cancion');
      expect(StringUtils.normalize('Coração'), 'coracao');
      expect(StringUtils.normalize('Ёлка'), 'елка');
    });

    test('fold conserva la longitud para resaltar el original', () {
      const text = 'Cantad alegres al SEÑOR';
      expect(SearchMatch.fold(text).length, text.length);
      expect(SearchMatch.ranges(text, 'senor'), [(18, 23)]);
      expect(text.substring(18, 23), 'SEÑOR');
    });

    test('encuentra todas las apariciones', () {
      expect(SearchMatch.ranges('Santo, santo, SANTO', 'santo'), [
        (0, 5),
        (7, 12),
        (14, 19),
      ]);
      expect(SearchMatch.ranges('Hola', ''), isEmpty);
    });
  });

  group('Fragmento de la letra', () {
    test('recorta alrededor de la coincidencia y la marca', () {
      const content =
          '1.\nCantad alegres al Señor, mortales todos por doquier;\n'
          'servidle siempre con fervor, obedecedle con placer.';
      final s = SearchMatch.snippet(content, 'fervor', radius: 20);
      expect(s.text, contains('fervor'));
      expect(s.text, startsWith('…'));
      expect(s.text, isNot(contains('\n')));
      final (start, end) = s.ranges.single;
      expect(s.text.substring(start, end), 'fervor');
    });

    test('sin coincidencia muestra el comienzo', () {
      final s = SearchMatch.snippet('Una letra corta', 'xyz');
      expect(s.text, 'Una letra corta');
      expect(s.ranges, isEmpty);
    });
  });

  group('Búsquedas recientes', () {
    test('primero la más reciente, sin duplicados y con límite', () async {
      SharedPreferences.setMockInitialValues({});
      final recent = RecentSearchesService();
      await recent.add('gracia');
      await recent.add('Señor');
      await recent.add('GRACIA');
      expect(recent.items, ['GRACIA', 'Señor']);
      for (var i = 0; i < 10; i++) {
        await recent.add('búsqueda $i');
      }
      expect(recent.items.length, RecentSearchesService.limit);
      expect(recent.items.first, 'búsqueda 9');
      await recent.remove('búsqueda 9');
      expect(recent.items.first, 'búsqueda 8');

      // Se guardan.
      final reloaded = RecentSearchesService();
      await reloaded.load();
      expect(reloaded.items, recent.items);
    });
  });
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hymnal_app/services/background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    rootBundle.clear();
    SharedPreferences.setMockInitialValues({});
  });

  test('catálogo: el fondo inicial es el lago y cada foto existe', () async {
    final service = BackgroundService();
    await service.initialize();
    expect(service.backgrounds.length, greaterThanOrEqualTo(16));
    expect(service.current?.id, 'lake');
    for (final b in service.backgrounds) {
      await rootBundle.load(b.asset);
      await rootBundle.load(b.thumbAsset);
      expect(b.name('es'), isNotEmpty);
      expect(b.name('ru'), isNotEmpty);
    }
    // Las fotos de terceros llevan crédito.
    expect(service.backgrounds.where((b) => b.site == 'Freepik').length, 3);
    expect(service.current?.credit, 'Rafael Peier · Unsplash');
  });

  test('elegir se guarda; "siguiente" da la vuelta', () async {
    final service = BackgroundService();
    await service.initialize();
    final last = service.backgrounds.last;
    await service.select(last.id);
    expect(service.current?.id, last.id);
    await service.showNext();
    expect(service.current?.id, service.backgrounds.first.id);

    final again = BackgroundService();
    await again.initialize();
    expect(again.current?.id, service.backgrounds.first.id);
  });

  test('automático: al abrir avanza; cada himno solo en su modo', () async {
    SharedPreferences.setMockInitialValues({
      'background_selected': 'lake',
      'background_auto': true,
      'background_frequency': 'onOpen',
    });
    final service = BackgroundService();
    await service.initialize();
    expect(service.current?.id, isNot('lake'));

    final before = service.current?.id;
    service.onHymnShown();
    expect(service.current?.id, before);

    await service.setFrequency(BackgroundFrequency.perHymn);
    service.onHymnShown();
    await Future<void>.delayed(Duration.zero);
    expect(service.current?.id, isNot(before));
    service.dispose();
  });
}

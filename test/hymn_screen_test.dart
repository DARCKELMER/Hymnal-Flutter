import 'package:audio_service/audio_service.dart' as audio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_lyrics.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_screen.dart';
import 'package:hymnal_app/services/audio_handler.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/services/locator_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/theme.dart';
import 'package:hymnal_app/widgets/glass/glass_scope.dart';
import 'package:hymnal_app/widgets/glass/lyrics_card.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SilentAudio extends AudioService {
  _SilentAudio() : super.test();
}

void main() {
  group('Estrofas', () {
    test('el número pasa a la insignia y "Coro" a encabezado', () {
      final stanzas = parseStanzas(
        '1.\nCantad alegres al Señor,\nmortales todos\n\n'
        'Coro\nGloria a Dios\n\n2.\nCon gratitud\n',
      );
      expect(stanzas, hasLength(3));
      expect(stanzas[0].number, 1);
      expect(stanzas[0].lines.first, 'Cantad alegres al Señor,');
      expect(stanzas[1].number, isNull);
      expect(stanzas[1].header, 'Coro');
      expect(stanzas[1].lines, ['Gloria a Dios']);
      expect(stanzas[2].number, 2);
    });

    test('sin encabezado queda tal cual', () {
      final stanzas = parseStanzas('Santo, santo, santo\nSeñor Dios');
      expect(stanzas.single.number, isNull);
      expect(stanzas.single.header, isNull);
      expect(stanzas.single.lines, hasLength(2));
    });

    test('autores en una línea', () {
      expect(
        authorsLine('Letra: Tomás J. González\nMúsica: John Hatton'),
        'Letra: Tomás J. González · Música: John Hatton',
      );
      expect(authorsLine(null), isNull);
      expect(authorsLine('  '), isNull);
    });
  });

  setUp(() async {
    rootBundle.clear();
    SharedPreferences.setMockInitialValues({'selectedHymnal': 'es-newVersion'});
    PackageInfo.setMockInitialValues(
      appName: 'Himnario',
      packageName: 'test',
      version: '0',
      buildNumber: '0',
      buildSignature: '',
    );
    await GetIt.I.reset();
    setupLocator();
    GetIt.I.registerSingleton<audio.AudioHandler>(MyAudioHandler());
    GetIt.I.unregister<AudioService>();
    GetIt.I.registerSingleton<AudioService>(_SilentAudio());
  });

  testWidgets('Tarjeta de letra del lienzo y acciones', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => GetIt.I<SettingsService>().initialize());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GlassScope(
          tintAmount: 0,
          child: HymnScreen(
            hymnalId: 'es-newVersion',
            hymnNumber: 1,
            skipHistory: true,
          ),
        ),
      ),
    );
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(LyricsCard).evaluate().isNotEmpty) break;
    }
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(LyricsCard), findsWidgets);
    expect(find.text('HIMNO 1 · ADORACIÓN Y ALABANZA'), findsOneWidget);
    expect(find.text('Cantad alegres al Señor'), findsWidgets);
    expect(
      find.textContaining('Letra: Tomás J. González Carvajal · Música'),
      findsOneWidget,
    );
    // Estrofas con insignia: el "1." ya no está en el texto.
    expect(find.textContaining('1.\n'), findsNothing);
    expect(find.text('2'), findsWidgets);

    // Acciones de la cápsula.
    for (final label in [
      'Tamaño de fuente',
      'Agregar a favoritos',
      'Compartir',
    ]) {
      expect(find.semantics.byLabel(label), findsOne, reason: label);
    }
    tester.semantics.tap(find.semantics.byLabel('Agregar a favoritos'));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.semantics.byLabel('Quitar de favoritos'), findsOne);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}

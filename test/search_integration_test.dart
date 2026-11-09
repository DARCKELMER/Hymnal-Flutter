import 'package:audio_service/audio_service.dart' as audio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/screens/main_tabs_screen.dart';
import 'package:hymnal_app/layers/screens/search/search_panel.dart';
import 'package:hymnal_app/services/audio_handler.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/services/locator_service.dart';
import 'package:hymnal_app/services/recent_searches_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/theme.dart';
import 'package:hymnal_app/widgets/glass/glass_scope.dart';
import 'package:hymnal_app/widgets/glass/glass_tab_bar.dart';
import 'package:hymnal_app/widgets/glass/loupe_tab_bar/loupe_tab_bar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SilentAudio extends AudioService {
  _SilentAudio() : super.test();
}

void main() {
  setUp(() async {
    // rootBundle guarda los archivos cargados; una carga que quedó ligada al
    // tiempo simulado de la prueba anterior nunca terminaría en esta.
    rootBundle.clear();
    // Himnario en español (si no, se elige por el idioma del sistema de
    // pruebas, que es inglés).
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

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => GetIt.I<SettingsService>().initialize());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GlassScope(tintAmount: .1, child: MainTabsScreen()),
      ),
    );
    await tester.pump();
  }

  /// Avanza hasta que terminen las búsquedas (assets reales, que tardan
  /// más con la suite completa en marcha): hasta que aparezca el encabezado
  /// con la cantidad de himnos, con un límite.
  Future<void> settleSearch(WidgetTester tester) async {
    final header = find.textContaining(RegExp(r'^[1-9]\d* HIMNOS?$'));
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (i > 2 && header.evaluate().isNotEmpty) break;
    }
    await tester.pump();
  }

  Finder tabSearch() => find.descendant(
    of: find.byType(GlassTabBar),
    matching: find.bySemanticsLabel('Buscar'),
  );

  double collapse(WidgetTester tester) =>
      tester.widget<LoupeTabBar>(find.byType(LoupeTabBar)).collapse;

  testWidgets('La lupa se transforma en campo, busca y vuelve a la barra', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byType(SearchPanel), findsNothing);
    expect(collapse(tester), 0);

    // Abrir: barra en círculo, campo y panel de resultados.
    await tester.tap(tabSearch());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(collapse(tester), closeTo(1, .01));
    expect(find.byType(SearchPanel), findsOneWidget);
    final field = find.descendant(
      of: find.byType(GlassTabBar),
      matching: find.byType(TextField),
    );
    expect(field, findsOneWidget);
    // Sin búsquedas recientes: la ayuda.
    expect(find.text('Busca por número, título o letra'), findsOneWidget);

    // Buscar "12": el himno 12 primero.
    await tester.enterText(field, '12');
    await settleSearch(tester);
    final first = find
        .descendant(
          of: find.byType(SearchPanel),
          matching: find.bySemanticsLabel(RegExp(r'^\d+\. ')),
        )
        .first;
    expect(tester.getSemantics(first).label, startsWith('12. '));

    // Cerrar con la ✕ de la barra: vuelve la barra y se va el panel.
    await tester.tap(
      find
          .descendant(
            of: find.byType(GlassTabBar),
            matching: find.bySemanticsLabel('Cancelar'),
          )
          .last,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(collapse(tester), closeTo(0, .01));
    expect(find.byType(SearchPanel), findsNothing);
  });

  testWidgets('Sin tildes, resalta lo buscado y recuerda la búsqueda', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(tabSearch());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final field = find.descendant(
      of: find.byType(GlassTabBar),
      matching: find.byType(TextField),
    );

    await tester.enterText(field, 'senor');
    await settleSearch(tester);
    // "senor" encuentra "Señor" (con tilde).
    expect(
      find.descendant(
        of: find.byType(SearchPanel),
        matching: find.textContaining('Señor', findRichText: true),
      ),
      findsWidgets,
    );

    // Atrás (Android) cierra la búsqueda.
    final popped = await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(popped, isTrue);
    expect(find.byType(SearchPanel), findsNothing);
  });

  testWidgets('Las búsquedas recientes aparecen con el campo vacío', (
    tester,
  ) async {
    await GetIt.I<RecentSearchesService>().add('gracia');
    await pumpApp(tester);
    await tester.tap(tabSearch());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('BÚSQUEDAS RECIENTES'), findsOneWidget);
    expect(find.text('gracia'), findsOneWidget);

    // Tocarla la vuelve a buscar.
    await tester.tap(find.text('gracia'));
    await settleSearch(tester);
    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byType(GlassTabBar),
        matching: find.byType(TextField),
      ),
    );
    expect(field.controller!.text, 'gracia');
  });
}

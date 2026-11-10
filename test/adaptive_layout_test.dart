import 'package:audio_service/audio_service.dart' as audio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/core/layout/window_class.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_screen.dart';
import 'package:hymnal_app/layers/screens/main_tabs_screen.dart';
import 'package:hymnal_app/layers/screens/search/search_panel.dart';
import 'package:hymnal_app/services/audio_handler.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/services/locator_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/theme.dart';
import 'package:hymnal_app/widgets/glass/glass_icon_button.dart';
import 'package:hymnal_app/widgets/glass/glass_navigation_rail.dart';
import 'package:hymnal_app/widgets/glass/glass_scope.dart';
import 'package:hymnal_app/widgets/glass/glass_tab_bar.dart';
import 'package:hymnal_app/widgets/glass/loupe_tab_bar/loupe_tab_bar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SilentAudio extends AudioService {
  _SilentAudio() : super.test();
}

void main() {
  group('WindowClass', () {
    test('clasifica por el ancho (y el alto) de la ventana', () {
      expect(WindowClass.fromSize(const Size(390, 844)), WindowClass.compact);
      // Pantalla dividida en tableta: compacta.
      expect(WindowClass.fromSize(const Size(500, 1100)), WindowClass.compact);
      expect(WindowClass.fromSize(const Size(700, 1000)), WindowClass.medium);
      // Celular girado: ancho, pero bajo.
      expect(WindowClass.fromSize(const Size(891, 411)), WindowClass.medium);
      expect(WindowClass.fromSize(const Size(1200, 900)), WindowClass.expanded);
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

  Future<void> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
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

  Future<void> settle(WidgetTester tester, Finder until) async {
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (i > 2 && until.evaluate().isNotEmpty) break;
    }
    await tester.pump();
  }

  testWidgets('Compacta: barra inferior, sin barra lateral', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    expect(find.byType(LoupeTabBar), findsOneWidget);
    expect(find.byType(GlassNavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mediana: barra lateral y una columna de 600 dp como máximo', (
    tester,
  ) async {
    await pumpApp(tester, const Size(800, 1000));
    expect(find.byType(GlassNavigationRail), findsOneWidget);
    // Sin barra de pestañas abajo (la de la barra lateral es la misma
    // barra, girada).
    expect(
      find.descendant(
        of: find.byType(GlassTabBar),
        matching: find.byType(LoupeTabBar),
      ),
      findsNothing,
    );
    expect(find.bySemanticsLabel('Historial'), findsWidgets);
    // Historial es un destino de la barra lateral.
    await tester.tap(
      find.descendant(
        of: find.byType(GlassNavigationRail),
        matching: find.bySemanticsLabel('Historial'),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Celular girado: la barra lateral cabe sin desbordarse', (
    tester,
  ) async {
    await pumpApp(tester, const Size(891, 411));
    expect(find.byType(GlassNavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Expandida: el himno se abre a la derecha sin navegar, y al '
      'pasar a compacta se abre como pantalla', (tester) async {
    await pumpApp(tester, const Size(1200, 900));
    expect(find.byType(GlassNavigationRail), findsOneWidget);
    expect(find.text('Elige un himno de la lista'), findsOneWidget);

    // Buscar "12" con la lupa de la barra lateral y abrir el resultado.
    await tester.tap(
      find.ancestor(
        of: find.byIcon(Icons.search_rounded),
        matching: find.byType(GlassIconButton),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final field = find.descendant(
      of: find.byType(GlassTabBar),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, '12');
    await settle(tester, find.textContaining(RegExp(r'^[1-9]\d* HIMNOS?$')));
    await tester.tap(
      find
          .descendant(
            of: find.byType(SearchPanel),
            matching: find.bySemanticsLabel(RegExp(r'^12\. ')),
          )
          .first,
    );
    await settle(tester, find.byType(HymnScreen));
    expect(find.byType(HymnScreen), findsOneWidget);
    // Sin navegar: la pantalla principal sigue siendo la única ruta.
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    expect(navigator.canPop(), isFalse);

    // A compacta (p. ej. pantalla dividida): el himno se abre como
    // pantalla normal.
    tester.view.physicalSize = const Size(390, 844) * 2;
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LoupeTabBar, skipOffstage: false), findsOneWidget);
    // Se abrió como pantalla encima (puede seguir en su transición).
    expect(navigator.canPop(), isTrue);
    expect(find.byType(HymnScreen, skipOffstage: false), findsOneWidget);

    // Deja terminar los temporizadores de la pantalla del himno.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}

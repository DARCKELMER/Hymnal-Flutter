import 'package:audio_service/audio_service.dart' as audio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_screen.dart';
import 'package:hymnal_app/layers/screens/main_tabs_screen.dart';
import 'package:hymnal_app/services/audio_handler.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/services/history_service.dart';
import 'package:hymnal_app/services/locator_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/theme.dart';
import 'package:hymnal_app/widgets/glass/glass_scope.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SilentAudio extends AudioService {
  _SilentAudio() : super.test();
}

void main() {
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

  Future<void> pumpHome(WidgetTester tester) async {
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
        home: const GlassScope(tintAmount: 0, child: MainTabsScreen()),
      ),
    );
    // Carga los himnos (assets reales) para la vista previa.
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (find.textContaining('himnos').evaluate().isNotEmpty) break;
    }
  }

  Future<void> press(WidgetTester tester, String label) async {
    tester.semantics.tap(find.semantics.byLabel(label));
    await tester.pump();
  }

  testWidgets('Encabezado, himnario y teclado del lienzo', (tester) async {
    await pumpHome(tester);
    expect(find.text('Himnario Adventista'), findsOneWidget);
    expect(find.text('Inicio'), findsWidgets);
    // "Español · 614 himnos" (detalle + cantidad).
    expect(find.textContaining('himnos'), findsOneWidget);
    for (final k in ['0', '1', '9', 'Borrar número', 'Borrar último dígito']) {
      expect(find.semantics.byLabel(k), findsOne, reason: k);
    }
    // Sin campo de texto: no aparece el teclado del sistema.
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Vista previa en tiempo real y "No existe"', (tester) async {
    await pumpHome(tester);
    await press(tester, '1');
    expect(find.text('Cantad alegres al Señor'), findsOneWidget);

    // 1 → 19 → 199 → 1999: no existe.
    await press(tester, '9');
    await press(tester, '9');
    await press(tester, '9');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No existe'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Abrir Himno')),
      matchesSemantics(
        label: 'Abrir Himno',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );

    // Retroceso hasta "1" y Borrar.
    await press(tester, 'Borrar último dígito');
    await press(tester, 'Borrar último dígito');
    await press(tester, 'Borrar último dígito');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Cantad alegres al Señor'), findsOneWidget);
    await press(tester, 'Borrar número');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Cantad alegres al Señor'), findsNothing);
  });

  testWidgets('"Abrir himno" lo abre y lo guarda en el historial', (
    tester,
  ) async {
    await pumpHome(tester);
    await press(tester, '1');
    await press(tester, '2');
    expect(find.text('Todos juntos reunidos'), findsOneWidget);
    tester.semantics.tap(find.semantics.byLabel('Abrir Himno'));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(HymnScreen, skipOffstage: false), findsOneWidget);
    expect(GetIt.I<HistoryService>().history.first.hymnNumber, 12);

    // Deja terminar los temporizadores de la pantalla del himno.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}

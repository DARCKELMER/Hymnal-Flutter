import 'package:audio_service/audio_service.dart' as audio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/screens/settings/settings_screen.dart';
import 'package:hymnal_app/services/audio_handler.dart';
import 'package:hymnal_app/services/locator_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/theme.dart';
import 'package:hymnal_app/widgets/glass/glass_scope.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    rootBundle.clear();
    SharedPreferences.setMockInitialValues({'selectedHymnal': 'es-newVersion'});
    PackageInfo.setMockInitialValues(
      appName: 'Himnario',
      packageName: 'test',
      version: '2.0',
      buildNumber: '7',
      buildSignature: '',
    );
    await GetIt.I.reset();
    setupLocator();
    GetIt.I.registerSingleton<audio.AudioHandler>(MyAudioHandler());
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('Ajustes del lienzo: secciones, tema, interruptor y créditos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final settings = GetIt.I<SettingsService>();
    await tester.runAsync(settings.initialize);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GlassScope(
          tintAmount: 0,
          child: Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('FONDO'), findsOneWidget);
    expect(find.text('APARIENCIA'), findsOneWidget);
    expect(find.text('Imagen de fondo'), findsOneWidget);
    expect(find.textContaining('Nueva Versión 2009 ·'), findsOneWidget);

    // Tema con la gota: Oscuro.
    await tester.tap(find.text('Oscuro').first);
    await settle(tester);
    expect(settings.themeMode, 'dark');

    // Interruptor de imagen de fondo (toda la fila responde).
    final before = settings.showBackgroundImage;
    await tester.tap(find.text('Imagen de fondo'));
    await settle(tester);
    expect(settings.showBackgroundImage, !before);

    // Créditos (al final de la lista).
    await tester.drag(find.text('FONDO'), const Offset(0, -500));
    await settle(tester);
    await tester.ensureVisible(find.text('Créditos'));
    await settle(tester);
    expect(find.text('2.0 (7)'), findsOneWidget);
    await tester.tap(find.text('Créditos'));
    await settle(tester);
    expect(find.textContaining('GoGoShift'), findsOneWidget);

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}

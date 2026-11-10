import 'package:audio_service/audio_service.dart' as audio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/data/repository/hymnal_repository.dart';
import 'package:hymnal_app/layers/domain/model/hymnal.dart';
import 'package:hymnal_app/layers/screens/sheets/sheets_screen.dart';
import 'package:hymnal_app/services/audio_handler.dart';
import 'package:hymnal_app/services/audio_service.dart';
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
      version: '0',
      buildNumber: '0',
      buildSignature: '',
    );
    await GetIt.I.reset();
    setupLocator();
    GetIt.I.registerSingleton<audio.AudioHandler>(MyAudioHandler());
    GetIt.I.unregister<AudioService>();
    GetIt.I.registerSingleton<AudioService>(AudioService.test());
  });

  Future<void> pumpSheets(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.runAsync(GetIt.I<SettingsService>().initialize);
    final hymnals = await tester.runAsync(
      () => GetIt.I<HymnalRepository>().getHymnals(),
    );
    final hymnal = hymnals!.firstWhere((Hymnal h) => h.id == 'es-newVersion');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GlassScope(
          tintAmount: 0,
          child: SheetsScreen(hymnal: hymnal, hymnNumber: 1),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Cantad alegres al Señor').evaluate().isNotEmpty) break;
    }
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('Partitura en celular: encabezado del lienzo', (tester) async {
    await pumpSheets(tester, const Size(390, 844));
    expect(find.text('PARTITURA · HIMNO 1'), findsOneWidget);
    expect(find.text('Cantad alegres al Señor'), findsOneWidget);
    expect(find.semantics.byLabel('Acercar'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('Partitura en tableta: zoom en el encabezado', (tester) async {
    await pumpSheets(tester, const Size(1280, 800));
    expect(find.text('PARTITURA · HIMNO 1'), findsOneWidget);
    expect(find.semantics.byLabel('Acercar'), findsOne);
    expect(find.text('100 %'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}

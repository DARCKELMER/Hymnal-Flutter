import 'package:audio_service/audio_service.dart' as audio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/screens/lists/ambit_screen.dart';
import 'package:hymnal_app/layers/screens/main_tabs_screen.dart';
import 'package:hymnal_app/services/audio_handler.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/services/locator_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/theme.dart';
import 'package:hymnal_app/widgets/glass/glass_hymn_list.dart';
import 'package:hymnal_app/widgets/glass/glass_scope.dart';
import 'package:hymnal_app/widgets/glass/loupe_tab_bar/loupe_tab_bar.dart';
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

  Future<void> settle(WidgetTester tester, Finder until) async {
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (i > 2 && until.evaluate().isNotEmpty) break;
    }
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> pumpLists(WidgetTester tester) async {
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
    await tester.pump();
    // Pestaña "Listas" (segunda de cuatro).
    final bar = tester.getRect(find.byType(LoupeTabBar));
    await tester.tapAt(Offset(bar.left + bar.width * .375, bar.center.dy));
    // (Sin pumpAndSettle: el indicador de carga gira hasta leer los himnos.)
    await tester.pump(const Duration(seconds: 1));
    await settle(tester, find.byType(GlassHymnList));
  }

  testWidgets('Numérico: filas con insignia e índice lateral 1, 100 … 600', (
    tester,
  ) async {
    await pumpLists(tester);
    expect(find.byType(GlassHymnList), findsOneWidget);
    expect(find.text('Cantad alegres al Señor'), findsOneWidget);
    for (final label in ['1', '100', '300', '600']) {
      expect(
        find.descendant(
          of: find.byType(GlassHymnList),
          matching: find.text(label),
        ),
        findsWidgets,
        reason: label,
      );
    }

    // Tocar "300" en el índice salta a ese himno.
    final indexLabel = find
        .descendant(of: find.byType(GlassHymnList), matching: find.text('300'))
        .last;
    await tester.tap(indexLabel);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel(RegExp(r'^300\. ')), findsOneWidget);
    expect(find.text('Cantad alegres al Señor'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Alfabético y temático con secciones', (tester) async {
    await pumpLists(tester);
    tester.semantics.tap(find.semantics.byLabel('Alfabético'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // Índice de letras.
    expect(
      find.descendant(of: find.byType(GlassHymnList), matching: find.text('A')),
      findsWidgets,
    );

    tester.semantics.tap(find.semantics.byLabel('Temático'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('secciones'), findsWidgets);

    // Abrir el primer tema y su primera sección.
    final firstTheme = find.semantics.byPredicate(
      (n) => n.getSemanticsData().label.contains('secciones'),
    );
    tester.semantics.tap(firstTheme.first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final section = find.semantics.byPredicate(
      (n) => RegExp(r'Himnos \d+-\d+$').hasMatch(n.getSemanticsData().label),
    );
    expect(section, findsWidgets);
    tester.semantics.tap(section.first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(AmbitScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'package:audio_service/audio_service.dart' as audio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/screens/favorites/favorites_screen.dart';
import 'package:hymnal_app/layers/screens/history/history_screen.dart';
import 'package:hymnal_app/services/audio_handler.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/services/favorites_service.dart';
import 'package:hymnal_app/services/history_service.dart';
import 'package:hymnal_app/services/locator_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/theme.dart';
import 'package:hymnal_app/widgets/glass/glass_hymn_list.dart';
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

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 14; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.runAsync(GetIt.I<SettingsService>().initialize);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GlassScope(tintAmount: 0, child: Scaffold(body: screen)),
      ),
    );
    await settle(tester);
  }

  List<int> numbers() =>
      GetIt.I<FavoritesService>().favorites.map((f) => f.hymnNumber).toList();

  testWidgets('Favoritos: vacío, reordenar arrastrando y quitar deslizando', (
    tester,
  ) async {
    final favorites = GetIt.I<FavoritesService>();
    await pump(tester, const FavoritesScreen());
    expect(find.text('Favoritos'), findsOneWidget);
    expect(find.byType(GlassHymnList), findsNothing);

    await tester.runAsync(() async {
      await favorites.addFavorite('es-newVersion', 1, 'Cantad alegres');
      await favorites.addFavorite('es-newVersion', 2, 'Da gloria');
      await favorites.addFavorite('es-newVersion', 3, 'Unidos');
    });
    await settle(tester);
    expect(find.byType(GlassHymnRow), findsNWidgets(3));
    final before = numbers();

    // Arrastrar la primera fila por su asa dos filas abajo.
    final handle = find.byIcon(Icons.drag_handle_rounded).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await settle(tester);
    final after = numbers();
    expect(after.first, isNot(before.first));
    expect(after.toSet(), before.toSet());

    // Quitar deslizando a la izquierda, con confirmación.
    await tester.drag(find.byType(GlassHymnRow).first, const Offset(-300, 0));
    await settle(tester);
    expect(find.text('Quitar Favorito'), findsOneWidget);
    await tester.tap(find.text('Quitar'));
    await settle(tester);
    expect(numbers(), hasLength(2));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('Historial: filas con himnario y fecha', (tester) async {
    await tester.runAsync(
      () => GetIt.I<HistoryService>().addToHistory(
        'es-newVersion',
        1,
        'Cantad alegres al Señor',
      ),
    );
    await pump(tester, const HistoryScreen());
    expect(find.text('Historial'), findsOneWidget);
    expect(find.text('Cantad alegres al Señor'), findsOneWidget);
    expect(find.textContaining('Nueva Versión 2009 ·'), findsOneWidget);
    expect(find.semantics.byLabel('Borrar historial'), findsOne);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}

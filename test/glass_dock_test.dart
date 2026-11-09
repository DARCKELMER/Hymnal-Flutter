import 'package:audio_service/audio_service.dart' as audio;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/domain/model/hymn.dart';
import 'package:hymnal_app/layers/domain/model/hymnal.dart';
import 'package:hymnal_app/services/audio_handler.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/services/locator_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/theme.dart';
import 'package:hymnal_app/widgets/app_scaffold.dart';
import 'package:hymnal_app/widgets/glass/glass_tab_bar.dart';
import 'package:hymnal_app/widgets/glass/liquid_mini_player.dart';
import 'package:hymnal_app/widgets/glass/loupe_tab_bar/loupe_tab_bar.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Audio simulado: permite fijar el himno, la reproducción y el cierre.
class FakeAudioService extends AudioService {
  FakeAudioService() : super.test();

  Hymn? hymn;
  Hymnal? hymnal;
  bool playing = false;
  bool dismissing = false;
  int finalized = 0;
  int stops = 0;
  double speedValue = 1;

  @override
  Hymn? get currentHymn => hymn;
  @override
  Hymnal? get currentHymnal => hymnal;
  @override
  bool get isPlaying => playing;
  @override
  bool get isLoading => false;
  @override
  bool get isDismissing => dismissing;
  @override
  Duration get duration => const Duration(minutes: 3);
  @override
  Duration get position => const Duration(seconds: 45);
  @override
  double get speed => speedValue;

  void startHymn() {
    hymn = Hymn(
      number: 1,
      title: 'Cantad alegres al Señor',
      content: '',
      normalizedTitle: 'cantad alegres al senor',
      normalizedContent: '',
    );
    hymnal = const Hymnal(
      id: 'test',
      name: 'Himnario',
      detail: '',
      year: 2010,
      twoLetterIsoLanguageName: 'es',
      hymnsFileName: '',
      thematicHymnsFileName: '',
    );
    playing = true;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    stops++;
    dismissing = true;
    playing = false;
    notifyListeners();
  }

  @override
  void finalizeDismiss() {
    finalized++;
    dismissing = false;
    hymn = null;
    hymnal = null;
    notifyListeners();
  }

  @override
  Future<String?> versionUrl({required bool instrumental}) async => null;

  @override
  Future<void> setSpeed(double speed) async {
    speedValue = speed;
    notifyListeners();
  }
}

void main() {
  late FakeAudioService fakeAudio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    setupLocator();
    GetIt.I.registerSingleton<audio.AudioHandler>(MyAudioHandler());
    GetIt.I.unregister<AudioService>();
    fakeAudio = FakeAudioService();
    GetIt.I.registerSingleton<AudioService>(fakeAudio);
  });

  Future<void> pumpTabs(WidgetTester tester, {ValueChanged<int>? onTab}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    var index = 0;
    var searches = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatefulBuilder(
          builder: (context, setState) => AppScaffold(
            body: const SizedBox.expand(),
            tabBar: GlassTabBar(
              tabs: const [
                BottomBarTab(icon: Icons.home, label: 'Inicio'),
                BottomBarTab(icon: Icons.list, label: 'Listas'),
                BottomBarTab(icon: Icons.favorite, label: 'Favoritos'),
                BottomBarTab(icon: Icons.settings, label: 'Ajustes'),
              ],
              selectedIndex: index,
              onSelected: (i) {
                setState(() => index = i);
                onTab?.call(i);
              },
              onSearch: () => searches++,
              searchLabel: 'Buscar',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Sin himno, la barra queda abajo del todo y el reproductor '
      'no ocupa espacio', (tester) async {
    await pumpTabs(tester);
    final mini = find.byType(LiquidMiniPlayer);
    expect(mini, findsOneWidget); // montado (constante), pero plegado
    expect(tester.getSize(mini).height, 0);
    expect(find.semantics.byLabel('Pausa'), findsNothing);
    // Un solo layer para la zona inferior (más la gota de la barra).
    expect(find.byType(LiquidGlassLayer), findsNWidgets(2));
  });

  testWidgets('Al sonar un himno brota de la barra; al cerrarlo se funde y '
      'libera el himno', (tester) async {
    await pumpTabs(tester);
    final mini = find.byType(LiquidMiniPlayer);
    final barTop = tester.getTopLeft(find.byType(GlassTabBar)).dy;

    fakeAudio.startHymn();
    await tester.pump();
    var maxBlend = 0.0;
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final blend = tester
          .widget<LiquidGlassBlendGroup>(find.byType(LiquidGlassBlendGroup))
          .blend;
      if (blend > maxBlend) maxBlend = blend;
    }
    expect(maxBlend, greaterThan(10), reason: 'se mezcla con la barra');
    expect(tester.getSize(mini).height, closeTo(60, .5));
    // La barra no se mueve: el reproductor crece hacia arriba.
    expect(tester.getTopLeft(find.byType(GlassTabBar)).dy, closeTo(barTop, .5));
    expect(find.semantics.byLabel('Pausa'), findsOne);
    expect(find.text('Cantad alegres al Señor'), findsOneWidget);

    // Deslizar hacia abajo: se cierra, se funde y libera el himno.
    await tester.drag(mini, const Offset(0, 120));
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(fakeAudio.stops, 1);
    expect(fakeAudio.finalized, 1);
    expect(tester.getSize(mini).height, 0);
    expect(find.semantics.byLabel('Pausa'), findsNothing);
  });

  testWidgets('La barra de cristal cambia de pestaña y la lupa busca', (
    tester,
  ) async {
    final tabs = <int>[];
    await pumpTabs(tester, onTab: tabs.add);
    final bar = tester.getRect(find.byType(LoupeTabBar));
    await tester.tapAt(Offset(bar.left + bar.width * .625, bar.center.dy));
    await tester.pumpAndSettle();
    expect(tabs, [2]);
    expect(find.bySemanticsLabel('Buscar'), findsOneWidget);
  });

  testWidgets('El panel real trae velocidad, versiones y letra', (
    tester,
  ) async {
    await pumpTabs(tester);
    fakeAudio.startHymn();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    SemanticsFinder withAction(String label) {
      final id = CustomSemanticsAction.getIdentifier(
        CustomSemanticsAction(label: label),
      );
      return find.semantics.byPredicate(
        (n) =>
            n.getSemanticsData().customSemanticsActionIds?.contains(id) ??
            false,
      );
    }

    tester.semantics.customAction(
      withAction('Mostrar ajustes'),
      const CustomSemanticsAction(label: 'Mostrar ajustes'),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    for (final label in [
      'Instrumental',
      'Cantado',
      'Reproducción continua',
      'Ver letra',
      'Velocidad 2×',
    ]) {
      expect(find.semantics.byLabel(label), findsOne, reason: label);
    }
    tester.semantics.tap(find.semantics.byLabel('Velocidad 2×'));
    await tester.pump();
    expect(fakeAudio.speedValue, 2);
    // Sin URL de la otra versión, su botón queda deshabilitado.
    expect(
      find.semantics.byPredicate((n) {
        final d = n.getSemanticsData();
        return d.label == 'Cantado' &&
            d.flagsCollection.isEnabled.toBoolOrNull() == false;
      }),
      findsOne,
    );
  });

  test('El ajuste "Cristal" se guarda en el servicio', () async {
    final settings = GetIt.I<SettingsService>();
    await settings.setGlassTint(.7);
    expect(settings.glassTint, .7);
  });
}

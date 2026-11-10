import 'package:audio_service/audio_service.dart' as audio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/domain/model/hymn.dart';
import 'package:hymnal_app/layers/domain/model/hymnal.dart';
import 'package:hymnal_app/layers/screens/player/player_screen.dart';
import 'package:hymnal_app/services/audio_handler.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/services/locator_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/theme.dart';
import 'package:hymnal_app/widgets/glass/glass_scope.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Audio simulado: el himno 1 sonando en la versión instrumental.
class _FakeAudio extends AudioService {
  _FakeAudio() : super.test();

  double speedValue = 1;
  bool continuous = false;
  bool playing = true;

  @override
  Hymn? get currentHymn => Hymn(
    number: 1,
    title: 'Cantad alegres al Señor',
    content: '',
    normalizedTitle: 'cantad alegres al senor',
    normalizedContent: '',
  );
  @override
  Hymnal? get currentHymnal => const Hymnal(
    id: 'es-newVersion',
    name: 'Nueva Versión 2009',
    detail: '',
    year: 2009,
    twoLetterIsoLanguageName: 'es',
    hymnsFileName: '',
    thematicHymnsFileName: '',
  );
  @override
  bool get isPlaying => playing;
  @override
  bool get isInstrumental => true;
  @override
  bool get continuousPlay => continuous;
  @override
  Duration get duration => const Duration(minutes: 2, seconds: 23);
  @override
  Duration get position => const Duration(seconds: 42);
  @override
  double get speed => speedValue;
  @override
  Future<String?> versionUrl({required bool instrumental}) async => 'x';
  @override
  Future<void> setSpeed(double speed) async {
    speedValue = speed;
    notifyListeners();
  }

  @override
  void toggleContinuousPlay() {
    continuous = !continuous;
    notifyListeners();
  }

  @override
  Future<void> togglePlayPause() async {
    playing = !playing;
    notifyListeners();
  }
}

void main() {
  late _FakeAudio fake;

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
    fake = _FakeAudio();
    GetIt.I.registerSingleton<AudioService>(fake);
  });

  Future<void> pumpPlayer(WidgetTester tester, Size size) async {
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
        home: GlassScope(
          tintAmount: 0,
          child: PlayerScreen(onClose: () {}, onOpenLyrics: () {}),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (find.textContaining('Da gloria').evaluate().isNotEmpty) break;
    }
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('Reproductor del lienzo en celular', (tester) async {
    await pumpPlayer(tester, const Size(390, 844));

    expect(find.text('Reproduciendo ahora'), findsOneWidget);
    expect(find.text('Cantad alegres al Señor'), findsOneWidget);
    expect(find.text('Adoración y alabanza · Instrumental'), findsOneWidget);
    expect(find.text('0:42'), findsOneWidget);
    expect(find.text('-1:41'), findsOneWidget);
    expect(find.text('A CONTINUACIÓN'), findsOneWidget);
    expect(find.text('2 · Da gloria al Señor'), findsOneWidget);

    // Velocidad 1× → 2×; reproducción continua.
    tester.semantics.tap(find.semantics.byLabel('Velocidad 1×'));
    await settle(tester);
    expect(fake.speedValue, 2);
    tester.semantics.tap(find.semantics.byLabel('Reproducción continua'));
    await settle(tester);
    expect(fake.continuous, isTrue);

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('Reproductor en tableta horizontal sin desbordes', (
    tester,
  ) async {
    await pumpPlayer(tester, const Size(1280, 800));
    expect(find.text('Cantad alegres al Señor'), findsOneWidget);
    expect(find.text('2 · Da gloria al Señor'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}

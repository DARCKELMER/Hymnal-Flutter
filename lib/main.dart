import 'package:flutter/material.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/layers/data/repository/remote_settings_repository.dart';
import 'package:hymnal_app/services/locator_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/theme.dart';
import 'package:hymnal_app/layers/screens/main_tabs_screen.dart';
import 'package:audio_service/audio_service.dart';
import 'package:hymnal_app/services/audio_handler.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Precarga los shaders de Liquid Glass antes de `runApp`.
///
/// Evita que el primer cristal se pinte como FakeGlass durante uno o dos
/// cuadros, a cambio de un arranque algo más lento. Se deja detrás de una
/// constante para medir con y sin ella.
const bool kPrecacheLiquidGlass = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kPrecacheLiquidGlass) {
    await LiquidGlass.precache();
  }

  setupLocator();

  // Pre-fetch remote settings (non-blocking — app launches even if offline)
  GetIt.I<RemoteSettingsRepository>().fetchSettings().ignore();

  final settingsService = GetIt.I<SettingsService>();
  await settingsService.initialize();

  // Initialize background audio service
  final audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.isax5.hymnal.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  GetIt.I.registerSingleton<AudioHandler>(audioHandler);

  runApp(const HymnalApp());
}

class HymnalApp extends StatelessWidget {
  const HymnalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = GetIt.I<SettingsService>();

    return AnimatedBuilder(
      animation: settingsService,
      builder: (context, child) {
        ThemeMode themeMode;
        switch (settingsService.themeMode) {
          case 'light':
            themeMode = ThemeMode.light;
            break;
          case 'dark':
            themeMode = ThemeMode.dark;
            break;
          default:
            themeMode = ThemeMode.system;
        }

        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MainTabsScreen(),
        );
      },
    );
  }
}

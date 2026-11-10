import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hymnal_app/layers/data/repository/settings_repository.dart';
import 'package:hymnal_app/styles/glass/glass_settings.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
import 'package:hymnal_app/styles/theme.dart';
import 'package:hymnal_app/widgets/glass/glass_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Tokens', () {
    testWidgets('el tema claro y el oscuro traen sus tokens', (tester) async {
      late GlassTokens light;
      late GlassTokens dark;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              light = GlassTokens.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        // Otra clave: sin la transición animada entre temas.
        MaterialApp(
          key: const ValueKey('oscuro'),
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) {
              dark = GlassTokens.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(light.textPrimary, const Color(0xFF0E1A2B));
      expect(light.accent, const Color(0xFF1F4FD1));
      expect(light.buttonTint.a, closeTo(.84, .01));
      expect(light.selected.a, closeTo(.58, .01));
      expect(dark.textPrimary, const Color(0xFFF2F5FA));
      expect(dark.accent, const Color(0xFFA9C1FF));
      expect(dark.buttonTint.a, closeTo(.82, .01));
      expect(dark.favorite, const Color(0xFFFDBA74));
    });

    test('lerp mezcla los colores', () {
      final mid = GlassTokens.light.lerp(GlassTokens.dark, .5);
      expect(mid.textPrimary, isNot(GlassTokens.light.textPrimary));
      expect(mid.textPrimary, isNot(GlassTokens.dark.textPrimary));
    });

    test('las cápsulas usan la mitad de su altura', () {
      expect(GlassMetrics.capsuleRadius(64), 32);
      expect(GlassMetrics.minTouchTarget, 48);
    });
  });

  group('Tipografía', () {
    test('interfaz en Inter con los tamaños del plan', () {
      final title = GlassTypography.screenTitle(Colors.black);
      expect(title.fontFamily, 'Inter');
      expect(title.fontSize, 34);
      expect(title.fontWeight, FontWeight.w700);
      expect(title.letterSpacing, closeTo(-.68, .001));
      expect(
        GlassTypography.listRow(Colors.black, selected: true).fontWeight,
        FontWeight.w600,
      );
      expect(GlassTypography.sectionText('Apariencia'), 'APARIENCIA');
      expect(GlassTypography.tabLabel(Colors.black).fontSize, 11);
    });

    test('letra en Literata por distribución', () {
      expect(
        GlassTypography.hymnTitle(HymnLayout.phone, Colors.black).fontSize,
        28,
      );
      expect(
        GlassTypography.hymnTitle(
          HymnLayout.tabletPortrait,
          Colors.black,
        ).fontSize,
        34,
      );
      final phone = GlassTypography.lyrics(HymnLayout.phone, Colors.black);
      expect(phone.fontFamily, 'Literata');
      expect(phone.fontSize, 19);
      expect(phone.height, 1.6);
      final landscape = GlassTypography.lyrics(
        HymnLayout.tabletLandscape,
        Colors.black,
      );
      expect(landscape.fontSize, 18);
      expect(landscape.height, 1.55);
    });

    test('el tamaño elegido en Ajustes escala solo la letra', () {
      final big = GlassTypography.lyrics(
        HymnLayout.phone,
        Colors.black,
        userFontSize: 32,
      );
      expect(big.fontSize, 38); // 19 × 32/16
      // La interfaz no cambia.
      expect(GlassTypography.listRow(Colors.black).fontSize, 16);
    });
  });

  group('Cristal', () {
    test('la tarjeta de letra nunca baja de 0.85 de tinte', () {
      expect(lyricsGlassSettings(0).tintAmount, lyricsMinTint);
      expect(lyricsGlassSettings(.95).tintAmount, .95);
      expect(waterGlassSettings(.3).tintAmount, .3);
      expect(waterGlassSettings(0).refractionAmount, 72);
    });

    Future<GlassScopeData> scopeData(
      WidgetTester tester, {
      required bool highContrast,
      double tint = .3,
    }) async {
      late GlassScopeData data;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(highContrast: highContrast),
          child: GlassScope(
            tintAmount: tint,
            child: Builder(
              builder: (context) {
                data = GlassScope.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      return data;
    }

    testWidgets('GlassScope entrega el tinte elegido', (tester) async {
      final data = await scopeData(tester, highContrast: false);
      expect(data.tintAmount, .3);
      expect(data.forcedTint, isFalse);
      expect(data.settings.tintAmount, .3);
      expect(data.lyricsSettings.tintAmount, lyricsMinTint);
    });

    testWidgets('con alto contraste el cristal va tintado', (tester) async {
      final data = await scopeData(tester, highContrast: true);
      expect(data.tintAmount, 1);
      expect(data.forcedTint, isTrue);
    });
  });

  group('Ajuste "Cristal"', () {
    test('por defecto 0 (transparente) y se guarda', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = SettingsRepository();
      expect(await repository.getGlassTint(), 0);
      await repository.setGlassTint(.6);
      expect(await repository.getGlassTint(), .6);
    });
  });
}

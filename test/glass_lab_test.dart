import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/screens/glass_lab/glass_lab_screen.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

Widget _wrap(Widget child) => MaterialApp(
  locale: const Locale('es'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  testWidgets('El laboratorio usa un solo LiquidGlassLayer con blend group', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const GlassLabScreen()));
    await tester.pump();

    expect(find.byType(LiquidGlassLayer), findsOneWidget);
    expect(find.byType(LiquidGlassBlendGroup), findsOneWidget);
    expect(find.byType(LiquidGlass), findsNWidgets(4));
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
  });

  testWidgets('Los controles de prueba cambian tinte, fake y reproducción', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const GlassLabScreen()));
    await tester.pump();

    LiquidGlassLayer layer() =>
        tester.widget<LiquidGlassLayer>(find.byType(LiquidGlassLayer));

    expect(layer().settings.tintAmount, 0);
    expect(layer().fake, isFalse);

    // Deslizador al extremo derecho → tintado.
    await tester.drag(find.byType(Slider), const Offset(2000, 0));
    await tester.pump();
    expect(layer().settings.tintAmount, closeTo(1, 0.001));

    // Interruptor "Forzar FakeGlass".
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(layer().fake, isTrue);

    // Reproducir ↔ pausa (botón grande y mini reproductor comparten estado).
    expect(find.bySemanticsLabel('Pausa'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Reproducir').first);
    await tester.pump();
    expect(find.bySemanticsLabel('Pausa'), findsNWidgets(2));
  });
}

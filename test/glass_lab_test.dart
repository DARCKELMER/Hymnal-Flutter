import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/screens/glass_lab/glass_lab_screen.dart';
import 'package:hymnal_app/widgets/glass/loupe_tab_bar/loupe_tab_bar.dart';
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
    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Ajustes'), findsWidgets);
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

    Finder switchFor(String label) => find.descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(Row)),
      matching: find.byType(Switch),
    );

    // "Agua brillante" activo por defecto: bisel más profundo que iOS 27.
    expect(layer().settings.refractionAmount, 72);
    await tester.tap(switchFor('Agua brillante'));
    await tester.pump();
    expect(layer().settings.refractionAmount, 50);

    // Interruptor "Forzar FakeGlass".
    await tester.tap(switchFor('Forzar FakeGlass'));
    await tester.pump();
    expect(layer().fake, isTrue);

    // Reproducir ↔ pausa (botón grande y mini reproductor comparten estado).
    expect(find.bySemanticsLabel('Pausa'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Reproducir').first);
    await tester.pump();
    expect(find.bySemanticsLabel('Pausa'), findsNWidgets(2));
  });

  testWidgets('La gota del menú cambia de pestaña al tocar', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const GlassLabScreen()));
    await tester.pump();

    final bar = find.byType(LoupeTabBar);
    expect(tester.widget<LoupeTabBar>(bar).selectedIndex, 0);

    // Tocar "Favoritos" (tercera de cuatro pestañas).
    final rect = tester.getRect(bar);
    await tester.tapAt(Offset(rect.left + rect.width * 0.625, rect.center.dy));
    await tester.pumpAndSettle();
    expect(tester.widget<LoupeTabBar>(bar).selectedIndex, 2);
  });
}

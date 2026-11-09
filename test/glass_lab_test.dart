import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/screens/glass_lab/glass_lab_screen.dart';
import 'package:hymnal_app/widgets/glass/jelly_wobble.dart';
import 'package:hymnal_app/widgets/glass/liquid_play_button.dart';
import 'package:hymnal_app/widgets/glass/loupe_tab_bar/loupe_tab_bar.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

Widget _wrap(Widget child) => MaterialApp(
  locale: const Locale('es'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  testWidgets(
    'El laboratorio: layer principal, blend group y gota 3D en reposo',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(const GlassLabScreen()));
      await tester.pump();

      // Layer principal + gota de reposo del menú + play (gota entera con
      // lente propia). La lupa comparte el layer principal: un layer propio
      // que cambia de tamaño deja una "media luna" fantasma al cerrar.
      expect(find.byType(LiquidGlassLayer), findsNWidgets(3));
      expect(find.byKey(LoupeTabBar.loupeKey), findsOneWidget);
      expect(find.byType(LiquidGlassBlendGroup), findsOneWidget);
      expect(find.byType(LiquidGlass), findsNWidgets(5));
      expect(find.text('Inicio'), findsWidgets);
      expect(find.text('Ajustes'), findsWidgets);
    },
  );

  testWidgets('Los controles de prueba cambian tinte, fake y reproducción', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const GlassLabScreen()));
    await tester.pump();

    LiquidGlassLayer layer() =>
        tester.widget<LiquidGlassLayer>(find.byType(LiquidGlassLayer).first);

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

  testWidgets('La lupa se transforma en campo de búsqueda y vuelve', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const GlassLabScreen()));
    await tester.pump();
    expect(find.byType(TextField), findsNothing);

    double collapse() =>
        tester.widget<LoupeTabBar>(find.byType(LoupeTabBar)).collapse;
    expect(collapse(), 0);

    // Abrir: la barra real se encoge en un círculo (sin desmontarse) y
    // aparece el campo.
    await tester.tap(find.bySemanticsLabel('Buscar'));
    await tester.pumpAndSettle();
    expect(find.byType(LoupeTabBar), findsOneWidget);
    expect(collapse(), closeTo(1, .01));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Buscar himnos...'), findsOneWidget);

    // Cerrar con la X: la barra vuelve a su ancho y a mostrar las pestañas.
    await tester.tap(find.bySemanticsLabel('Cancelar').last);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(collapse(), closeTo(0, .01));

    // Abrir de nuevo y cerrar tocando el círculo de la pestaña.
    await tester.tap(find.bySemanticsLabel('Buscar'));
    await tester.pumpAndSettle();
    final circle = tester.getRect(find.byType(LoupeTabBar));
    await tester.tapAt(circle.center);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(collapse(), closeTo(0, .01));
  });

  testWidgets('El play transforma su ícono y lanza la onda', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const GlassLabScreen()));
    await tester.pump();

    final icon = find.descendant(
      of: find.byType(LiquidPlayButton),
      matching: find.byType(AnimatedIcon),
    );
    expect(tester.widget<AnimatedIcon>(icon).progress.value, 0);

    await tester.tap(find.byType(LiquidPlayButton));
    await tester.pump(); // reconstruye y arranca la animación
    await tester.pump(const Duration(milliseconds: 150));
    // A mitad de la animación: el ícono va camino de ⏸.
    final mid = tester.widget<AnimatedIcon>(icon).progress.value;
    expect(mid, greaterThan(0));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedIcon>(icon).progress.value, 1);
  });

  testWidgets('Los botones redondos tiemblan como gelatina al soltar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const GlassLabScreen()));
    await tester.pump();

    final wobble = find.descendant(
      of: find.byType(LiquidPlayButton),
      matching: find.byType(JellyWobble),
    );
    // Diferencia entre la escala horizontal y la vertical del primer
    // Transform bajo la gelatina: 0 en reposo (solo escalas uniformes),
    // distinta de 0 mientras la gota tiembla (ancha o alta).
    double anisotropy() {
      final transforms = find.descendant(
        of: wobble,
        matching: find.byType(Transform),
      );
      if (transforms.evaluate().isEmpty) return 0;
      final m = tester.widget<Transform>(transforms.first).transform;
      return m.entry(0, 0) - m.entry(1, 1);
    }

    expect(anisotropy(), closeTo(0, 1e-6));

    await tester.tap(find.byType(LiquidPlayButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(anisotropy().abs(), greaterThan(.05));

    // Se queda quieta al terminar.
    await tester.pumpAndSettle();
    expect(anisotropy(), closeTo(0, 1e-6));
  });

  testWidgets('Ningún cristal de la fila se crea ni se destruye al buscar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const GlassLabScreen()));
    await tester.pump();

    // Cristales de la fila inferior: los de la barra (cápsula y gota) y el
    // de la lupa/campo.
    List<Element> rowGlass() => [
      ...find
          .descendant(
            of: find.byType(LoupeTabBar),
            matching: find.byType(LiquidGlass),
          )
          .evaluate(),
      tester.element(
        find
            .ancestor(
              of: find.byIcon(Icons.search_rounded),
              matching: find.byType(LiquidGlass),
            )
            .first,
      ),
    ];

    final before = rowGlass();
    expect(before, hasLength(3));
    // Padre del objeto de render de cada cristal: si cambia, el cristal se
    // volvió a montar (aunque una GlobalKey conserve el Element) y el
    // renderizador deja restos de contorno durante unos cuadros.
    final parents = [for (final e in before) e.renderObject!.parent];

    void expectSame(String when) {
      final now = rowGlass();
      expect(now, hasLength(before.length), reason: when);
      for (var i = 0; i < before.length; i++) {
        expect(identical(now[i], before[i]), isTrue, reason: '$when [$i]');
        expect(
          identical(now[i].renderObject!.parent, parents[i]),
          isTrue,
          reason: '$when [$i]: el cristal cambió de padre (re-montaje)',
        );
      }
    }

    await tester.tap(find.bySemanticsLabel('Buscar'));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expectSame('abriendo, cuadro $i');
    }
    await tester.pumpAndSettle();
    expectSame('abierto');

    await tester.tap(find.bySemanticsLabel('Cancelar').last);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expectSame('cerrando, cuadro $i');
    }
    await tester.pumpAndSettle();
    expectSame('cerrado');
  });

  testWidgets('El temblor de gelatina no vuelve a montar el cristal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const GlassLabScreen()));
    await tester.pump();

    final glass = find.descendant(
      of: find.byType(LiquidPlayButton),
      matching: find.byType(LiquidGlass),
    );
    final element = tester.element(glass);
    final parent = element.renderObject!.parent;

    await tester.tap(find.byType(LiquidPlayButton));
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(identical(tester.element(glass), element), isTrue);
      expect(
        identical(tester.element(glass).renderObject!.parent, parent),
        isTrue,
        reason: 'cuadro $i: el cristal cambió de padre',
      );
    }
  });
}

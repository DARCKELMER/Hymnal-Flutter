import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/screens/glass_lab/glass_lab_screen.dart';
import 'package:hymnal_app/widgets/glass/jelly_wobble.dart';
import 'package:hymnal_app/widgets/glass/liquid_mini_player.dart';
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

      // Layer principal + gota de reposo del menú. La gota ▶ y la lupa
      // comparten el layer principal (la gota ▶ para fundirse con el mini
      // reproductor; un layer propio que cambia de tamaño deja destellos).
      expect(find.byType(LiquidGlassLayer), findsNWidgets(2));
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
    expect(find.semantics.byLabel('Pausa'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Reproducir').first);
    await tester.pump(); // arranca el resorte del mini reproductor
    await tester.pump(const Duration(seconds: 1)); // ya brotó
    // La gota ▶ se absorbió en el reproductor: solo queda su ▶/⏸.
    expect(find.semantics.byLabel('Pausa'), findsOne);
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
    // Sonando, la onda del agua corre en bucle: se avanza un tiempo fijo.
    await tester.pump(const Duration(seconds: 1));
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

    // Se queda quieta al terminar (sonando nunca hay "settle").
    await tester.pump(const Duration(seconds: 2));
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

  testWidgets('El mini reproductor brota de la barra y se funde al cerrarlo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const GlassLabScreen()));
    await tester.pump();

    final glass = find.descendant(
      of: find.byType(LiquidMiniPlayer),
      matching: find.byType(LiquidGlass),
    );
    double visibility() =>
        tester.widget<LiquidGlass>(glass).appearance!.visibility;
    double blend() => tester
        .widget<LiquidGlassBlendGroup>(find.byType(LiquidGlassBlendGroup))
        .blend;

    // Oculto: sigue montado, invisible y fuera del lector de pantalla.
    expect(visibility(), 0);
    expect(blend(), 0);
    expect(find.semantics.byLabel('Cerrar reproductor'), findsNothing);
    final element = tester.element(glass);
    final parent = element.renderObject!.parent;

    void expectSameGlass(String when) {
      expect(identical(tester.element(glass), element), isTrue, reason: when);
      expect(
        identical(tester.element(glass).renderObject!.parent, parent),
        isTrue,
        reason: '$when: el cristal cambió de padre (re-montaje)',
      );
    }

    // Reproducir: brota, y a mitad del brote la gota se mezcla con la barra.
    await tester.tap(find.bySemanticsLabel('Reproducir').first);
    var maxBlend = 0.0;
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expectSameGlass('brotando, cuadro $i');
      maxBlend = math.max(maxBlend, blend());
    }
    expect(maxBlend, greaterThan(10));
    expect(visibility(), 1);
    expect(blend(), closeTo(0, .5));
    expect(find.bySemanticsLabel('Cerrar reproductor'), findsOneWidget);

    // Pausar no lo oculta.
    await tester.tap(find.bySemanticsLabel('Pausa').first);
    await tester.pump(const Duration(seconds: 1));
    expect(visibility(), 1);

    // Cerrar con la ✕: se funde con la barra y deja de sonar.
    await tester.tap(find.bySemanticsLabel('Cerrar reproductor'));
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expectSameGlass('fundiéndose, cuadro $i');
    }
    expect(visibility(), 0);
    expect(find.semantics.byLabel('Pausa'), findsNothing);
    expect(find.semantics.byLabel('Cerrar reproductor'), findsNothing);
  });

  testWidgets('Deslizar el mini reproductor cambia de himno o lo cierra', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const GlassLabScreen()));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Reproducir').first);
    await tester.pump(); // arranca el resorte
    await tester.pump(const Duration(seconds: 2));

    final mini = find.byType(LiquidMiniPlayer);
    expect(find.text('Cantad alegres al Señor'), findsOneWidget);

    // A la izquierda: siguiente himno; la insignia muestra su número.
    await tester.drag(mini, const Offset(-200, 0));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Da gloria al Señor'), findsOneWidget);
    expect(find.descendant(of: mini, matching: find.text('2')), findsOneWidget);

    // A la derecha: vuelve al anterior.
    await tester.drag(mini, const Offset(200, 0));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Cantad alegres al Señor'), findsOneWidget);

    // Un toque corto no cambia de himno.
    await tester.drag(mini, const Offset(-20, 0));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Cantad alegres al Señor'), findsOneWidget);

    // Hacia abajo: se cierra.
    await tester.drag(mini, const Offset(0, 120));
    await tester.pump(const Duration(seconds: 2));
    expect(find.semantics.byLabel('Cerrar reproductor'), findsNothing);
    expect(find.semantics.byLabel('Pausa'), findsNothing);
  });

  testWidgets('El agua de progreso avanza solo mientras suena', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const GlassLabScreen()));
    await tester.pump();

    double progress() => tester
        .widget<LiquidMiniPlayer>(find.byType(LiquidMiniPlayer))
        .progress
        .value;

    await tester.tap(find.bySemanticsLabel('Reproducir').first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    final playing = progress();
    expect(playing, greaterThan(.05));

    // En pausa se detiene.
    await tester.tap(find.bySemanticsLabel('Pausa').first);
    await tester.pump();
    final paused = progress();
    await tester.pump(const Duration(seconds: 3));
    expect(progress(), closeTo(paused, 1e-9));
  });

  testWidgets('La cápsula alcanza la gota ▶ por el costado y la disuelve', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const GlassLabScreen()));
    await tester.pump();

    final play = find.byType(LiquidPlayButton);
    final mini = find.byType(LiquidMiniPlayer);
    final glass = find.descendant(of: play, matching: find.byType(LiquidGlass));
    double visibility() =>
        tester.widget<LiquidGlass>(glass).appearance!.visibility;
    double blend() => tester
        .widget<LiquidGlassBlendGroup>(find.byType(LiquidGlassBlendGroup))
        .blend;
    final element = tester.element(glass);
    final parent = element.renderObject!.parent;
    void expectSameGlass(String when) {
      expect(identical(tester.element(glass), element), isTrue, reason: when);
      expect(
        identical(tester.element(glass).renderObject!.parent, parent),
        isTrue,
        reason: '$when: el cristal cambió de padre (re-montaje)',
      );
    }

    // En reposo: sobre la lupa, en el hueco del mini reproductor, visible.
    final restCenter = tester.getCenter(play);
    final search = tester.getCenter(find.byIcon(Icons.search_rounded));
    expect(restCenter.dy, closeTo(tester.getCenter(mini).dy, 1));
    expect(restCenter.dx, closeTo(search.dx, 1));
    expect(visibility(), 1);

    // Reproducir: la gota no se mueve (ni salta); la cápsula la alcanza,
    // se forma el puente líquido (mezcla > 0) y la gota se disuelve.
    await tester.tap(play);
    var maxBlend = 0.0;
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expectSameGlass('fundiéndose, cuadro $i');
      expect(
        tester.getCenter(play).dy,
        closeTo(restCenter.dy, .5),
        reason: 'cuadro $i: la gota no salta',
      );
      expect(tester.getCenter(play).dx, closeTo(restCenter.dx, .5));
      maxBlend = math.max(maxBlend, blend());
    }
    expect(maxBlend, greaterThan(10));
    expect(visibility(), 0);
    // El ▶/⏸ de la cápsula queda justo donde estaba la gota.
    final miniPlay = tester.getCenter(
      find.descendant(of: mini, matching: find.byType(AnimatedIcon)),
    );
    expect(miniPlay.dx, closeTo(restCenter.dx, 1));
    expect(find.semantics.byLabel('Reproducir'), findsNothing);

    // Pausar no la saca.
    tester.semantics.tap(find.semantics.byLabel('Pausa'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(visibility(), 0);

    // Cerrar el reproductor: la gota vuelve a formarse en su lugar.
    tester.semantics.tap(find.semantics.byLabel('Cerrar reproductor'));
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expectSameGlass('volviendo, cuadro $i');
    }
    expect(visibility(), 1);
    expect(tester.getCenter(play).dx, closeTo(restCenter.dx, .5));
    expect(tester.getCenter(play).dy, closeTo(restCenter.dy, .5));
    expect(find.semantics.byLabel('Reproducir'), findsOne);
  });

  testWidgets('El interruptor de lente propia separa la gota ▶ en su layer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const GlassLabScreen()));
    await tester.pump();
    expect(find.byType(LiquidGlassLayer), findsNWidgets(2));

    final lensSwitch = find.descendant(
      of: find.ancestor(
        of: find.text('Lente propia en la gota ▶'),
        matching: find.byType(Row),
      ),
      matching: find.byType(Switch),
    );
    await tester.tap(lensSwitch);
    await tester.pump();
    expect(find.byType(LiquidGlassLayer), findsNWidgets(3));
  });
}

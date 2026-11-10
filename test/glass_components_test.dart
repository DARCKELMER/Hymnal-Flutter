import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/screens/glass_lab/glass_catalog_screen.dart';
import 'package:hymnal_app/styles/glass/glass_settings.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/theme.dart';
import 'package:hymnal_app/widgets/glass/glass_controls.dart';
import 'package:hymnal_app/widgets/glass/glass_icon_button.dart';
import 'package:hymnal_app/widgets/glass/glass_navigation_rail.dart';
import 'package:hymnal_app/widgets/glass/glass_pill.dart';
import 'package:hymnal_app/widgets/glass/glass_scope.dart';
import 'package:hymnal_app/widgets/glass/glass_segmented.dart';
import 'package:hymnal_app/widgets/glass/glass_zone.dart';
import 'package:hymnal_app/widgets/glass/lyrics_card.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

Widget _host(Widget child, {double tint = 0, ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.lightTheme,
  locale: const Locale('es'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: GlassScope(
    tintAmount: tint,
    child: Scaffold(
      body: GlassZone(
        child: Center(
          child: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    ),
  ),
);

/// Contraste WCAG entre dos colores opacos.
double _contrast(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) =>
        v <= .03928 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();
    return .2126 * ch(c.r) + .7152 * ch(c.g) + .0722 * ch(c.b);
  }

  final (l1, l2) = (lum(a), lum(b));
  return (math.max(l1, l2) + .05) / (math.min(l1, l2) + .05);
}

void main() {
  testWidgets('GlassIconButton: 48 dp suelto, 64 en barra, y se anuncia', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassIconButton(
              icon: Icons.search,
              semanticLabel: 'Buscar',
              onPressed: () => taps++,
            ),
            const GlassIconButton(
              icon: Icons.play_arrow,
              semanticLabel: 'Reproducir',
              onPressed: null,
              bar: true,
              prominent: true,
            ),
          ],
        ),
      ),
    );
    final buttons = find.byType(GlassIconButton);
    expect(tester.getSize(buttons.first), const Size.square(48));
    expect(tester.getSize(buttons.last), const Size.square(64));
    await tester.tap(find.bySemanticsLabel('Buscar'));
    await tester.pump(const Duration(seconds: 1));
    expect(taps, 1);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Reproducir')),
      matchesSemantics(
        label: 'Reproducir',
        isButton: true,
        hasEnabledState: true,
      ),
    );
  });

  testWidgets('GlassPill: acciones de 48 dp con estado seleccionado', (
    tester,
  ) async {
    var fav = false;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => GlassPill(
            children: [
              GlassPillAction(
                icon: Icons.share,
                semanticLabel: 'Compartir',
                onPressed: () {},
              ),
              GlassPillAction(
                icon: Icons.favorite,
                semanticLabel: 'Favoritos',
                selected: fav,
                onPressed: () => setState(() => fav = !fav),
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(GlassPillAction).first).height, 48);
    expect(find.byType(LiquidGlass), findsOneWidget); // una sola cápsula
    await tester.tap(find.bySemanticsLabel('Favoritos'));
    await tester.pump(const Duration(seconds: 1));
    expect(fav, isTrue);
    expect(
      find.semantics.byPredicate((n) {
        final d = n.getSemanticsData();
        return d.label == 'Favoritos' &&
            d.flagsCollection.isSelected.toBoolOrNull() == true;
      }),
      findsOne,
    );
  });

  testWidgets('GlassSegmented: cambia de opción y la píldora se desliza', (
    tester,
  ) async {
    var selected = 'a';
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 300,
            child: GlassSegmented<String>(
              segments: const [
                GlassSegment(value: 'a', label: 'Numérico'),
                GlassSegment(value: 'b', label: 'Alfabético'),
                GlassSegment(value: 'c', label: 'Temático'),
              ],
              selected: selected,
              onChanged: (v) => setState(() => selected = v),
            ),
          ),
        ),
      ),
    );
    double pillLeft() => tester
        .widget<Positioned>(
          find.descendant(
            of: find.byType(GlassSegmented<String>),
            matching: find.byType(Positioned),
          ),
        )
        .left!;
    final start = pillLeft();
    await tester.tap(find.bySemanticsLabel('Temático'));
    await tester.pump(); // arranca el resorte
    await tester.pump(const Duration(seconds: 2));
    expect(selected, 'c');
    expect(pillLeft(), greaterThan(start + 150));
    // Grupo exclusivo: solo una opción seleccionada.
    expect(
      find.semantics.byPredicate(
        (n) =>
            n.getSemanticsData().flagsCollection.isSelected.toBoolOrNull() ==
            true,
      ),
      findsOne,
    );
  });

  testWidgets('GlassSwitch: alterna, se anuncia y respeta deshabilitado', (
    tester,
  ) async {
    var on = false;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassSwitch(
                value: on,
                semanticLabel: 'Pantalla encendida',
                onChanged: (v) => setState(() => on = v),
              ),
              const GlassSwitch(
                value: true,
                semanticLabel: 'Bloqueado',
                onChanged: null,
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(GlassSwitch).first).height, 48);
    await tester.tap(find.bySemanticsLabel('Pantalla encendida'));
    await tester.pump(const Duration(seconds: 1));
    expect(on, isTrue);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Pantalla encendida')),
      matchesSemantics(
        label: 'Pantalla encendida',
        hasToggledState: true,
        isToggled: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.bySemanticsLabel('Bloqueado'));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('GlassSlider: arrastrar cambia el valor', (tester) async {
    var value = 0.0;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 300,
            child: GlassSlider(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(Slider), const Offset(400, 0));
    await tester.pump();
    expect(value, closeTo(1, .01));
  });

  testWidgets('GlassNavigationRail: 84 dp de ancho y cambia de destino', (
    tester,
  ) async {
    var index = 0;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => GlassNavigationRail(
            destinations: const [
              GlassRailDestination(icon: Icons.home, label: 'Inicio'),
              GlassRailDestination(icon: Icons.list, label: 'Listas'),
              GlassRailDestination(icon: Icons.favorite, label: 'Favoritos'),
            ],
            selectedIndex: index,
            onSelected: (i) => setState(() => index = i),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(GlassNavigationRail)).width, 84);
    // La gota de agua 3D (lente propia) está sobre el destino elegido.
    final drop = find.byKey(GlassNavigationRail.dropKey);
    expect(drop, findsOneWidget);
    final start = tester.getCenter(drop).dy;
    await tester.tap(find.bySemanticsLabel('Favoritos'));
    await tester.pump(); // arranca el resorte
    await tester.pump(const Duration(seconds: 2));
    expect(index, 2);
    // Se deslizó dos destinos hacia abajo y quedó sobre "Favoritos".
    expect(tester.getCenter(drop).dy, closeTo(start + 2 * 72, 1));
    expect(
      tester.getCenter(drop).dy,
      closeTo(tester.getCenter(find.bySemanticsLabel('Favoritos')).dy, 1),
    );
  });

  testWidgets('LyricsCard: tinte mínimo 0.85 aunque el cristal sea Clear', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const LyricsCard(child: Text('Cantad alegres al Señor'))),
    );
    final layers = tester.widgetList<LiquidGlassLayer>(
      find.byType(LiquidGlassLayer),
    );
    // El de la zona usa el tinte del usuario (0) y el de la tarjeta 0.85.
    expect(layers.map((l) => l.settings.tintAmount), contains(lyricsMinTint));
    final text = tester.widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text('Cantad alegres al Señor'),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );
    expect(text.style.fontFamily, 'Literata');
  });

  test('LyricsCard: contraste de al menos 4.5:1 en el peor fondo', () {
    // Claro: velo blanco sobre un fondo negro (lo peor para letra oscura).
    final lightBg = Color.alphaBlend(
      LyricsCard.veil(Brightness.light),
      const Color(0xFF000000),
    );
    expect(
      _contrast(GlassTokens.light.textPrimary, lightBg),
      greaterThanOrEqualTo(4.5),
    );
    // Oscuro: velo azul noche sobre un fondo blanco (lo peor para letra
    // clara).
    final darkBg = Color.alphaBlend(
      LyricsCard.veil(Brightness.dark),
      const Color(0xFFFFFFFF),
    );
    expect(
      _contrast(GlassTokens.dark.textPrimary, darkBg),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('El catálogo muestra todos los componentes sin errores', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 4800);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GlassScope(tintAmount: .1, child: GlassCatalogScreen()),
      ),
    );
    await tester.pump();
    expect(find.byType(GlassIconButton), findsNWidgets(3));
    expect(find.byType(GlassPill), findsOneWidget);
    expect(find.byType(GlassSegmented<ThemeMode>), findsOneWidget);
    expect(find.byType(GlassSwitch), findsOneWidget);
    expect(find.byType(GlassNavigationRail), findsOneWidget);
    expect(find.byType(LyricsCard), findsOneWidget);
    // Zona de controles + tarjeta de letra + gota de la barra lateral.
    expect(find.byType(LiquidGlassLayer), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}

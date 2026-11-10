import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/glass/glass_settings.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Configuración de cristal que comparten todos los componentes.
@immutable
class GlassScopeData {
  const GlassScopeData({required this.tintAmount, required this.forcedTint});

  /// Tinte efectivo (0 = transparente, 1 = tintado).
  final double tintAmount;

  /// Si el tinte está forzado al máximo por accesibilidad (alto contraste).
  final bool forcedTint;

  /// Cristal de los controles (agua brillante con el tinte efectivo).
  LiquidGlassSettings get settings => waterGlassSettings(tintAmount);

  /// Cristal de la tarjeta de letra: siempre muy tintado.
  LiquidGlassSettings get lyricsSettings => lyricsGlassSettings(tintAmount);

  @override
  bool operator ==(Object other) =>
      other is GlassScopeData &&
      other.tintAmount == tintAmount &&
      other.forcedTint == forcedTint;

  @override
  int get hashCode => Object.hash(tintAmount, forcedTint);
}

/// Expone a sus hijos la configuración de cristal: el ajuste "Cristal" de
/// [SettingsService] (`glassTint`) o, si el sistema pide alto contraste,
/// cristal totalmente tintado para que todo se lea bien.
///
/// Va una sola vez arriba de la app (en `MaterialApp.builder`). Los
/// componentes la leen con [GlassScope.of].
class GlassScope extends StatelessWidget {
  const GlassScope({required this.child, this.tintAmount, super.key});

  final Widget child;

  /// Tinte fijo (pruebas o vistas previas). `null` = el de los ajustes.
  final double? tintAmount;

  /// Tinte por defecto si no hay ajustes ni un [GlassScope] arriba.
  static const double defaultTint = 0;

  static GlassScopeData of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_GlassScopeInherited>()
          ?.data ??
      _resolve(context, defaultTint);

  static GlassScopeData _resolve(BuildContext context, double tint) {
    final highContrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    return GlassScopeData(
      tintAmount: highContrast ? 1 : tint.clamp(0.0, 1.0),
      forcedTint: highContrast,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fixed = tintAmount;
    if (fixed != null || !GetIt.I.isRegistered<SettingsService>()) {
      return _GlassScopeInherited(
        data: _resolve(context, fixed ?? defaultTint),
        child: child,
      );
    }
    final settings = GetIt.I<SettingsService>();
    return ListenableBuilder(
      listenable: settings,
      builder: (context, child) => _GlassScopeInherited(
        data: _resolve(context, settings.glassTint),
        child: child!,
      ),
      child: child,
    );
  }
}

class _GlassScopeInherited extends InheritedWidget {
  const _GlassScopeInherited({required this.data, required super.child});

  final GlassScopeData data;

  @override
  bool updateShouldNotify(_GlassScopeInherited oldWidget) =>
      oldWidget.data != data;
}

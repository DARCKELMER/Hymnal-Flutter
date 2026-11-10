import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/data/repository/hymnal_repository.dart';
import 'package:hymnal_app/layers/domain/model/hymn.dart';
import 'package:hymnal_app/layers/screens/history/history_screen.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_opener.dart';
import 'package:hymnal_app/services/history_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
import 'package:hymnal_app/widgets/glass/glass_icon_button.dart';
import 'package:hymnal_app/widgets/glass/glass_zone.dart';
import 'package:hymnal_app/widgets/glass/jelly_wobble.dart';
import 'package:hymnal_app/widgets/glass/liquid_glass_button.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

part 'home_controller.dart';

/// Inicio (lienzo, pantalla 1): encabezado con Historial, selector de
/// himnario en cápsula, tarjeta del número con vista previa del título en
/// tiempo real y teclado numérico de cristal, y el botón "Abrir himno".
///
/// En celular no aparece el teclado del sistema (lo reemplaza el propio);
/// en tableta funciona además el teclado físico.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends _HomeController {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = GlassTokens.of(context);
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;

    return ListenableBuilder(
      listenable: _settingsService,
      builder: (context, _) {
        final hymnal = _settingsService.selectedHymnal;
        return Focus(
          focusNode: _keysFocus,
          autofocus: isTablet,
          onKeyEvent: _onKey,
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                GlassMetrics.screenMarginPhone,
                12,
                GlassMetrics.screenMarginPhone,
                24,
              ),
              // Una sola zona de cristal para toda la pantalla.
              child: GlassZone(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Encabezado.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.appFullName,
                                style:
                                    GlassTypography.listRow(
                                      tokens.textSecondary,
                                    ).copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                l10n.home,
                                style: GlassTypography.screenTitle(
                                  tokens.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GlassIconButton(
                          icon: Icons.history_rounded,
                          semanticLabel: l10n.history,
                          onPressed: _openHistory,
                        ),
                      ],
                    ),
                    const SizedBox(height: GlassMetrics.gapL),
                    _HymnalCapsule(
                      code: (hymnal?.twoLetterIsoLanguageName ?? '')
                          .toUpperCase(),
                      name: hymnal?.name ?? '',
                      detail: [
                        if (hymnal != null) hymnal.detail,
                        if (_hymnsByNumber.isNotEmpty)
                          l10n.searchResultsCount(_hymnsByNumber.length),
                      ].join(' · '),
                      semanticLabel: l10n.selectHymnal,
                      onTap: _showHymnalSelector,
                    ),
                    const SizedBox(height: GlassMetrics.gapM),
                    _NumberCard(
                      label: l10n.hymnNumber,
                      number: _number,
                      preview: _previewHymn,
                      missingLabel: l10n.hymnDoesNotExist,
                      clearLabel: l10n.clear,
                      clearSemantics: l10n.clearNumber,
                      deleteSemantics: l10n.deleteDigit,
                      onDigit: _typeDigit,
                      onDelete: _deleteDigit,
                      onClear: _clearNumber,
                    ),
                    const SizedBox(height: GlassMetrics.gapL),
                    _OpenButton(
                      label: l10n.openHymn,
                      onPressed: _previewHymn == null ? null : _openHymn,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Cápsula del himnario elegido: insignia tintada, nombre, detalle y
/// flecha. Abre la lista de himnarios.
class _HymnalCapsule extends StatelessWidget {
  const _HymnalCapsule({
    required this.code,
    required this.name,
    required this.detail,
    required this.semanticLabel,
    required this.onTap,
  });

  final String code;
  final String name;
  final String detail;
  final String semanticLabel;
  final VoidCallback onTap;

  static const double height = 60;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => LiquidGlassButton(
        semanticLabel: '$semanticLabel: $name',
        onTap: onTap,
        size: Size(constraints.maxWidth, height),
        shape: const LiquidRoundedSuperellipse(borderRadius: height / 2),
        interactionScale: 1.03,
        stretch: .2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.buttonTint,
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontFamily: GlassTypography.ui,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GlassTypography.listRow(
                        tokens.textPrimary,
                        selected: true,
                      ).copyWith(fontSize: 17),
                    ),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: GlassTypography.ui,
                        fontSize: 13,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: tokens.textPrimary,
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta del número: etiqueta, número grande (Literata 64/600), vista
/// previa del título en tiempo real y el teclado numérico.
class _NumberCard extends StatelessWidget {
  const _NumberCard({
    required this.label,
    required this.number,
    required this.preview,
    required this.missingLabel,
    required this.clearLabel,
    required this.clearSemantics,
    required this.deleteSemantics,
    required this.onDigit,
    required this.onDelete,
    required this.onClear,
  });

  final String label;
  final String number;
  final Hymn? preview;
  final String missingLabel;
  final String clearLabel;
  final String clearSemantics;
  final String deleteSemantics;
  final ValueChanged<int> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  /// Color de aviso ("No existe").
  static const Color _warning = Color(0xFFC2410C);

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final missing = number.isNotEmpty && preview == null;

    Widget key(Widget child, String semantics, VoidCallback onTap) =>
        _KeypadKey(semanticLabel: semantics, onTap: onTap, child: child);
    Widget digit(int d) => key(
      Text(
        '$d',
        style: TextStyle(
          fontFamily: GlassTypography.ui,
          fontSize: 26,
          fontWeight: FontWeight.w500,
          color: tokens.textPrimary,
        ),
      ),
      '$d',
      () => onDigit(d),
    );

    return LiquidGlass(
      shape: const LiquidRoundedSuperellipse(
        borderRadius: GlassMetrics.cardRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: GlassTypography.ui,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: tokens.textSecondary,
              ),
            ),
            // El número grande, anunciado junto con su vista previa.
            Semantics(
              liveRegion: true,
              label: number.isEmpty
                  ? label
                  : '$number. ${preview?.title ?? missingLabel}',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 78,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        number.isEmpty ? '—' : number,
                        style: TextStyle(
                          fontFamily: GlassTypography.content,
                          fontSize: 64,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                          color: number.isEmpty
                              ? tokens.textSecondary.withValues(alpha: .4)
                              : tokens.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 24,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: Row(
                        key: ValueKey(preview?.number ?? (missing ? -1 : 0)),
                        children: [
                          if (preview != null) ...[
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: tokens.accent,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                preview!.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GlassTypography.listRow(tokens.accent),
                              ),
                            ),
                          ] else if (missing) ...[
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: _warning,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              missingLabel,
                              style: GlassTypography.listRow(_warning),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: GlassMetrics.gapL),
            // Teclado numérico: 1–9, Borrar, 0 y retroceso.
            for (final row in const [
              [1, 2, 3],
              [4, 5, 6],
              [7, 8, 9],
            ]) ...[
              Row(
                children: [
                  for (final (i, d) in row.indexed) ...[
                    if (i > 0) const SizedBox(width: GlassMetrics.gapS),
                    Expanded(child: digit(d)),
                  ],
                ],
              ),
              const SizedBox(height: GlassMetrics.gapS),
            ],
            Row(
              children: [
                Expanded(
                  child: key(
                    Text(
                      clearLabel,
                      style: TextStyle(
                        fontFamily: GlassTypography.ui,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                    clearSemantics,
                    onClear,
                  ),
                ),
                const SizedBox(width: GlassMetrics.gapS),
                Expanded(child: digit(0)),
                const SizedBox(width: GlassMetrics.gapS),
                Expanded(
                  child: key(
                    Icon(Icons.backspace_outlined, color: tokens.textPrimary),
                    deleteSemantics,
                    onDelete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tecla del teclado numérico: cápsula translúcida de 52 dp **sin cristal
/// propio** (va sobre la tarjeta de cristal: no hay cristal sobre cristal),
/// con brillo arriba y temblor de gelatina al tocarla.
class _KeypadKey extends StatelessWidget {
  const _KeypadKey({
    required this.semanticLabel,
    required this.onTap,
    required this.child,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;

  static const double height = 52;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      container: true,
      button: true,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: JellyWobble(
          amplitude: .08,
          squash: .06,
          child: Container(
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? const [Color(0x40FFFFFF), Color(0x14FFFFFF)]
                    : const [Color(0x8CFFFFFF), Color(0x40FFFFFF)],
              ),
              border: Border.all(color: const Color(0x66FFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Botón tintado "Abrir himno" de 56 dp; desactivado si el número no
/// existe.
class _OpenButton extends StatelessWidget {
  const _OpenButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final enabled = onPressed != null;
    return LayoutBuilder(
      builder: (context, constraints) => Opacity(
        opacity: enabled ? 1 : .55,
        child: LiquidGlassButton(
          semanticLabel: label,
          onTap: onPressed,
          size: Size(constraints.maxWidth, height),
          shape: const LiquidRoundedSuperellipse(borderRadius: height / 2),
          appearance: LiquidGlassAppearance.ios27Clear(tint: tokens.buttonTint),
          interactionScale: 1.04,
          stretch: .25,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: GlassTypography.ui,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

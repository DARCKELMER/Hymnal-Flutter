import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:hymnal_app/constants/app_links.dart';
import 'package:hymnal_app/core/constants/app_assets.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:hymnal_app/layers/screens/glass_lab/glass_catalog_screen.dart';
import 'package:hymnal_app/layers/screens/glass_lab/glass_lab_screen.dart';
import 'package:hymnal_app/services/favorites_service.dart';
import 'package:hymnal_app/services/history_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
import 'package:hymnal_app/utils/platform_helper.dart';
import 'package:hymnal_app/widgets/glass/glass_card.dart';
import 'package:hymnal_app/widgets/glass/glass_controls.dart';
import 'package:hymnal_app/widgets/glass/glass_segmented.dart';
import 'package:hymnal_app/widgets/glass/glass_zone.dart';

part 'settings_controller.dart';

/// Ajustes (lienzo, pantalla 5): título grande y tarjetas de cristal por
/// sección — Fondo, Apariencia (tema con la gota, tamaño de letra y
/// cristal), Himnario, Comportamiento, Datos y Acerca de (con créditos).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends _SettingsController {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = GlassTokens.of(context);
    return ListenableBuilder(
      listenable: _settingsService,
      builder: (context, _) {
        final hymnal = _settingsService.selectedHymnal;
        return SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  GlassMetrics.screenMarginPhone,
                  12,
                  GlassMetrics.screenMarginPhone,
                  120,
                ),
                children: [
                  Text(
                    l10n.settings,
                    style: GlassTypography.screenTitle(tokens.textPrimary),
                  ),
                  const SizedBox(height: GlassMetrics.gapM),

                  // Fondo (la galería de paisajes llega con la fase 5).
                  _Section(
                    title: l10n.sectionBackground,
                    children: [
                      _SwitchRow(
                        title: l10n.backgroundImage,
                        subtitle: l10n.backgroundImageSubtitle,
                        value: _settingsService.showBackgroundImage,
                        onChanged: _settingsService.setShowBackgroundImage,
                      ),
                    ],
                  ),

                  _Section(
                    title: l10n.sectionAppearance,
                    children: [
                      GlassSegmented<String>(
                        segments: [
                          GlassSegment(value: 'light', label: l10n.themeLight),
                          GlassSegment(value: 'dark', label: l10n.themeDark),
                          GlassSegment(
                            value: 'system',
                            label: l10n.themeSystem,
                          ),
                        ],
                        selected: _settingsService.themeMode,
                        onChanged: _settingsService.setThemeMode,
                      ),
                      const SizedBox(height: GlassMetrics.gapM),
                      _fontSizeRow(l10n, tokens),
                      const SizedBox(height: GlassMetrics.gapS),
                      _glassTintRow(l10n, tokens),
                    ],
                  ),

                  _Section(
                    children: [
                      _Row(
                        title: l10n.sectionHymnal,
                        subtitle: hymnal != null
                            ? '${hymnal.name} · ${hymnal.detail}'
                            : l10n.none,
                        onTap: _showHymnalSelector,
                      ),
                    ],
                  ),

                  _Section(
                    title: l10n.sectionBehavior,
                    children: [
                      _SwitchRow(
                        title: l10n.keepScreenOn,
                        value: _settingsService.keepScreenOn,
                        onChanged: (value) {
                          _settingsService.setKeepScreenOn(value);
                          WakelockPlus.toggle(enable: value);
                        },
                      ),
                    ],
                  ),

                  _Section(
                    title: l10n.sectionDataManagement,
                    children: [
                      _Row(
                        icon: Icons.history_rounded,
                        title: l10n.clearHistory,
                        subtitle: l10n.clearHistorySubtitle,
                        onTap: _clearHistory,
                      ),
                      _Row(
                        icon: Icons.heart_broken_outlined,
                        title: l10n.clearFavorites,
                        subtitle: l10n.clearFavoritesSubtitle,
                        onTap: _clearFavorites,
                      ),
                    ],
                  ),

                  _Section(
                    title: l10n.sectionAbout,
                    children: [
                      _Row(
                        icon: Icons.language_rounded,
                        title: l10n.website,
                        subtitle: AppLinks.websiteUrl,
                        onTap: () => _launchUrl(AppLinks.websiteUrl),
                      ),
                      _Row(
                        icon: Icons.code_rounded,
                        title: l10n.contribute,
                        subtitle: l10n.githubRepo,
                        onTap: () => _launchUrl(AppLinks.repositoryUrl),
                      ),
                      _Row(
                        icon: Icons.mail_outline_rounded,
                        title: l10n.contactUs,
                        subtitle: AppLinks.contactUrl,
                        onTap: () => _launchUrl(AppLinks.contactUrl),
                      ),
                      _Row(
                        icon: Icons.star_outline_rounded,
                        title: l10n.rateApp,
                        onTap: _showRateOptions,
                      ),
                      _Row(
                        icon: Icons.favorite_outline_rounded,
                        title: l10n.credits,
                        onTap: _showCredits,
                      ),
                      _Row(
                        icon: Icons.inventory_2_outlined,
                        title: l10n.licenses,
                        onTap: () => _showLicenses(l10n),
                      ),
                      _Row(
                        icon: Icons.info_outline_rounded,
                        title: l10n.version,
                        subtitle: '$_appVersion ($_buildNumber)',
                      ),
                      if (kDebugMode) ...[
                        _Row(
                          icon: Icons.blur_on_rounded,
                          title: l10n.glassLabTitle,
                          subtitle: l10n.glassLabSubtitle,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const GlassLabScreen(),
                            ),
                          ),
                        ),
                        _Row(
                          icon: Icons.widgets_outlined,
                          title: l10n.glassCatalogTitle,
                          subtitle: l10n.glassCatalogSubtitle,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const GlassCatalogScreen(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Tamaño de letra: "A" pequeña — deslizador — "A" grande.
  Widget _fontSizeRow(AppLocalizations l10n, GlassTokens tokens) {
    TextStyle a(double size) => TextStyle(
      fontFamily: GlassTypography.content,
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: tokens.textPrimary,
    );
    return Row(
      children: [
        ExcludeSemantics(child: Text('A', style: a(15))),
        Expanded(
          child: GlassSlider(
            value: _settingsService.fontSize,
            min: 12,
            max: 32,
            divisions: 10,
            label: _settingsService.fontSize.round().toString(),
            activeColor: tokens.vivid,
            semanticFormatterCallback: (v) => '${l10n.fontSize}: ${v.round()}',
            onChanged: _settingsService.setFontSize,
          ),
        ),
        ExcludeSemantics(child: Text('A', style: a(26))),
      ],
    );
  }

  /// "Cristal: Transparente ↔ Tintado". Con alto contraste el cristal va
  /// siempre tintado y el deslizador queda desactivado.
  Widget _glassTintRow(AppLocalizations l10n, GlassTokens tokens) {
    final forced = MediaQuery.highContrastOf(context);
    final caption = TextStyle(
      fontFamily: GlassTypography.ui,
      fontSize: 13,
      color: tokens.textSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.glassTint,
          style: GlassTypography.listRow(tokens.textPrimary, selected: true),
        ),
        Row(
          children: [
            Text(l10n.glassTransparent, style: caption),
            Expanded(
              child: GlassSlider(
                value: forced ? 1 : _settingsService.glassTint,
                activeColor: tokens.vivid,
                onChanged: forced ? null : _settingsService.setGlassTint,
                semanticFormatterCallback: (value) =>
                    '${l10n.glassTint}: ${(value * 100).round()} %',
              ),
            ),
            Text(l10n.glassTinted, style: caption),
          ],
        ),
        if (forced) Text(l10n.glassTintForced, style: caption),
      ],
    );
  }

  void _showLicenses(AppLocalizations l10n) {
    showLicensePage(
      context: context,
      applicationIcon: Padding(
        padding: const EdgeInsets.all(12),
        child: Image.asset(AppAssets.appIcon, width: 80, height: 80),
      ),
      applicationName: l10n.appName,
      applicationVersion: '$_appVersion ($_buildNumber)',
      applicationLegalese:
          '${l10n.aboutDevelopers}\n\n'
          '${l10n.applicationLegalese(DateTime.now().year.toString())}',
    );
  }
}

/// Tarjeta de cristal de una sección, con su título en versalitas.
class _Section extends StatelessWidget {
  const _Section({required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final title = this.title;
    return Padding(
      padding: const EdgeInsets.only(bottom: GlassMetrics.gapM),
      child: Stack(
        children: [
          // El cristal de la tarjeta, detrás; los controles de cristal van
          // en su propia capa encima.
          const Positioned.fill(child: GlassCard(child: SizedBox.expand())),
          GlassZone(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null) ...[
                    Semantics(
                      header: true,
                      child: Text(
                        GlassTypography.sectionText(title),
                        style: GlassTypography.sectionLabel(
                          tokens.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: GlassMetrics.gapS),
                  ],
                  ...children,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila con título, subtítulo opcional y flecha si se puede tocar.
class _Row extends StatelessWidget {
  const _Row({required this.title, this.subtitle, this.icon, this.onTap});

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final subtitle = this.subtitle;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 22, color: tokens.textPrimary),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GlassTypography.listRow(
                          tokens.textPrimary,
                          selected: true,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: GlassTypography.ui,
                            fontSize: 13,
                            color: tokens.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right_rounded, color: tokens.textPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila con un interruptor de cristal.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final subtitle = this.subtitle;
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GlassTypography.listRow(
                        tokens.textPrimary,
                        selected: true,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: GlassTypography.ui,
                          fontSize: 13,
                          color: tokens.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GlassSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:hymnal_app/constants/app_links.dart';
import 'package:hymnal_app/layers/screens/glass_lab/glass_catalog_screen.dart';
import 'package:hymnal_app/layers/screens/glass_lab/glass_lab_screen.dart';
import 'package:hymnal_app/core/constants/app_assets.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/services/favorites_service.dart';
import 'package:hymnal_app/services/history_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:hymnal_app/utils/platform_helper.dart';

part 'settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends _SettingsController {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_settingsService]),
      builder: (context, child) {
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            toolbarHeight:
                MediaQuery.of(context).orientation == Orientation.landscape
                ? 40
                : null,
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            titleTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            title: Text(l10n.settings),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              _buildSection(l10n.sectionHymnal),
              _buildHymnalSelector(),
              _buildSection(l10n.sectionAppearance),
              _buildThemeSelector(),
              _buildFontSizeSlider(),
              _buildGlassTintSlider(),
              SwitchListTile(
                title: Text(l10n.backgroundImage),
                subtitle: Text(l10n.backgroundImageSubtitle),
                value: _settingsService.showBackgroundImage,
                onChanged: (value) =>
                    _settingsService.setShowBackgroundImage(value),
              ),
              _buildSection(l10n.sectionBehavior),
              _buildSwitchTile(
                l10n.keepScreenOn,
                _settingsService.keepScreenOn,
                (value) {
                  _settingsService.setKeepScreenOn(value);
                  WakelockPlus.toggle(enable: value);
                },
              ),
              _buildSection(l10n.sectionDataManagement),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(l10n.clearHistory),
                subtitle: Text(l10n.clearHistorySubtitle),
                onTap: _clearHistory,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.clearFavorites),
                subtitle: Text(l10n.clearFavoritesSubtitle),
                onTap: _clearFavorites,
              ),
              _buildSection(l10n.sectionAbout),
              ListTile(
                leading: const Icon(Icons.web),
                title: Text(l10n.website),
                subtitle: const Text(AppLinks.websiteUrl),
                onTap: () => _launchUrl(AppLinks.websiteUrl),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: Text(l10n.contribute),
                subtitle: Text(l10n.githubRepo),
                onTap: () => _launchUrl(AppLinks.repositoryUrl),
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: Text(l10n.contactUs),
                subtitle: const Text(AppLinks.contactUrl),
                onTap: () => _launchUrl(AppLinks.contactUrl),
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: Text(l10n.rateApp),
                onTap: _showRateOptions,
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: Text(l10n.version),
                subtitle: Text('$_appVersion ($_buildNumber)'),
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2),
                title: Text(l10n.licenses),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationIcon: Image.asset(
                    AppAssets.appIcon,
                    width: 100,
                    height: 100,
                  ),
                  applicationName: l10n.appName,
                  applicationVersion: '$_appVersion ($_buildNumber)',
                  applicationLegalese: l10n.aboutDevelopers,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        l10n.applicationLegalese(
                          DateTime.now().year.toString(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (kDebugMode) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.blur_on),
                  title: Text(l10n.glassLabTitle),
                  subtitle: Text(l10n.glassLabSubtitle),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const GlassLabScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.widgets_outlined),
                  title: Text(l10n.glassCatalogTitle),
                  subtitle: Text(l10n.glassCatalogSubtitle),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const GlassCatalogScreen(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildHymnalSelector() {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.book),
      title: Text(l10n.selectedHymnal),
      subtitle: Text(
        _settingsService.selectedHymnal != null
            ? '${_settingsService.selectedHymnal?.name} • ${_settingsService.selectedHymnal?.detail}'
            : l10n.none,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _showHymnalSelector,
    );
  }

  Widget _buildThemeSelector() {
    final l10n = AppLocalizations.of(context)!;
    String themeLabel;
    switch (_settingsService.themeMode) {
      case 'light':
        themeLabel = l10n.themeLight;
        break;
      case 'dark':
        themeLabel = l10n.themeDark;
        break;
      default:
        themeLabel = l10n.themeSystem;
    }

    return ListTile(
      leading: const Icon(Icons.palette),
      title: Text(l10n.theme),
      subtitle: Text(themeLabel),
      trailing: const Icon(Icons.chevron_right),
      onTap: _showThemeSelector,
    );
  }

  Widget _buildFontSizeSlider() {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.format_size),
      title: Text(l10n.fontSize),
      subtitle: Slider(
        value: _settingsService.fontSize,
        min: 12,
        max: 32,
        divisions: 10,
        label: _settingsService.fontSize.round().toString(),
        onChanged: (value) => _settingsService.setFontSize(value),
      ),
    );
  }

  /// "Cristal: Transparente ↔ Tintado". Con alto contraste el cristal va
  /// siempre tintado y el deslizador queda desactivado.
  Widget _buildGlassTintSlider() {
    final l10n = AppLocalizations.of(context)!;
    final forced = MediaQuery.highContrastOf(context);
    final caption = Theme.of(context).textTheme.bodySmall;
    return ListTile(
      leading: const Icon(Icons.blur_on_rounded),
      title: Text(l10n.glassTint),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Slider(
            value: forced ? 1 : _settingsService.glassTint,
            onChanged: forced ? null : _settingsService.setGlassTint,
            semanticFormatterCallback: (value) =>
                '${l10n.glassTint}: ${(value * 100).round()} %',
          ),
          Row(
            children: [
              Text(l10n.glassTransparent, style: caption),
              const Spacer(),
              Text(l10n.glassTinted, style: caption),
            ],
          ),
          if (forced) Text(l10n.glassTintForced, style: caption),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      secondary: const Icon(Icons.settings),
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

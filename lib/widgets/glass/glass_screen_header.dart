import 'package:flutter/material.dart';
import 'package:hymnal_app/styles/glass/glass_tokens.dart';
import 'package:hymnal_app/styles/glass/glass_typography.dart';
import 'package:hymnal_app/widgets/glass/glass_card.dart';
import 'package:hymnal_app/widgets/glass/glass_icon_button.dart';

/// Encabezado de pantalla del lienzo: Volver (si se puede), una línea
/// pequeña opcional encima y el título grande; acciones a la derecha.
///
/// Debe ir dentro de una zona de cristal (`GlassZone`).
class GlassScreenHeader extends StatelessWidget {
  const GlassScreenHeader({
    required this.title,
    this.overline,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? overline;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final overline = this.overline;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (canPop) ...[
          GlassIconButton(
            icon: Icons.chevron_left_rounded,
            semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: GlassMetrics.gapS),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (overline != null)
                Text(
                  overline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GlassTypography.listRow(tokens.textSecondary)
                      .copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GlassTypography.screenTitle(tokens.textPrimary),
                ),
              ),
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}

/// Estado vacío de una lista: ícono grande y uno o dos textos.
class GlassEmptyState extends StatelessWidget {
  const GlassEmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final subtitle = this.subtitle;
    // Sobre una tarjeta de cristal legible: se lee sobre cualquier foto.
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: tokens.textSecondary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GlassTypography.listRow(
                tokens.textPrimary,
                selected: true,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: GlassTypography.ui,
                  fontSize: 13,
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

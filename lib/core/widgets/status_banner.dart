import 'package:calcademy/app/theme/app_radius.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum StatusBannerTone { info, warning, error, success }

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    required this.message,
    this.tone = StatusBannerTone.info,
    this.title,
    super.key,
  });

  final String? title;
  final String message;
  final StatusBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground, icon) = switch (tone) {
      StatusBannerTone.info => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
        Icons.info_outline_rounded,
      ),
      StatusBannerTone.warning => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
        Icons.warning_amber_rounded,
      ),
      StatusBannerTone.error => (
        colors.errorContainer,
        colors.onErrorContainer,
        Icons.error_outline_rounded,
      ),
      StatusBannerTone.success => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        Icons.check_circle_outline_rounded,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.control,
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: foreground),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title case final title?) ...[
                    Text(
                      title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(color: foreground),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                  ],
                  Text(
                    message,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: foreground),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

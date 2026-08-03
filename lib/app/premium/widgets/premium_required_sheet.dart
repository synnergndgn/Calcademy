import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

Future<void> showPremiumRequiredSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.t('premiumRequired'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(context.l10n.t('premiumOperatingCostNotice')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: null,
                child: Text(context.l10n.t('comingSoon')),
              ),
            ],
          ),
        ),
      ),
    );

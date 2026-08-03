import 'package:calcademy/app/premium/premium_feature.dart';
import 'package:calcademy/app/premium/widgets/premium_gate_card.dart';
import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class CameraSolverPage extends StatelessWidget {
  const CameraSolverPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('camera-solver-page'),
    appBar: AppBar(title: Text(context.l10n.t('cameraSolver'))),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxContentWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Icon(
                Icons.document_scanner_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.t('cameraSolverComingSoon'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              PremiumGateCard(
                feature: PremiumFeature.cameraSolver,
                title: context.l10n.t('cameraSolver'),
                benefits: [
                  context.l10n.t('cameraNoPermission'),
                  context.l10n.t('cameraNoOcr'),
                  context.l10n.t('cameraNoUpload'),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

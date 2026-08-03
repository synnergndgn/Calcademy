import 'package:calcademy/app/auth/auth_gate_controller.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/premium/premium_feature.dart';
import 'package:calcademy/app/premium/premium_gate_controller.dart';
import 'package:calcademy/app/premium/widgets/premium_badge.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PremiumGateCard extends ConsumerWidget {
  const PremiumGateCard({
    super.key,
    required this.feature,
    required this.title,
    required this.benefits,
    this.compact = false,
  });

  final PremiumFeature feature;
  final String title;
  final List<String> benefits;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(premiumGateControllerProvider);
    final auth = ref.watch(authGateControllerProvider);
    final active = entitlement.canUse(feature);
    return Card(
      key: Key('premium-gate-${feature.name}'),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(active ? Icons.auto_awesome_rounded : Icons.lock_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: PremiumBadge(active: active),
            ),
            const SizedBox(height: 8),
            Text(context.l10n.t('premiumOperatingCostNotice')),
            if (!compact) ...[
              const SizedBox(height: 8),
              for (final benefit in benefits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_rounded, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(benefit)),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 8),
            if (auth.status == AuthStatus.signedOut)
              Text(
                context.l10n.t('signInRequired'),
                key: const Key('premium-sign-in-required'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const Key('premium-subscribe-placeholder'),
                  onPressed: null,
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: Text(context.l10n.t('subscribe')),
                ),
                if (auth.status == AuthStatus.signedOut)
                  OutlinedButton(
                    key: const Key('premium-sign-in-placeholder'),
                    onPressed: null,
                    child: Text(context.l10n.t('signIn')),
                  ),
                Chip(label: Text(context.l10n.t('comingSoon'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

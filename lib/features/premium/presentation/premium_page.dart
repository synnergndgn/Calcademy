import 'package:calcademy/app/auth/auth_gate_controller.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/premium/premium_feature.dart';
import 'package:calcademy/app/premium/premium_gate_controller.dart';
import 'package:calcademy/app/premium/widgets/premium_badge.dart';
import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PremiumPage extends ConsumerWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(premiumGateControllerProvider);
    final auth = ref.watch(authGateControllerProvider);
    final benefits = [
      ('premiumGeminiAssistant', Icons.auto_awesome_rounded),
      ('cameraSolver', Icons.document_scanner_outlined),
      ('removeAds', Icons.block_rounded),
      ('higherDailyLimits', Icons.speed_rounded),
    ];
    return Scaffold(
      key: const Key('premium-page'),
      appBar: AppBar(title: Text(context.l10n.t('calcademyPremium'))),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxContentWidth,
              ),
              child: ListView(
                key: const Key('premium-scroll'),
                padding: EdgeInsets.fromLTRB(
                  AppBreakpoints.pagePadding(constraints.maxWidth).left,
                  AppSpacing.md,
                  AppBreakpoints.pagePadding(constraints.maxWidth).right,
                  MediaQuery.paddingOf(context).bottom + AppSpacing.xxl,
                ),
                children: [
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.t('calcademyPremium'),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          PremiumBadge(active: entitlement.isPremium),
                          Text(
                            context.l10n.t(
                              entitlement.isPremium
                                  ? 'premiumActive'
                                  : 'freePlan',
                            ),
                            key: const Key('premium-current-status'),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(context.l10n.t('basicToolsNoAccount')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    context.l10n.t('premiumBenefits'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final benefit in benefits)
                    Card(
                      child: ListTile(
                        leading: Icon(benefit.$2),
                        title: Text(context.l10n.t(benefit.$1)),
                        trailing: const Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  if (auth.status == AuthStatus.signedOut)
                    Card(
                      child: ListTile(
                        key: const Key('premium-auth-placeholder'),
                        leading: const Icon(Icons.person_outline_rounded),
                        title: Text(context.l10n.t('signInRequired')),
                        subtitle: Text(context.l10n.t('accountDeletionFuture')),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      OutlinedButton(
                        key: const Key('premium-sign-in-button'),
                        onPressed: null,
                        child: Text(context.l10n.t('signIn')),
                      ),
                      OutlinedButton(
                        key: const Key('premium-create-account-button'),
                        onPressed: null,
                        child: Text(context.l10n.t('createAccount')),
                      ),
                      FilledButton(
                        key: const Key('premium-subscribe-button'),
                        onPressed: null,
                        child: Text(context.l10n.t('subscribe')),
                      ),
                      TextButton(
                        key: const Key('premium-manage-button'),
                        onPressed: null,
                        child: Text(context.l10n.t('manageSubscription')),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.t('premiumComingSoonNotice'),
                    key: const Key('premium-coming-soon'),
                  ),
                  if (entitlement.canUse(PremiumFeature.removeAds))
                    Text(context.l10n.t('removeAdsActive')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

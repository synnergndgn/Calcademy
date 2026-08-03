import 'package:calcademy/app/app_metadata.dart';
import 'package:calcademy/app/auth/auth_gate_controller.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/billing/billing_controller.dart';
import 'package:calcademy/app/billing/billing_state.dart';
import 'package:calcademy/app/premium/premium_feature.dart';
import 'package:calcademy/app/premium/premium_gate_controller.dart';
import 'package:calcademy/app/premium/widgets/premium_badge.dart';
import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumPage extends ConsumerStatefulWidget {
  const PremiumPage({super.key});

  @override
  ConsumerState<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends ConsumerState<PremiumPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(billingControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final entitlement = ref.watch(premiumGateControllerProvider);
    final auth = ref.watch(authGateControllerProvider);
    final billing = ref.watch(billingControllerProvider);
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
                  _StatusCard(
                    isPremium: entitlement.isPremium,
                    email: auth.user?.email,
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
                  if (auth.status != AuthStatus.signedIn)
                    _SignedOutBillingCard(authStatus: auth.status)
                  else
                    _BillingCard(
                      billing: billing,
                      onSubscribe: () => ref
                          .read(billingControllerProvider.notifier)
                          .subscribe(),
                      onRestore: () => ref
                          .read(billingControllerProvider.notifier)
                          .restorePurchases(),
                      onManage: billing.isAvailable
                          ? _manageGooglePlaySubscription
                          : null,
                    ),
                  if (entitlement.canUse(PremiumFeature.removeAds)) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(context.l10n.t('removeAdsActive')),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _manageGooglePlaySubscription() async {
    final productId = ref.read(billingControllerProvider.notifier).productId;
    final uri = Uri.https('play.google.com', '/store/account/subscriptions', {
      'sku': productId,
      'package': AppMetadata.applicationId,
    });
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('billingUnavailable'))),
      );
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.isPremium, required this.email});

  final bool isPremium;
  final String? email;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.t('premiumSubscription'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          PremiumBadge(active: isPremium),
          Text(
            context.l10n.t('currentPlan'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Text(
            context.l10n.t(
              isPremium ? 'premiumActive' : 'noActiveSubscription',
            ),
            key: const Key('premium-current-status'),
          ),
          if (email case final value?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(value, key: const Key('premium-user-email')),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(context.l10n.t('basicToolsNoAccount')),
        ],
      ),
    ),
  );
}

class _SignedOutBillingCard extends StatelessWidget {
  const _SignedOutBillingCard({required this.authStatus});

  final AuthStatus authStatus;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('premium-auth-placeholder'),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline_rounded),
            title: Text(context.l10n.t('premiumRequiresAccount')),
            subtitle: Text(context.l10n.t('signInToSubscribe')),
          ),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              FilledButton(
                key: const Key('premium-sign-in-button'),
                onPressed: () => context.push(
                  authStatus == AuthStatus.signedOut ? '/sign-in' : '/account',
                ),
                child: Text(context.l10n.t('signIn')),
              ),
              OutlinedButton(
                key: const Key('premium-create-account-button'),
                onPressed: () => context.push('/create-account'),
                child: Text(context.l10n.t('createAccount')),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _BillingCard extends StatelessWidget {
  const _BillingCard({
    required this.billing,
    required this.onSubscribe,
    required this.onRestore,
    required this.onManage,
  });

  final BillingState billing;
  final VoidCallback onSubscribe;
  final VoidCallback onRestore;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final product = billing.primaryProduct;
    final canPurchase =
        billing.status == BillingStatus.available && product != null;
    return Card(
      key: const Key('premium-billing-section'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.t('monthlyPlan'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            if (billing.status == BillingStatus.loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator(
                    key: Key('premium-product-loading'),
                  ),
                ),
              )
            else if (billing.status == BillingStatus.unavailable)
              Text(
                context.l10n.t('billingUnavailableDevice'),
                key: const Key('premium-billing-unavailable'),
              )
            else if (product != null) ...[
              Text(product.title, key: const Key('premium-product-title')),
              Text(
                product.price,
                key: const Key('premium-product-price'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(product.description),
            ] else
              Text(context.l10n.t('billingUnavailable')),
            if (billing.isPurchasePending) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.t('purchasePending'),
                key: const Key('premium-purchase-pending'),
              ),
            ],
            if (billing.isPendingValidation) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.t('purchaseReceived'),
                key: const Key('premium-purchase-received'),
              ),
              Text(context.l10n.t(billing.validationResult!.messageKey)),
            ],
            if (billing.errorMessage case final error?) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                error == 'signInToSubscribe' ? context.l10n.t(error) : error,
                key: const Key('premium-billing-error'),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                FilledButton(
                  key: const Key('premium-subscribe-button'),
                  onPressed: canPurchase ? onSubscribe : null,
                  child: Text(context.l10n.t('subscribe')),
                ),
                OutlinedButton(
                  key: const Key('premium-restore-button'),
                  onPressed: billing.isAvailable ? onRestore : null,
                  child: Text(context.l10n.t('restorePurchases')),
                ),
                TextButton(
                  key: const Key('premium-manage-button'),
                  onPressed: onManage,
                  child: Text(context.l10n.t('manageSubscription')),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(context.l10n.t('subscriptionManagedByGooglePlay')),
            Text(context.l10n.t('cancelAnytimeGooglePlay')),
            Text(context.l10n.t('purchasesProcessedGooglePlay')),
            if (billing.status == BillingStatus.unavailable)
              Text(context.l10n.t('billingComingSoon')),
          ],
        ),
      ),
    );
  }
}

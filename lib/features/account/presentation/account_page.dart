import 'package:calcademy/app/auth/auth_providers.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/account/presentation/widgets/auth_configuration_notice.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final signedIn = auth.status == AuthStatus.signedIn && auth.user != null;
    return Scaffold(
      key: const Key('account-page'),
      appBar: AppBar(title: Text(context.l10n.t('account'))),
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
                if (!auth.isConfigured) const AuthConfigurationNotice(),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          signedIn
                              ? Icons.account_circle_rounded
                              : Icons.person_outline_rounded,
                          size: 48,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          context.l10n.t(signedIn ? 'signedInAs' : 'signedOut'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (signedIn) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            auth.user!.label,
                            key: const Key('account-user-label'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Chip(label: Text(context.l10n.t('freePlan'))),
                          const SizedBox(height: AppSpacing.sm),
                          FilledButton.tonalIcon(
                            key: const Key('account-sign-out-button'),
                            onPressed: auth.isBusy
                                ? null
                                : () async {
                                    await ref
                                        .read(authControllerProvider.notifier)
                                        .signOut();
                                  },
                            icon: const Icon(Icons.logout_rounded),
                            label: Text(context.l10n.t('signOut')),
                          ),
                          OutlinedButton.icon(
                            key: const Key('account-delete-button'),
                            onPressed: () => context.push('/account/delete'),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: Text(context.l10n.t('deleteAccount')),
                          ),
                          TextButton.icon(
                            key: const Key('account-manage-subscription'),
                            onPressed: null,
                            icon: const Icon(Icons.workspace_premium_outlined),
                            label: Text(context.l10n.t('manageSubscription')),
                          ),
                        ] else ...[
                          const SizedBox(height: AppSpacing.sm),
                          FilledButton(
                            key: const Key('account-sign-in-button'),
                            onPressed: () => context.push('/sign-in'),
                            child: Text(context.l10n.t('signIn')),
                          ),
                          OutlinedButton(
                            key: const Key('account-create-button'),
                            onPressed: () => context.push('/create-account'),
                            child: Text(context.l10n.t('createAccount')),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Card(
                  key: const Key('account-no-login-notice'),
                  child: ListTile(
                    leading: const Icon(Icons.check_circle_outline_rounded),
                    title: Text(context.l10n.t('continueWithoutAccount')),
                    subtitle: Text(context.l10n.t('coreToolsNoAccount')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

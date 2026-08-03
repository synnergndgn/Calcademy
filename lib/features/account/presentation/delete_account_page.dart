import 'package:calcademy/app/auth/auth_providers.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final signedIn = auth.status == AuthStatus.signedIn && auth.user != null;
    final canRequest =
        signedIn &&
        auth.isConfigured &&
        auth.supportsAccountDeletion &&
        _confirmed &&
        !auth.isBusy;
    return Scaffold(
      key: const Key('delete-account-page'),
      appBar: AppBar(title: Text(context.l10n.t('accountDeletion'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxContentWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: Text(context.l10n.t('thisActionCannotBeUndone')),
                  subtitle: Text(context.l10n.t('accountDeletionExplanation')),
                ),
              ),
              if (!signedIn)
                Card(
                  child: ListTile(
                    title: Text(context.l10n.t('signedOut')),
                    subtitle: Text(context.l10n.t('premiumRequiresAccount')),
                    trailing: TextButton(
                      onPressed: () => context.push('/sign-in'),
                      child: Text(context.l10n.t('signIn')),
                    ),
                  ),
                ),
              if (!auth.supportsAccountDeletion)
                Card(
                  key: const Key('account-deletion-backend-notice'),
                  child: ListTile(
                    leading: const Icon(Icons.security_rounded),
                    title: Text(context.l10n.t('accountFeaturesComingSoon')),
                    subtitle: Text(
                      context.l10n.t('accountDeletionBackendRequired'),
                    ),
                  ),
                ),
              CheckboxListTile(
                key: const Key('delete-account-confirmation'),
                value: _confirmed,
                onChanged: signedIn
                    ? (value) => setState(() => _confirmed = value ?? false)
                    : null,
                title: Text(context.l10n.t('confirmAccountDeletion')),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              FilledButton.icon(
                key: const Key('request-account-deletion-button'),
                onPressed: canRequest ? _requestDeletion : null,
                icon: const Icon(Icons.delete_forever_outlined),
                label: Text(context.l10n.t('requestAccountDeletion')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestDeletion() async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .requestAccountDeletion();
    if (!mounted) return;
    final key = success ? 'accountDeletionRequested' : 'authenticationFailed';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.t(key))));
  }
}

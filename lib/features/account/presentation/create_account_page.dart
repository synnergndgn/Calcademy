import 'package:calcademy/app/auth/auth_providers.dart';
import 'package:calcademy/app/auth/auth_validators.dart';
import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/account/presentation/widgets/auth_configuration_notice.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateAccountPage extends ConsumerStatefulWidget {
  const CreateAccountPage({super.key});

  @override
  ConsumerState<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends ConsumerState<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      key: const Key('create-account-page'),
      appBar: AppBar(title: Text(context.l10n.t('createAccount'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.compact),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (!auth.isConfigured) const AuthConfigurationNotice(),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const Key('create-account-email'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.newUsername],
                      decoration: InputDecoration(
                        labelText: context.l10n.t('email'),
                      ),
                      validator: (value) =>
                          AuthValidators.isValidEmail(value ?? '')
                          ? null
                          : context.l10n.t('invalidEmail'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      key: const Key('create-account-password'),
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: context.l10n.t('password'),
                      ),
                      validator: (value) =>
                          AuthValidators.isValidPassword(value ?? '')
                          ? null
                          : context.l10n.t('passwordTooShort'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      key: const Key('create-account-confirm-password'),
                      controller: _confirmationController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: context.l10n.t('confirmPassword'),
                      ),
                      validator: (value) =>
                          AuthValidators.passwordsMatch(
                            _passwordController.text,
                            value ?? '',
                          )
                          ? null
                          : context.l10n.t('passwordsDoNotMatch'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      key: const Key('create-account-submit'),
                      onPressed: auth.isConfigured && !auth.isBusy
                          ? _submit
                          : null,
                      child: auth.isBusy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.l10n.t('createAccount')),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.l10n.t('createAccountLegalNote'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextButton(
                      onPressed: () => context.go('/sign-in'),
                      child: Text(context.l10n.t('signIn')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref
        .read(authControllerProvider.notifier)
        .signUp(_emailController.text, _passwordController.text);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('accountCreatedNotice'))),
      );
      context.go('/account');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('authenticationFailed'))),
      );
    }
  }
}

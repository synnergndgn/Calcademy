import 'package:calcademy/app/auth/auth_providers.dart';
import 'package:calcademy/app/auth/auth_validators.dart';
import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/account/presentation/widgets/auth_configuration_notice.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      key: const Key('sign-in-page'),
      appBar: AppBar(title: Text(context.l10n.t('signIn'))),
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
                      key: const Key('sign-in-email'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
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
                      key: const Key('sign-in-password'),
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: context.l10n.t('password'),
                      ),
                      validator: (value) =>
                          AuthValidators.isValidPassword(value ?? '')
                          ? null
                          : context.l10n.t('passwordTooShort'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      key: const Key('sign-in-submit'),
                      onPressed: auth.isConfigured && !auth.isBusy
                          ? _submit
                          : null,
                      child: auth.isBusy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.l10n.t('signIn')),
                    ),
                    TextButton(
                      key: const Key('forgot-password-button'),
                      onPressed: auth.isConfigured && !auth.isBusy
                          ? _resetPassword
                          : null,
                      child: Text(context.l10n.t('forgotPassword')),
                    ),
                    OutlinedButton(
                      onPressed: () => context.push('/create-account'),
                      child: Text(context.l10n.t('createAccount')),
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
        .signIn(_emailController.text, _passwordController.text);
    if (!mounted) return;
    if (success) {
      context.go('/account');
    } else {
      _showFeedback(
        ref.read(authControllerProvider).errorKey ?? 'authenticationFailed',
      );
    }
  }

  Future<void> _resetPassword() async {
    if (!AuthValidators.isValidEmail(_emailController.text)) {
      _formKey.currentState?.validate();
      return;
    }
    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(_emailController.text);
    if (!mounted) return;
    _showFeedback(
      success
          ? 'passwordResetSent'
          : ref.read(authControllerProvider).errorKey ?? 'authenticationFailed',
    );
  }

  void _showFeedback(String key) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.t(key))));
  }
}

import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AuthConfigurationNotice extends StatelessWidget {
  const AuthConfigurationNotice({super.key});

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('auth-not-configured-notice'),
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: ListTile(
      leading: const Icon(Icons.cloud_off_outlined),
      title: Text(context.l10n.t('authNotConfigured')),
      subtitle: Text(context.l10n.t('supabaseNotConfigured')),
    ),
  );
}

import 'package:calcademy/features/home/models/academy_module.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({required this.moduleId, super.key});
  final String moduleId;

  @override
  Widget build(BuildContext context) {
    final module = academyModules.firstWhere(
      (item) => item.id == moduleId,
      orElse: () => academyModules[1],
    );
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.t(module.titleKey))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      module.icon,
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.l10n.t('comingSoon'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.t(module.titleKey),
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.t('plannedFeature'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.home_rounded),
                      label: Text(context.l10n.t('backHome')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

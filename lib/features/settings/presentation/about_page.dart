import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/calcademy_logo.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.t('about'))),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      children: [
                        const CalcademyLogo(
                          size: 92,
                          showWordmark: true,
                          showTagline: true,
                          direction: Axis.vertical,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          context.l10n.t('aboutBody'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.calculate_rounded),
                        title: Text(context.l10n.t('supportedModule')),
                        subtitle: Text(context.l10n.t('calculator')),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.school_outlined),
                        title: Text(context.l10n.t('futureModules')),
                        subtitle: Text(context.l10n.t('futureModulesBody')),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: Text(context.l10n.t('privacy')),
                        subtitle: Text(context.l10n.t('privacyBody')),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline_rounded),
                        title: Text(context.l10n.t('version')),
                      ),
                      ExpansionTile(
                        leading: const Icon(Icons.code_rounded),
                        title: Text(context.l10n.t('openSourceLicenses')),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              AppSpacing.md,
                            ),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton.icon(
                                onPressed: () => showLicensePage(
                                  context: context,
                                  applicationName: context.l10n.t('appName'),
                                  applicationVersion: '1.0.0',
                                ),
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: Text(context.l10n.t('viewLicenses')),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

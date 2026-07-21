import 'package:calcademy/app/app_metadata.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/calcademy_logo.dart';
import 'package:calcademy/core/widgets/section_header.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.t('aboutLegal'))),
    body: ListView(
      key: const Key('about-legal-scroll'),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        MediaQuery.paddingOf(context).bottom + AppSpacing.xxl,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      children: [
                        const CalcademyLogo(
                          size: 80,
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
                        const SizedBox(height: AppSpacing.md),
                        Semantics(
                          label:
                              '${context.l10n.t('versionLabel')} ${AppMetadata.versionName}',
                          child: Chip(
                            key: const Key('about-version'),
                            avatar: const Icon(Icons.info_outline_rounded),
                            label: Text(
                              '${context.l10n.t('versionLabel')} '
                              '${AppMetadata.versionName} '
                              '(${AppMetadata.versionCode})',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _AboutSection(
                  sectionKey: const Key('about-privacy-section'),
                  title: context.l10n.t('dataHandling'),
                  icon: Icons.privacy_tip_outlined,
                  children: [
                    Text(
                      context.l10n.t('privacyPolicyBody'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InformationRow(
                      icon: Icons.storage_rounded,
                      title: context.l10n.t('localStorage'),
                      body: context.l10n.t('localStorageBody'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _PrivacyFlag(
                          icon: Icons.block_rounded,
                          label: context.l10n.t('noAds'),
                        ),
                        _PrivacyFlag(
                          icon: Icons.analytics_outlined,
                          label: context.l10n.t('noAnalytics'),
                        ),
                        _PrivacyFlag(
                          icon: Icons.cloud_off_outlined,
                          label: context.l10n.t('noCloudSync'),
                        ),
                        _PrivacyFlag(
                          icon: Icons.person_off_outlined,
                          label: context.l10n.t('noAccount'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _AboutSection(
                  sectionKey: const Key('about-legal-section'),
                  title: context.l10n.t('educationalUse'),
                  icon: Icons.school_outlined,
                  children: [
                    _InformationRow(
                      icon: Icons.calculate_outlined,
                      title: context.l10n.t('educationalUse'),
                      body: context.l10n.t('educationalUseBody'),
                    ),
                    const Divider(height: AppSpacing.xxl),
                    _InformationRow(
                      icon: Icons.account_balance_outlined,
                      title: context.l10n.t('financialDisclaimer'),
                      body: context.l10n.t('financialDisclaimerBody'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _AboutSection(
                  title: context.l10n.t('contact'),
                  icon: Icons.contact_support_outlined,
                  children: [
                    _InformationRow(
                      icon: Icons.mail_outline_rounded,
                      title: context.l10n.t('contact'),
                      body: context.l10n.t('contactBody'),
                    ),
                    const Divider(height: AppSpacing.xxl),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.code_rounded),
                      title: Text(context.l10n.t('openSourceLicenses')),
                      subtitle: Text(context.l10n.t('openSourceLicensesBody')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: AppMetadata.name,
                        applicationVersion: AppMetadata.versionName,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.title,
    required this.icon,
    required this.children,
    this.sectionKey,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Key? sectionKey;

  @override
  Widget build(BuildContext context) => Column(
    key: sectionKey,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionHeader(title: title, icon: icon),
      const SizedBox(height: AppSpacing.sm),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ],
  );
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _PrivacyFlag extends StatelessWidget {
  const _PrivacyFlag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 18),
    label: Text(label),
    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    side: BorderSide.none,
  );
}

import 'package:calcademy/features/history/presentation/history_controller.dart';
import 'package:calcademy/features/home/models/academy_module.dart';
import 'package:calcademy/features/settings/presentation/settings_controller.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(historyProvider).take(3).toList();
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.t('appName')),
        actions: [
          IconButton(
            tooltip: context.l10n.t('theme'),
            onPressed: () {
              final next = settings.themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
              ref.read(settingsProvider.notifier).setThemeMode(next);
            },
            icon: Icon(
              settings.themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _HeroCard()),
          SliverToBoxAdapter(child: _SectionTitle(context.l10n.t('available'))),
          SliverToBoxAdapter(child: _ModuleCard(module: academyModules.first)),
          SliverToBoxAdapter(child: _SectionTitle(context.l10n.t('recent'))),
          SliverToBoxAdapter(
            child: recent.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.history_toggle_off_rounded),
                        title: Text(context.l10n.t('noRecent')),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: Column(
                        children: [
                          for (final item in recent)
                            ListTile(
                              title: Text(
                                item.expression,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('= ${item.result}'),
                              trailing: const Icon(Icons.arrow_forward_rounded),
                              onTap: () => context.push(
                                '/calculator?expression=${Uri.encodeQueryComponent(item.expression)}',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
          SliverToBoxAdapter(
            child: _SectionTitle(context.l10n.t('comingSoon')),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final columns = width >= 1000
                    ? 3
                    : width >= 620
                    ? 2
                    : 1;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: columns == 1 ? 2.7 : 1.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ModuleCard(
                      module: academyModules[index + 1],
                      compact: true,
                    ),
                    childCount: academyModules.length - 1,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.primary, colors.tertiary]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.t('welcome'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.t('welcomeBody'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: colors.onPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.t('tagline'),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: colors.onPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(Icons.auto_graph_rounded, size: 64, color: colors.onPrimary),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    ),
  );
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, this.compact = false});
  final AcademyModule module;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => module.available
            ? context.push('/calculator')
            : context.push('/coming-soon/${module.id}'),
        child: Padding(
          padding: EdgeInsets.all(compact ? 16 : 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  module.icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.t(module.titleKey),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      module.available
                          ? context.l10n.t('calculatorDescription')
                          : context.l10n.t('plannedFeature'),
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  context.l10n.t(module.available ? 'open' : 'comingSoon'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return compact
        ? card
        : Padding(padding: const EdgeInsets.only(bottom: 4), child: card);
  }
}

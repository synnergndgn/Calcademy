import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_colors.dart';
import 'package:calcademy/app/theme/app_radius.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/calcademy_logo.dart';
import 'package:calcademy/core/widgets/empty_state.dart';
import 'package:calcademy/core/widgets/section_header.dart';
import 'package:calcademy/features/history/domain/calculation_record.dart';
import 'package:calcademy/features/history/presentation/history_controller.dart';
import 'package:calcademy/features/home/models/academy_module.dart';
import 'package:calcademy/features/home/presentation/widgets/professional_module_card.dart';
import 'package:calcademy/features/settings/presentation/settings_controller.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recent = ref.watch(historyProvider).take(3).toList(growable: false);
    final query = _searchController.text.trim().toLowerCase();
    final matchingModules = academyModules
        .where((module) => _matches(module, query))
        .toList(growable: false);
    final available = matchingModules.where((module) => module.available);
    final coming = matchingModules
        .where((module) => !module.available)
        .toList();
    final hasResults = matchingModules.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const _HomeBrand(),
        actions: const [
          _AboutButton(),
          _ThemeButton(),
          SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => CustomScrollView(
          key: const Key('home-scroll'),
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppBreakpoints.maxContentWidth,
                  ),
                  child: Padding(
                    padding: AppBreakpoints.pagePadding(constraints.maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.xs),
                        _HeroCard(
                          availableCount: academyModules
                              .where((module) => module.available)
                              .length,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ModuleSearchField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          onClear: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        if (!hasResults)
                          Card(
                            child: EmptyState(
                              key: const Key('home-search-empty'),
                              icon: Icons.search_off_rounded,
                              title: context.l10n.t('homeNoResultsTitle'),
                              body: context.l10n.t('homeNoResultsBody'),
                            ),
                          )
                        else ...[
                          for (final category in AcademyModuleCategory.values)
                            if (available.any(
                              (module) => module.category == category,
                            )) ...[
                              _ModuleCategorySection(
                                category: category,
                                modules: available
                                    .where(
                                      (module) => module.category == category,
                                    )
                                    .toList(growable: false),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          if (query.isEmpty) ...[
                            SectionHeader(
                              title: context.l10n.t('recent'),
                              icon: Icons.history_rounded,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _RecentCalculations(records: recent),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                          if (coming.isNotEmpty) ...[
                            SectionHeader(
                              title: context.l10n.t('comingSoon'),
                              subtitle: context.l10n.t('homeComingSoonBody'),
                              icon: Icons.explore_outlined,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _ResponsiveModuleGrid(modules: coming),
                          ],
                        ],
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matches(AcademyModule module, String query) {
    if (query.isEmpty) return true;
    final searchable = [
      context.l10n.t(module.titleKey),
      context.l10n.t(module.descriptionKey),
      context.l10n.t(module.category.localizationKey),
    ].join(' ').toLowerCase();
    return searchable.contains(query);
  }
}

class _HomeBrand extends StatelessWidget {
  const _HomeBrand();

  @override
  Widget build(BuildContext context) {
    final compactAccessibilityLayout =
        MediaQuery.sizeOf(context).width < 360 &&
        MediaQuery.textScalerOf(context).scale(1) > 1.2;
    return CalcademyLogo(size: 36, showWordmark: !compactAccessibilityLayout);
  }
}

class _ThemeButton extends ConsumerWidget {
  const _ThemeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: context.l10n.t('theme'),
      onPressed: () => ref
          .read(settingsProvider.notifier)
          .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
      icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
    );
  }
}

class _AboutButton extends StatelessWidget {
  const _AboutButton();

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('home-about-action'),
    tooltip: context.l10n.t('aboutLegal'),
    onPressed: () => context.push('/about'),
    icon: const Icon(Icons.info_outline_rounded),
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.availableCount});

  final int availableCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.t('homeHeroEyebrow').toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.primary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.t('welcome'),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.t('welcomeBody'),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _HeroMetric(
              icon: Icons.dashboard_customize_outlined,
              label: '$availableCount ${context.l10n.t('homeTools')}',
            ),
            _HeroMetric(
              icon: Icons.offline_bolt_outlined,
              label: context.l10n.t('homeOffline'),
            ),
            _HeroMetric(
              icon: Icons.lock_outline_rounded,
              label: context.l10n.t('homeOnDevice'),
            ),
          ],
        ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: AppRadius.hero,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _GraphAccent(),
                  const SizedBox(height: AppSpacing.lg),
                  copy,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: AppSpacing.xl),
                const _GraphAccent(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.72),
          borderRadius: AppRadius.button,
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: colors.primary),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphAccent extends StatelessWidget {
  const _GraphAccent();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.78),
            borderRadius: AppRadius.card,
          ),
          child: Icon(
            Icons.auto_graph_rounded,
            size: 48,
            color: colors.primary,
          ),
        ),
        const Positioned(
          right: 10,
          bottom: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.dataPoint,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(dimension: 11),
          ),
        ),
      ],
    );
  }
}

class _ModuleSearchField extends StatelessWidget {
  const _ModuleSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => TextField(
    key: const Key('home-module-search'),
    controller: controller,
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      labelText: context.l10n.t('homeSearchLabel'),
      hintText: context.l10n.t('homeSearchHint'),
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: controller.text.isEmpty
          ? null
          : IconButton(
              tooltip: context.l10n.t('clear'),
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            ),
    ),
  );
}

class _ModuleCategorySection extends StatelessWidget {
  const _ModuleCategorySection({required this.category, required this.modules});

  final AcademyModuleCategory category;
  final List<AcademyModule> modules;

  @override
  Widget build(BuildContext context) => Column(
    key: Key('home-category-${category.name}'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionHeader(
        title: context.l10n.t(category.localizationKey),
        subtitle: context.l10n.t('${category.localizationKey}Description'),
        icon: _categoryIcon(category),
      ),
      const SizedBox(height: AppSpacing.sm),
      _ResponsiveModuleGrid(modules: modules),
    ],
  );

  static IconData _categoryIcon(AcademyModuleCategory category) =>
      switch (category) {
        AcademyModuleCategory.mathematics => Icons.functions_rounded,
        AcademyModuleCategory.optimization => Icons.route_rounded,
        AcademyModuleCategory.data => Icons.query_stats_rounded,
        AcademyModuleCategory.finance => Icons.account_balance_rounded,
        AcademyModuleCategory.workspace => Icons.workspaces_outline,
      };
}

class _ResponsiveModuleGrid extends StatelessWidget {
  const _ResponsiveModuleGrid({required this.modules});

  final List<AcademyModule> modules;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = AppBreakpoints.gridColumns(constraints.maxWidth);
      final width =
          (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final module in modules)
            SizedBox(
              width: width,
              child: ProfessionalModuleCard(module: module),
            ),
        ],
      );
    },
  );
}

class _RecentCalculations extends StatelessWidget {
  const _RecentCalculations({required this.records});

  final List<CalculationRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Card(
        child: EmptyState(
          icon: Icons.history_toggle_off_rounded,
          title: context.l10n.t('noRecentTitle'),
          body: context.l10n.t('noRecent'),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final item in records)
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
    );
  }
}

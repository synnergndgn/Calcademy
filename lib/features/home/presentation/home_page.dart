import 'package:calcademy/app/ads/ad_banner.dart';
import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/calcademy_design.dart';
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
  AcademyModuleCategory? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recent = ref.watch(historyProvider).take(3).toList(growable: false);
    final query = _searchController.text.trim().toLowerCase();
    final modules = academyModules;
    final matchingModules = modules
        .where(
          (module) =>
              _matches(module, query) &&
              (_selectedCategory == null ||
                  module.category == _selectedCategory),
        )
        .toList(growable: false);
    final available = matchingModules
        .where((module) => module.available)
        .toList(growable: false);
    final coming = matchingModules
        .where((module) => !module.available)
        .toList();
    final hasResults = matchingModules.isNotEmpty;
    final quickAccess = [
      for (final id in visibleQuickAccessModuleIds())
        modules.firstWhere((module) => module.id == id),
    ];

    return CalcademyScaffold(
      title: const _HomeBrand(),
      actions: const [
        _AboutButton(),
        _ThemeButton(),
        SizedBox(width: AppSpacing.xs),
      ],
      // Low-intrusion anchored banner below the module grid. Renders nothing
      // until an ad loads, so it never affects layout in tests or offline.
      bottomNavigationBar: const AdBanner(),
      body: SafeArea(
        key: const Key('home-safe-area'),
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: LayoutBuilder(
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
                          const _HeroCard(),
                          const SizedBox(height: AppSpacing.md),
                          _ModuleSearchField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            onClear: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SectionHeader(
                            key: const Key('home-quick-access-header'),
                            title: context.l10n.t('quickAccess'),
                            subtitle: context.l10n.t('quickAccessDescription'),
                            icon: Icons.bolt_rounded,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _QuickAccessGrid(modules: quickAccess),
                          const SizedBox(height: AppSpacing.lg),
                          SectionHeader(
                            key: const Key('home-tool-categories-header'),
                            title: context.l10n.t('toolCategories'),
                            icon: Icons.category_outlined,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _HomeCategoryFilter(
                            selected: _selectedCategory,
                            onSelected: (category) =>
                                setState(() => _selectedCategory = category),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (!hasResults)
                            EmptyState(
                              key: const Key('home-search-empty'),
                              icon: Icons.search_off_rounded,
                              title: context.l10n.t('homeNoResultsTitle'),
                              body: context.l10n.t('homeNoResultsBody'),
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
                            if (query.isEmpty && _selectedCategory == null) ...[
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
                          const SizedBox(
                            key: Key('home-bottom-spacer'),
                            height: AppSpacing.xxl,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
      ...module.searchTerms,
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
  const _HeroCard();

  @override
  Widget build(BuildContext context) => StudyHeader(
    eyebrow: context.l10n.t('homeHeroEyebrow'),
    title: context.l10n.t('homeReadyTitle'),
    subtitle: context.l10n.t('welcomeBody'),
    formula: 'Think  ·  Calculate  ·  Remember',
  );
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

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid({required this.modules});

  final List<AcademyModule> modules;

  @override
  Widget build(BuildContext context) {
    final moduleItems = {
      for (final module in modules)
        module.id: ToolDockItem(
          key: Key('quick-access-${module.id}'),
          icon: module.icon,
          label: context.l10n.t(module.titleKey),
          onTap: () => context.push(module.route!),
        ),
    };
    moduleItems.remove('calculator');
    final items = <ToolDockItem>[
      ToolDockItem(
        key: const Key('quick-access-calculator'),
        icon: Icons.calculate_rounded,
        label: context.l10n.t('calculator'),
        onTap: () => context.push('/calculator'),
      ),
      ToolDockItem(
        key: const Key('quick-access-history'),
        icon: Icons.history_rounded,
        label: context.l10n.t('history'),
        onTap: () => context.push('/history'),
      ),
      if (moduleItems.remove('saved') case final saved?)
        saved
      else
        ToolDockItem(
          key: const Key('quick-access-saved'),
          icon: Icons.bookmarks_rounded,
          label: context.l10n.t('saved'),
          onTap: () => context.push('/saved'),
        ),
      ToolDockItem(
        key: const Key('quick-access-settings'),
        icon: Icons.tune_rounded,
        label: context.l10n.t('settings'),
        onTap: () => context.push('/settings'),
      ),
      ToolDockItem(
        key: const Key('quick-access-about'),
        icon: Icons.school_outlined,
        label: context.l10n.t('about'),
        onTap: () => context.push('/about'),
      ),
      ...moduleItems.values,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = constraints.maxWidth >= AppBreakpoints.expanded
            ? items.length
            : 5;
        final groups = <List<ToolDockItem>>[];
        for (var index = 0; index < items.length; index += perRow) {
          final end = index + perRow < items.length
              ? index + perRow
              : items.length;
          groups.add(items.sublist(index, end));
        }
        return Column(
          key: const Key('home-quick-access'),
          children: [
            for (var index = 0; index < groups.length; index++) ...[
              ToolDock(items: groups[index]),
              if (index != groups.length - 1)
                const SizedBox(height: AppSpacing.xs),
            ],
          ],
        );
      },
    );
  }
}

class _HomeCategoryFilter extends StatelessWidget {
  const _HomeCategoryFilter({required this.selected, required this.onSelected});

  final AcademyModuleCategory? selected;
  final ValueChanged<AcademyModuleCategory?> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const Key('home-category-filter'),
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        ChoiceChip(
          key: const Key('home-category-filter-all'),
          label: Text(context.l10n.t('allTools')),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),
        const SizedBox(width: AppSpacing.xs),
        for (final category in AcademyModuleCategory.values) ...[
          ChoiceChip(
            key: Key('home-category-filter-${category.name}'),
            label: Text(context.l10n.t(category.localizationKey)),
            selected: selected == category,
            onSelected: (_) => onSelected(category),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ],
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
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final columns = switch (constraints.maxWidth) {
        >= AppBreakpoints.expanded => 4,
        >= AppBreakpoints.compact => 3,
        _ when textScale <= 1.3 => 2,
        _ => 1,
      };
      final width =
          (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final module in modules)
            SizedBox(
              width: width,
              child: RepaintBoundary(
                child: ProfessionalModuleCard(module: module, compact: true),
              ),
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
      return EmptyState(
        icon: Icons.history_toggle_off_rounded,
        title: context.l10n.t('noRecentTitle'),
        body: context.l10n.t('noRecent'),
      );
    }
    return Column(
      children: [
        for (var index = 0; index < records.length; index++)
          TimelineCalculationItem(
            expression: records[index].expression,
            result: records[index].result,
            metadata: records[index].angleMode.name == 'degrees'
                ? 'DEG'
                : 'RAD',
            isLast: index == records.length - 1,
            actions: const [],
            onTap: () => context.push(
              '/calculator?expression='
              '${Uri.encodeQueryComponent(records[index].expression)}',
            ),
          ),
      ],
    );
  }
}

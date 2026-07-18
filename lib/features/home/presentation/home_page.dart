import 'package:calcademy/app/theme/app_colors.dart';
import 'package:calcademy/app/theme/app_radius.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/calcademy_logo.dart';
import 'package:calcademy/core/widgets/empty_state.dart';
import 'package:calcademy/features/history/domain/calculation_record.dart';
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
    final availableModules = academyModules.where((item) => item.available);
    final comingModules = academyModules.where((item) => !item.available);
    return Scaffold(
      appBar: AppBar(
        title: const _HomeBrand(),
        actions: const [
          _ThemeButton(),
          SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _HeroCard()),
          SliverToBoxAdapter(child: _SectionTitle(context.l10n.t('available'))),
          SliverToBoxAdapter(
            child: Column(
              children: [
                for (final module in availableModules)
                  _ModuleCard(module: module),
              ],
            ),
          ),
          SliverToBoxAdapter(child: _SectionTitle(context.l10n.t('recent'))),
          SliverToBoxAdapter(child: _RecentCalculations(records: recent)),
          SliverToBoxAdapter(
            child: _SectionTitle(context.l10n.t('comingSoon')),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 960
                      ? 3
                      : constraints.maxWidth >= 600
                      ? 2
                      : 1;
                  final itemWidth =
                      (constraints.maxWidth - AppSpacing.sm * (columns - 1)) /
                      columns;
                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final module in comingModules)
                        SizedBox(
                          width: itemWidth,
                          child: _ModuleCard(module: module, compact: true),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
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

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.t('welcome'),
          style: theme.textTheme.headlineSmall?.copyWith(
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
      ],
    );
    const graphic = _GraphAccent();

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: AppRadius.hero,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 340) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                graphic,
                const SizedBox(height: AppSpacing.md),
                copy,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: AppSpacing.lg),
              graphic,
            ],
          );
        },
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
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.7),
            borderRadius: AppRadius.card,
          ),
          child: Icon(
            Icons.auto_graph_rounded,
            size: 42,
            color: colors.primary,
          ),
        ),
        const Positioned(
          right: 8,
          bottom: 9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.dataPoint,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(dimension: 10),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xl,
      AppSpacing.lg,
      AppSpacing.sm,
    ),
    child: Row(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.dataPoint,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(dimension: 8),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
      ],
    ),
  );
}

class _RecentCalculations extends StatelessWidget {
  const _RecentCalculations({required this.records});

  final List<CalculationRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Card(
          child: EmptyState(
            icon: Icons.history_toggle_off_rounded,
            title: context.l10n.t('noRecentTitle'),
            body: context.l10n.t('noRecent'),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Card(
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
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, this.compact = false});

  final AcademyModule module;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final card = Card(
      margin: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: module.available
          ? colors.primaryContainer.withValues(alpha: 0.62)
          : colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => module.available
            ? context.push(module.route!)
            : context.push('/coming-soon/${module.id}'),
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: module.available
                      ? colors.primary
                      : colors.surfaceContainerHighest,
                  borderRadius: AppRadius.control,
                ),
                child: Icon(
                  module.icon,
                  color: module.available
                      ? colors.onPrimary
                      : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.t(module.titleKey),
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      context.l10n.t(module.descriptionKey),
                      maxLines: compact ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ModuleStatus(available: module.available),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
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

class _ModuleStatus extends StatelessWidget {
  const _ModuleStatus({required this.available});

  final bool available;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: available
              ? colors.secondaryContainer
              : colors.tertiaryContainer,
          borderRadius: AppRadius.button,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              available ? Icons.check_circle_outline : Icons.schedule_rounded,
              size: 15,
              color: available ? colors.primary : colors.tertiary,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                context.l10n.t(available ? 'availableStatus' : 'comingSoon'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: available
                      ? colors.onSecondaryContainer
                      : colors.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

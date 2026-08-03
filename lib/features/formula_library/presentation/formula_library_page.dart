import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/features/formula_library/application/formula_favorites_controller.dart';
import 'package:calcademy/features/formula_library/application/formula_search_controller.dart';
import 'package:calcademy/features/formula_library/presentation/widgets/formula_card.dart';
import 'package:calcademy/features/formula_library/presentation/widgets/formula_category_filter.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FormulaLibraryPage extends ConsumerStatefulWidget {
  const FormulaLibraryPage({super.key});

  @override
  ConsumerState<FormulaLibraryPage> createState() => _FormulaLibraryPageState();
}

class _FormulaLibraryPageState extends ConsumerState<FormulaLibraryPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final filter = ref.watch(formulaSearchProvider);
    final formulas = ref.watch(filteredFormulasProvider(language));
    final favorites = ref.watch(formulaFavoritesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.t('formulaLibraryTitle'))),
      body: SafeArea(
        key: const Key('formula-library-safe-area'),
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxContentWidth,
              ),
              child: CustomScrollView(
                key: const Key('formula-library-scroll'),
                slivers: [
                  SliverPadding(
                    padding: AppBreakpoints.pagePadding(constraints.maxWidth),
                    sliver: SliverList.list(
                      children: [
                        Text(
                          context.l10n.t('formulaLibraryTitle'),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(context.l10n.t('formulaLibrarySubtitle')),
                        const SizedBox(height: 20),
                        SegmentedButton<bool>(
                          key: const Key('formula-view-selector'),
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: false,
                              icon: const Icon(Icons.menu_book_outlined),
                              label: Text(
                                context.l10n.t('allFormulas'),
                                key: const Key('formula-view-all'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ButtonSegment(
                              value: true,
                              icon: const Icon(Icons.favorite_outline_rounded),
                              label: Text(
                                '${context.l10n.t('favorites')} (${favorites.length})',
                                key: const Key('formula-view-favorites'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          selected: {filter.favoritesOnly},
                          onSelectionChanged: (selection) => ref
                              .read(formulaSearchProvider.notifier)
                              .setFavoritesOnly(selection.single),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const Key('formula-search-field'),
                          controller: _searchController,
                          onChanged: ref
                              .read(formulaSearchProvider.notifier)
                              .setQuery,
                          decoration: InputDecoration(
                            labelText: context.l10n.t('searchFormulas'),
                            prefixIcon: const Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FormulaCategoryFilter(
                          selected: filter.category,
                          onSelected: ref
                              .read(formulaSearchProvider.notifier)
                              .setCategory,
                        ),
                        const SizedBox(height: 16),
                        if (filter.favoritesOnly && favorites.isEmpty)
                          Card(
                            key: const Key('formula-favorites-empty'),
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.favorite_border_rounded,
                                    size: 42,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.l10n.t('noFavoriteFormulasTitle'),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    context.l10n.t('noFavoriteFormulasBody'),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (formulas.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.search_off_rounded,
                                    size: 42,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(context.l10n.t('noFormulasFound')),
                                ],
                              ),
                            ),
                          )
                        else
                          for (final formula in formulas) ...[
                            FormulaCard(
                              formula: formula,
                              favorite: favorites.contains(formula.id),
                              onTap: () =>
                                  context.push('/formulas/${formula.id}'),
                              onFavorite: () => ref
                                  .read(formulaFavoritesProvider.notifier)
                                  .toggle(formula.id),
                            ),
                            const SizedBox(height: 8),
                          ],
                        const SizedBox(
                          key: Key('formula-library-bottom-spacer'),
                          height: 32,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

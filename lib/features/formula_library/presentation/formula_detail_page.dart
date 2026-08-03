import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/features/formula_library/application/formula_favorites_controller.dart';
import 'package:calcademy/features/formula_library/domain/formula_registry.dart';
import 'package:calcademy/features/formula_library/presentation/widgets/formula_example_section.dart';
import 'package:calcademy/features/formula_library/presentation/widgets/formula_tool_action_button.dart';
import 'package:calcademy/features/formula_library/presentation/widgets/formula_variable_table.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormulaDetailPage extends ConsumerWidget {
  const FormulaDetailPage({super.key, required this.formulaId});

  final String formulaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formula = FormulaRegistry.byId(formulaId);
    if (formula == null) return const _FormulaNotFound();
    final favorites = ref.watch(formulaFavoritesProvider);
    final favorite = favorites.contains(formula.id);
    final language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(formula.title(language)),
        actions: [
          IconButton(
            key: const Key('formula-detail-favorite'),
            tooltip: context.l10n.t(
              favorite ? 'removeFavorite' : 'favoriteFormula',
            ),
            onPressed: () =>
                ref.read(formulaFavoritesProvider.notifier).toggle(formula.id),
            icon: Icon(
              favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        key: const Key('formula-detail-safe-area'),
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxContentWidth,
              ),
              child: SingleChildScrollView(
                key: const Key('formula-detail-scroll'),
                padding: AppBreakpoints.pagePadding(constraints.maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      formula.category.localized(language),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formula.title(language),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: SelectableText(
                          formula.formulaText,
                          key: const Key('formula-detail-expression'),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(formula.description(language)),
                    const SizedBox(height: 20),
                    _Heading(context.l10n.t('variables')),
                    FormulaVariableTable(variables: formula.variables),
                    const SizedBox(height: 20),
                    _Heading(context.l10n.t('examples')),
                    FormulaExampleSection(examples: formula.examples),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('copy-formula-button'),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: formula.plainTextFormula),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.l10n.t('formulaCopied'),
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: Text(context.l10n.t('copyFormula')),
                        ),
                        for (final link in formula.relatedTools)
                          FormulaToolActionButton(link: link),
                      ],
                    ),
                    const SizedBox(
                      key: Key('formula-detail-bottom-spacer'),
                      height: 32,
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

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _FormulaNotFound extends StatelessWidget {
  const _FormulaNotFound();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.t('formulaLibraryTitle'))),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.l10n.t('formulaNotFound'),
          key: const Key('formula-not-found'),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

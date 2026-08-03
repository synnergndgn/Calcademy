import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/app/tools/calcademy_tool_registry.dart';
import 'package:calcademy/features/ai_assistant/application/ai_assistant_controller.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_assistant_message.dart';
import 'package:calcademy/features/ai_assistant/presentation/widgets/ai_disclaimer_card.dart';
import 'package:calcademy/features/ai_assistant/presentation/widgets/ai_formula_suggestion_card.dart';
import 'package:calcademy/features/ai_assistant/presentation/widgets/ai_input_bar.dart';
import 'package:calcademy/features/ai_assistant/presentation/widgets/ai_message_bubble.dart';
import 'package:calcademy/features/ai_assistant/presentation/widgets/ai_scope_notice_card.dart';
import 'package:calcademy/features/ai_assistant/presentation/widgets/ai_tool_suggestion_card.dart';
import 'package:calcademy/features/formula_library/domain/formula_registry.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantControllerProvider);
    final languageCode = Localizations.localeOf(context).languageCode;
    final examples = languageCode == 'tr'
        ? const [
            'NPV nasıl hesaplanır?',
            '2x2 determinant',
            'Türev için hangi aracı kullanmalıyım?',
            'LP problemi nasıl kurulur?',
            'Ortalama ve standart sapma',
          ]
        : const [
            'How is NPV calculated?',
            '2x2 determinant',
            'Which tool should I use for derivatives?',
            'How do I set up an LP problem?',
            'Mean and standard deviation',
          ];
    return Scaffold(
      key: const Key('ai-assistant-page'),
      appBar: AppBar(title: Text(context.l10n.t('aiAssistantTitle'))),
      body: SafeArea(
        key: const Key('ai-assistant-safe-area'),
        top: false,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppBreakpoints.maxContentWidth,
                    ),
                    child: ListView(
                      key: const Key('ai-assistant-scroll'),
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(
                        AppBreakpoints.pagePadding(constraints.maxWidth).left,
                        AppSpacing.md,
                        AppBreakpoints.pagePadding(constraints.maxWidth).right,
                        AppSpacing.xl,
                      ),
                      children: [
                        Text(
                          context.l10n.t('aiAssistantSubtitle'),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const AiScopeNoticeCard(),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          context.l10n.t('aiAssistantExamples'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          key: const Key('ai-suggestion-chips'),
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (
                              var index = 0;
                              index < examples.length;
                              index++
                            )
                              ActionChip(
                                key: Key('ai-suggestion-$index'),
                                label: Text(examples[index]),
                                onPressed: state.isSending
                                    ? null
                                    : () => _send(examples[index]),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        for (final message in state.messages) ...[
                          AiMessageBubble(message: message),
                          ..._suggestionsFor(message, languageCode),
                        ],
                        if (state.isSending)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AiInputBar(
              controller: _inputController,
              enabled: !state.isSending,
              onChanged: (_) => setState(() {}),
              onSend: () => _send(_inputController.text),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _suggestionsFor(
    AiAssistantMessage message,
    String languageCode,
  ) {
    final plan = message.solutionPlan;
    if (plan == null) return const [];
    final widgets = <Widget>[];
    for (final toolId in message.relatedToolIds) {
      final tool = CalcademyToolRegistry.byId(toolId);
      if (tool == null || !tool.route.startsWith('/')) continue;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: AiToolSuggestionCard(
            tool: tool,
            reason: plan.summary(languageCode),
            onOpen: () => context.push(tool.route),
          ),
        ),
      );
    }
    for (final formulaId in message.relatedFormulaIds) {
      final formula = FormulaRegistry.byId(formulaId);
      if (formula == null) continue;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: AiFormulaSuggestionCard(
            formula: formula,
            onOpen: () => context.push('/formulas/${formula.id}'),
          ),
        ),
      );
    }
    if (message.safetyNotice != null) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AiDisclaimerCard(text: message.safetyNotice),
        ),
      );
    }
    return widgets;
  }

  Future<void> _send(String value) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final sent = await ref
        .read(aiAssistantControllerProvider.notifier)
        .send(value, languageCode: languageCode);
    if (!mounted) return;
    final state = ref.read(aiAssistantControllerProvider);
    if (sent) {
      _inputController.clear();
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    } else if (state.errorKey case final String errorKey) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.t(errorKey))));
    }
  }
}

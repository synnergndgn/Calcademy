import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/calcademy_design.dart';
import 'package:calcademy/features/calculator/domain/calculator_error.dart';
import 'package:calcademy/features/calculator/presentation/calculator_controller.dart';
import 'package:calcademy/features/calculator/presentation/calculator_keypad.dart';
import 'package:calcademy/features/history/presentation/history_controller.dart';
import 'package:calcademy/features/saved_calculations/application/adapters/calculator_saved_adapter.dart';
import 'package:calcademy/features/saved_calculations/presentation/save_result_action.dart';
import 'package:calcademy/features/settings/domain/app_settings.dart';
import 'package:calcademy/features/settings/presentation/settings_controller.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CalculatorPage extends ConsumerStatefulWidget {
  const CalculatorPage({this.initialExpression, super.key});
  final String? initialExpression;

  @override
  ConsumerState<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends ConsumerState<CalculatorPage> {
  static const _functionInsertions = <String, String>{
    'sin': 'sin(',
    'cos': 'cos(',
    'tan': 'tan(',
    'ln': 'ln(',
    'log': 'log(',
    'asin': 'asin(',
    'acos': 'acos(',
    'atan': 'atan(',
    'floor': 'floor(',
    'ceil': 'ceil(',
    'round': 'round(',
    '√': 'sqrt(',
    '|x|': 'abs(',
    '1/x': '1/(',
  };
  static const _replaceableOperators = <String>{'+', '−', '×', '÷', '^'};
  static final _newExpressionPattern = RegExp(r'^[0-9a-zA-Zπ.(]');
  static final _trailingOperatorPattern = RegExp(r'[+−×÷^]$');

  /// Below this viewport height (landscape phones, extreme text scales) the
  /// page falls back to scrolling the whole workspace.
  static const _pinnedLayoutMinHeight = 560.0;

  late final TextEditingController _textController;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialExpression ?? '';
    _textController = TextEditingController(text: initial);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calculatorProvider.notifier).loadExpression(initial);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CalcademyScaffold(
    maxContentWidth: AppBreakpoints.maxContentWidth,
    title: Text(context.l10n.t('calculator')),
    actions: [
      const _AngleModeButton(),
      IconButton(
        tooltip: context.l10n.t('history'),
        onPressed: () => context.push('/history'),
        icon: const Icon(Icons.history_rounded),
      ),
      _CalculatorCopyMenu(onCopy: _copy),
    ],
    body: SafeArea(
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): _clear,
          const SingleActivator(LogicalKeyboardKey.delete): _clear,
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final expanded = constraints.maxWidth >= AppBreakpoints.expanded;
            // On a phone the keypad is taller than the space left over, so a
            // single scrolling column would let it push the expression and the
            // result off the top of the screen. Pin them instead and hand the
            // keypad whatever height is left.
            final pinned =
                !expanded && constraints.maxHeight >= _pinnedLayoutMinHeight;
            final calculator = _CalculatorWorkspace(
              textController: _textController,
              focusNode: _focusNode,
              fillHeight: pinned,
              onChanged: ref.read(calculatorProvider.notifier).setExpression,
              onSubmitted: (_) => _evaluate(),
              resultPanel: _CalculatorResultPanel(
                onCopy: _copy,
                onUse: _replaceText,
              ),
              keypad: RepaintBoundary(
                child: CalculatorKeypad(
                  onKey: _handleKey,
                  onBackspace: _backspace,
                  onClear: _clear,
                  fillHeight: pinned,
                ),
              ),
            );
            if (pinned) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: calculator,
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (expanded) ...[
                  StudyHeader(
                    compact: true,
                    eyebrow: context.l10n.t('calculatorWorkspaceEyebrow'),
                    title: context.l10n.t('calculatorWorkspaceTitle'),
                    subtitle: context.l10n.t('calculatorWorkspaceBody'),
                    formula: 'f(x) → result',
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (expanded)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: calculator),
                      const SizedBox(width: AppSpacing.xl),
                      const Expanded(flex: 2, child: _CalculatorNotebookPane()),
                    ],
                  )
                else
                  calculator,
              ],
            );
          },
        ),
      ),
    ),
  );

  Future<void> _handleKey(String key) async {
    if (key == '=') {
      await _evaluate();
      return;
    }
    if (key == 'x²') {
      _insert('^2');
    } else if (key == 'x!') {
      _insert('!');
    } else {
      _insert(_functionInsertions[key] ?? key);
    }
    final settings = ref.read(settingsProvider);
    if (settings.hapticsEnabled) HapticFeedback.selectionClick();
    if (settings.keySoundEnabled) SystemSound.play(SystemSoundType.click);
  }

  void _insert(String value) {
    final state = ref.read(calculatorProvider);
    if (state.justEvaluated && _newExpressionPattern.hasMatch(value)) {
      _replaceText('');
    }
    final selection = _textController.selection;
    final start = selection.isValid
        ? selection.start
        : _textController.text.length;
    final end = selection.isValid ? selection.end : _textController.text.length;
    var insert = value;
    final current = _textController.text;
    if (_replaceableOperators.contains(value) &&
        start > 0 &&
        _trailingOperatorPattern.hasMatch(current.substring(0, start))) {
      _setTextAndSelection(current.replaceRange(start - 1, end, value), start);
      return;
    }
    if (value == ')' &&
        '('.allMatches(current).length <= ')'.allMatches(current).length) {
      return;
    }
    if (value == '.') {
      final before = current.substring(0, start);
      final number = before.split(RegExp(r'[^0-9.]')).last;
      if (number.contains('.')) return;
      if (number.isEmpty) insert = '0.';
    }
    _setTextAndSelection(
      current.replaceRange(start, end, insert),
      start + insert.length,
      requestFocus: true,
    );
  }

  void _backspace() {
    final selection = _textController.selection;
    if (_textController.text.isEmpty) return;
    final start = selection.isValid
        ? selection.start
        : _textController.text.length;
    final end = selection.isValid ? selection.end : _textController.text.length;
    if (start == 0 && end == 0) return;
    final deleteStart = start == end ? start - 1 : start;
    _setTextAndSelection(
      _textController.text.replaceRange(deleteStart, end, ''),
      deleteStart,
    );
  }

  void _clear() {
    _textController.clear();
    ref.read(calculatorProvider.notifier).clear();
    _focusNode.requestFocus();
  }

  void _replaceText(String text) => _setTextAndSelection(text, text.length);

  void _setTextAndSelection(
    String text,
    int selectionOffset, {
    bool requestFocus = false,
  }) {
    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
    ref.read(calculatorProvider.notifier).setExpression(text);
    if (requestFocus) _focusNode.requestFocus();
  }

  Future<void> _evaluate() => ref.read(calculatorProvider.notifier).evaluate();

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.t('copied'))));
    }
  }
}

class _CalculatorWorkspace extends StatelessWidget {
  const _CalculatorWorkspace({
    required this.textController,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.resultPanel,
    required this.keypad,
    this.fillHeight = false,
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final Widget resultPanel;
  final Widget keypad;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
    children: [
      ExpressionDisplay(
        controller: textController,
        focusNode: focusNode,
        hintText: context.l10n.t('expressionHint'),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
      const SizedBox(height: AppSpacing.sm),
      resultPanel,
      const SizedBox(height: AppSpacing.md),
      if (fillHeight) Expanded(child: keypad) else keypad,
    ],
  );
}

class _CalculatorNotebookPane extends ConsumerWidget {
  const _CalculatorNotebookPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(historyProvider).take(5).toList(growable: false);
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(left: BorderSide(color: colors.tertiary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(
            title: context.l10n.t('recent'),
            icon: Icons.history_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          if (records.isEmpty)
            Text(
              context.l10n.t('noRecent'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            )
          else
            for (final record in records)
              InkWell(
                onTap: () => context.push(
                  '/calculator?expression='
                  '${Uri.encodeQueryComponent(record.expression)}',
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        record.expression,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      Text(
                        '= ${record.result}',
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colors.primary),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _AngleModeButton extends ConsumerWidget {
  const _AngleModeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final angleMode = ref.watch(
      settingsProvider.select((settings) => settings.angleMode),
    );
    return TextButton(
      onPressed: () {
        final next = angleMode == AngleMode.degrees
            ? AngleMode.radians
            : AngleMode.degrees;
        ref.read(settingsProvider.notifier).setAngleMode(next);
      },
      child: Text(angleMode == AngleMode.degrees ? 'DEG' : 'RAD'),
    );
  }
}

class _CalculatorCopyMenu extends ConsumerWidget {
  const _CalculatorCopyMenu({required this.onCopy});

  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasResult = ref.watch(
      calculatorProvider.select((state) => state.result.isNotEmpty),
    );
    return PopupMenuButton<String>(
      onSelected: (value) {
        final state = ref.read(calculatorProvider);
        if (value == 'copyExpression') onCopy(state.expression);
        if (value == 'copyResult') onCopy(state.result);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'copyExpression',
          child: Text(context.l10n.t('copyExpression')),
        ),
        PopupMenuItem(
          value: 'copyResult',
          enabled: hasResult,
          child: Text(context.l10n.t('copyResult')),
        ),
      ],
    );
  }
}

class _CalculatorResultPanel extends ConsumerWidget {
  const _CalculatorResultPanel({required this.onCopy, required this.onUse});

  final ValueChanged<String> onCopy;
  final ValueChanged<String> onUse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panelState = ref.watch(
      calculatorProvider.select(
        (state) => (
          result: state.result,
          error: state.error,
          lastRecord: state.lastRecord,
          hasResult: state.result.isNotEmpty,
        ),
      ),
    );
    final errorText = panelState.error == null
        ? null
        : _errorText(context, panelState.error!);
    return ResultPanel(
      label: context.l10n.t('result'),
      value: panelState.result,
      error: errorText,
      actions: panelState.hasResult
          ? [
              IconButton(
                tooltip: context.l10n.t('copyResult'),
                onPressed: () => onCopy(panelState.result),
                icon: const Icon(Icons.copy_rounded),
              ),
              if (panelState.lastRecord case final record?)
                SaveResultAction(
                  buttonKey: const Key('calculator-save-calculation'),
                  draft: CalculatorSavedAdapter.fromRecord(record),
                  compact: true,
                ),
              IconButton(
                tooltip: context.l10n.t('useResult'),
                onPressed: () => onUse(panelState.result),
                icon: const Icon(Icons.call_made_rounded),
              ),
            ]
          : const [],
    );
  }
}

String _errorText(BuildContext context, CalculatorErrorType type) =>
    switch (type) {
      CalculatorErrorType.empty => context.l10n.t('emptyExpression'),
      CalculatorErrorType.incomplete => context.l10n.t('incompleteExpression'),
      CalculatorErrorType.parentheses => context.l10n.t('parenthesesError'),
      CalculatorErrorType.divisionByZero => context.l10n.t('divisionByZero'),
      CalculatorErrorType.domain => context.l10n.t('domainError'),
      CalculatorErrorType.undefined => context.l10n.t('undefinedResult'),
      CalculatorErrorType.overflow => context.l10n.t('resultTooLarge'),
      CalculatorErrorType.invalid => context.l10n.t('invalidExpression'),
    };

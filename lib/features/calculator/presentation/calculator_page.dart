import 'package:calcademy/app/theme/app_colors.dart';
import 'package:calcademy/app/theme/app_radius.dart';
import 'package:calcademy/features/calculator/domain/calculator_error.dart';
import 'package:calcademy/features/calculator/presentation/calculator_controller.dart';
import 'package:calcademy/features/calculator/presentation/calculator_keypad.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): _clear,
                const SingleActivator(LogicalKeyboardKey.delete): _clear,
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  TextField(
                    key: const Key('expressionField'),
                    controller: _textController,
                    focusNode: _focusNode,
                    readOnly: true,
                    showCursor: true,
                    minLines: 2,
                    maxLines: 4,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.headlineSmall,
                    decoration: InputDecoration(
                      hintText: context.l10n.t('expressionHint'),
                    ),
                    onChanged: ref
                        .read(calculatorProvider.notifier)
                        .setExpression,
                    onSubmitted: (_) => _evaluate(),
                  ),
                  const SizedBox(height: 12),
                  _CalculatorResultPanel(onCopy: _copy, onUse: _replaceText),
                  const SizedBox(height: 16),
                  CalculatorKeypad(
                    onKey: _handleKey,
                    onBackspace: _backspace,
                    onClear: _clear,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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

  void _replaceText(String text) {
    _setTextAndSelection(text, text.length);
  }

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final errorText = panelState.error == null
        ? null
        : _errorText(context, panelState.error!);
    return Container(
      key: const Key('resultPanel'),
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorText == null
            ? colors.primaryContainer
            : colors.errorContainer,
        borderRadius: AppRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(context.l10n.t('result'), style: theme.textTheme.labelLarge),
              if (errorText == null && panelState.hasResult) ...[
                const SizedBox(width: 8),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.dataPoint,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(dimension: 8),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            errorText ?? (panelState.hasResult ? panelState.result : '—'),
            key: const Key('resultText'),
            textAlign: TextAlign.end,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: errorText == null
                  ? colors.onPrimaryContainer
                  : colors.onErrorContainer,
            ),
          ),
          if (panelState.hasResult) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
              ],
            ),
          ],
        ],
      ),
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

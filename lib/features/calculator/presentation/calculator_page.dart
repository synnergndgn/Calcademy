import 'package:calcademy/features/calculator/domain/calculator_error.dart';
import 'package:calcademy/features/calculator/presentation/calculator_controller.dart';
import 'package:calcademy/features/calculator/presentation/calculator_keypad.dart';
import 'package:calcademy/features/saved/presentation/saved_controller.dart';
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
    final state = ref.watch(calculatorProvider);
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.t('calculator')),
        actions: [
          TextButton(
            onPressed: () {
              final next = settings.angleMode == AngleMode.degrees
                  ? AngleMode.radians
                  : AngleMode.degrees;
              ref.read(settingsProvider.notifier).setAngleMode(next);
            },
            child: Text(
              settings.angleMode == AngleMode.degrees ? 'DEG' : 'RAD',
            ),
          ),
          IconButton(
            tooltip: context.l10n.t('history'),
            onPressed: () => context.push('/history'),
            icon: const Icon(Icons.history_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'copyExpression') _copy(state.expression);
              if (value == 'copyResult') _copy(state.result);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'copyExpression',
                child: Text(context.l10n.t('copyExpression')),
              ),
              PopupMenuItem(
                value: 'copyResult',
                enabled: state.result.isNotEmpty,
                child: Text(context.l10n.t('copyResult')),
              ),
            ],
          ),
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
                  _ResultPanel(
                    state: state,
                    errorText: state.error == null
                        ? null
                        : _errorText(state.error!),
                    onCopy: state.result.isEmpty
                        ? null
                        : () => _copy(state.result),
                    onSave: state.lastRecord == null ? null : _save,
                    onUse: state.result.isEmpty
                        ? null
                        : () => _replaceText(state.result),
                  ),
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
    final functions = {
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
    if (key == 'x²') {
      _insert('^2');
    } else if (key == 'x!') {
      _insert('!');
    } else {
      _insert(functions[key] ?? key);
    }
    final settings = ref.read(settingsProvider);
    if (settings.hapticsEnabled) HapticFeedback.selectionClick();
    if (settings.keySoundEnabled) SystemSound.play(SystemSoundType.click);
  }

  void _insert(String value) {
    final state = ref.read(calculatorProvider);
    if (state.justEvaluated && RegExp(r'^[0-9a-zA-Zπ.(]').hasMatch(value)) {
      _replaceText('');
    }
    final selection = _textController.selection;
    final start = selection.isValid
        ? selection.start
        : _textController.text.length;
    final end = selection.isValid ? selection.end : _textController.text.length;
    var insert = value;
    final current = _textController.text;
    if (['+', '−', '×', '÷', '^'].contains(value) &&
        start > 0 &&
        RegExp(r'[+−×÷^]$').hasMatch(current.substring(0, start))) {
      _textController.text = current.replaceRange(start - 1, end, value);
      _textController.selection = TextSelection.collapsed(offset: start);
      ref.read(calculatorProvider.notifier).setExpression(_textController.text);
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
    _textController.text = current.replaceRange(start, end, insert);
    _textController.selection = TextSelection.collapsed(
      offset: start + insert.length,
    );
    ref.read(calculatorProvider.notifier).setExpression(_textController.text);
    _focusNode.requestFocus();
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
    _textController.text = _textController.text.replaceRange(
      deleteStart,
      end,
      '',
    );
    _textController.selection = TextSelection.collapsed(offset: deleteStart);
    ref.read(calculatorProvider.notifier).setExpression(_textController.text);
  }

  void _clear() {
    _textController.clear();
    ref.read(calculatorProvider.notifier).clear();
    _focusNode.requestFocus();
  }

  void _replaceText(String text) {
    _textController.text = text;
    _textController.selection = TextSelection.collapsed(offset: text.length);
    ref.read(calculatorProvider.notifier).setExpression(text);
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

  Future<void> _save() async {
    final record = ref.read(calculatorProvider).lastRecord;
    if (record == null) return;
    final title = TextEditingController();
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('saveResult')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: InputDecoration(labelText: context.l10n.t('title')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: InputDecoration(labelText: context.l10n.t('note')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.t('save')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(savedProvider.notifier)
          .addFromRecord(record, title: title.text, note: note.text);
    }
    title.dispose();
    note.dispose();
  }

  String _errorText(CalculatorErrorType type) => switch (type) {
    CalculatorErrorType.empty => context.l10n.t('emptyExpression'),
    CalculatorErrorType.incomplete => context.l10n.t('incompleteExpression'),
    CalculatorErrorType.parentheses => context.l10n.t('parenthesesError'),
    CalculatorErrorType.divisionByZero => context.l10n.t('divisionByZero'),
    CalculatorErrorType.domain => context.l10n.t('domainError'),
    CalculatorErrorType.undefined => context.l10n.t('undefinedResult'),
    CalculatorErrorType.overflow => context.l10n.t('resultTooLarge'),
    CalculatorErrorType.invalid => context.l10n.t('invalidExpression'),
  };
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.state,
    required this.errorText,
    required this.onCopy,
    required this.onSave,
    required this.onUse,
  });

  final CalculatorState state;
  final String? errorText;
  final VoidCallback? onCopy;
  final VoidCallback? onSave;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorText == null
            ? colors.primaryContainer
            : colors.errorContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.t('result'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          SelectableText(
            errorText ?? (state.result.isEmpty ? '—' : state.result),
            key: const Key('resultText'),
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: errorText == null
                  ? colors.onPrimaryContainer
                  : colors.onErrorContainer,
            ),
          ),
          if (state.result.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: context.l10n.t('copyResult'),
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded),
                ),
                IconButton(
                  tooltip: context.l10n.t('saveResult'),
                  onPressed: onSave,
                  icon: const Icon(Icons.bookmark_add_outlined),
                ),
                IconButton(
                  tooltip: context.l10n.t('useResult'),
                  onPressed: onUse,
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

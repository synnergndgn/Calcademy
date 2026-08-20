import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/quiz/presentation/widgets/math_formula.dart';
import 'package:flutter/material.dart';

/// Inserts [insert] at the cursor, replacing whatever is selected, and leaves
/// the cursor [caretBack] characters from the end of what was inserted.
///
/// Pulled out of the widget so the caret arithmetic can be tested without a
/// pump: getting it wrong is the one way a convenience row can make typing
/// worse than not having it.
void insertMathInputToken(
  TextEditingController controller,
  String insert, {
  int caretBack = 0,
}) {
  final text = controller.text;
  final selection = controller.selection;
  // An untouched field reports an invalid selection rather than offset 0, so
  // the first tap appends instead of writing to the front of the answer.
  final start = selection.isValid ? selection.start : text.length;
  final end = selection.isValid ? selection.end : text.length;
  controller.value = TextEditingValue(
    text: text.replaceRange(start, end, insert),
    selection: TextSelection.collapsed(
      offset: start + insert.length - caretBack,
    ),
  );
}

/// One shortcut on the row: what it shows, what it types, and where it leaves
/// the cursor.
class MathInputToken {
  const MathInputToken(this.label, this.insert, {this.caretBack = 0});

  /// Rendered through [MathFormula], so `e^x` advertises itself as eˣ.
  final String label;

  /// Keyboard-friendly text, the same notation the normalizer already grades.
  final String insert;

  /// How far back from the end of [insert] to park the cursor. `()` leaves it
  /// between the brackets, which is the only place the next character goes.
  final int caretBack;
}

/// A row of shortcuts above the written-answer field.
///
/// Deliberately not an equation editor: every token here is something the
/// learner could type themselves, and the field stays a plain text field that
/// the Android keyboard drives. This only saves the reaching -- `^`, `|`, `√`,
/// `π` are all two or three taps deep on a phone keyboard -- so an answer is
/// never gated on finding the right key.
class MathTokenRow extends StatelessWidget {
  const MathTokenRow({
    required this.controller,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;

  /// Ordered by how often a calculus answer needs them, not by keyboard
  /// layout. `√` and `π` type their own glyph because the normalizer folds
  /// them to `sqrt` and `pi` already.
  static const tokens = <MathInputToken>[
    MathInputToken('x', 'x'),
    MathInputToken('^', '^'),
    MathInputToken('( )', '()', caretBack: 1),
    MathInputToken('|', '|'),
    MathInputToken('√', '√'),
    MathInputToken('π', 'π'),
    MathInputToken('e^x', 'e^x'),
    MathInputToken('ln|', 'ln|'),
    MathInputToken('+ C', ' + C'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      // Wrap rather than a scroller: nine short tokens fold onto a second line
      // on a narrow phone, and a token the learner cannot see is a token they
      // will not use.
      child: Wrap(
        key: const Key('quiz-math-token-row'),
        spacing: AppSpacing.xxs,
        runSpacing: AppSpacing.xxs,
        children: [
          for (final token in tokens)
            OutlinedButton(
              key: Key('quiz-math-token-${token.insert.trim()}'),
              onPressed: enabled
                  ? () => insertMathInputToken(
                      controller,
                      token.insert,
                      caretBack: token.caretBack,
                    )
                  : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 36),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: MathFormula(token.label, style: theme.textTheme.bodyLarge),
            ),
        ],
      ),
    );
  }
}

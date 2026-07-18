import 'package:calcademy/app/theme/app_radius.dart';
import 'package:flutter/material.dart';

class CalculatorKeypad extends StatelessWidget {
  const CalculatorKeypad({
    required this.onKey,
    required this.onBackspace,
    required this.onClear,
    super.key,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  static const keys = <String>[
    'sin',
    'cos',
    'tan',
    'ln',
    'log',
    '√',
    'asin',
    'acos',
    'atan',
    'floor',
    'ceil',
    'round',
    'π',
    'e',
    'x²',
    'x!',
    '|x|',
    '1/x',
    '7',
    '8',
    '9',
    '÷',
    '(',
    ')',
    '4',
    '5',
    '6',
    '×',
    'mod',
    '^',
    '1',
    '2',
    '3',
    '−',
    '%',
    'Ans',
    '0',
    '.',
    'AC',
    '⌫',
    '+',
    '=',
  ];
  static const _operatorKeys = <String>{'÷', '×', '−', '+', '^', 'mod'};
  static const _scientificKeys = <String>{
    'sin',
    'cos',
    'tan',
    'ln',
    'log',
    '√',
    'asin',
    'acos',
    'atan',
    'floor',
    'ceil',
    'round',
    'π',
    'e',
    'x²',
    'x!',
    '|x|',
    '1/x',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final standardTextStyle = theme.textTheme.titleMedium?.copyWith(
      color: colors.onSurface,
      fontWeight: FontWeight.w500,
    );
    final operatorTextStyle = theme.textTheme.titleMedium?.copyWith(
      color: colors.onSecondaryContainer,
      fontWeight: FontWeight.w700,
    );
    final primaryTextStyle = operatorTextStyle?.copyWith(
      color: colors.onPrimary,
    );
    final scientificTextStyle = standardTextStyle?.copyWith(
      color: colors.onPrimaryContainer,
    );
    final destructiveTextStyle = standardTextStyle?.copyWith(
      color: colors.onErrorContainer,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = constraints.maxWidth > 600 ? 1.75 : 1.15;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: keys.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            childAspectRatio: ratio,
          ),
          itemBuilder: (context, index) {
            final key = keys[index];
            final isPrimary = key == '=';
            final isDestructive = key == 'AC' || key == '⌫';
            final isOperator = _operatorKeys.contains(key);
            final isScientific = _scientificKeys.contains(key);
            return Semantics(
              button: true,
              label: _semanticLabel(key),
              child: Material(
                color: isPrimary
                    ? colors.primary
                    : isDestructive
                    ? colors.errorContainer
                    : isOperator
                    ? colors.secondaryContainer
                    : isScientific
                    ? colors.primaryContainer.withValues(alpha: 0.58)
                    : colors.surfaceContainerHigh,
                borderRadius: AppRadius.control,
                child: InkWell(
                  borderRadius: AppRadius.control,
                  onTap: () {
                    if (key == 'AC') {
                      onClear();
                    } else if (key == '⌫') {
                      onBackspace();
                    } else {
                      onKey(key);
                    }
                  },
                  onLongPress: key == '⌫' ? onClear : null,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        key,
                        style: isPrimary
                            ? primaryTextStyle
                            : isDestructive
                            ? destructiveTextStyle
                            : isOperator
                            ? operatorTextStyle
                            : isScientific
                            ? scientificTextStyle
                            : standardTextStyle,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _semanticLabel(String key) => switch (key) {
    '÷' => 'divide',
    '×' => 'multiply',
    '−' => 'subtract',
    '⌫' => 'backspace',
    '=' => 'equals',
    '√' => 'square root',
    _ => key,
  };
}

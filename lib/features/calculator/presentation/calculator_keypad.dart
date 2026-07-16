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

  static const keys = [
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
            final isOperator = ['÷', '×', '−', '+', '^', 'mod'].contains(key);
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
                    : colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: isPrimary ? colors.onPrimary : null,
                              fontWeight: isPrimary || isOperator
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
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

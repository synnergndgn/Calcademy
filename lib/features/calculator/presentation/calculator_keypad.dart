import 'package:calcademy/core/widgets/calcademy_design.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final columns = compact ? 5 : 6;
        final ratio = constraints.maxWidth > 600
            ? 1.75
            : (compact ? 1.0 : 1.15);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: keys.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
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
            return SoftCalculatorKey(
              label: key,
              semanticLabel: _semanticLabel(key),
              kind: isPrimary
                  ? CalculatorKeyKind.primary
                  : isDestructive
                  ? CalculatorKeyKind.action
                  : isOperator
                  ? CalculatorKeyKind.operator
                  : isScientific
                  ? CalculatorKeyKind.scientific
                  : CalculatorKeyKind.number,
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

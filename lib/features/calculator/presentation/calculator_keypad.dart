import 'dart:math' as math;

import 'package:calcademy/core/widgets/calcademy_design.dart';
import 'package:flutter/material.dart';

class CalculatorKeypad extends StatelessWidget {
  const CalculatorKeypad({
    required this.onKey,
    required this.onBackspace,
    required this.onClear,
    super.key,
    this.fillHeight = false,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  /// Sizes the keys to the height handed down instead of to their own natural
  /// height, so a pinned expression display can never be pushed off screen.
  final bool fillHeight;

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

  static const _spacing = 7.0;

  /// Keys never shrink below this; the grid scrolls on its own instead. Low
  /// enough that every portrait phone fits all nine rows, high enough that
  /// landscape and large text scales scroll rather than turn into slivers.
  static const _minKeyHeight = 40.0;

  /// Keys never grow taller than this multiple of their width.
  static const _maxKeyHeightRatio = 1.25;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final columns = compact ? 5 : 6;
        var ratio = constraints.maxWidth > 600 ? 1.75 : (compact ? 1.0 : 1.15);
        var scrolls = false;
        if (fillHeight && constraints.hasBoundedHeight) {
          final rows = (keys.length / columns).ceil();
          final keyWidth =
              (constraints.maxWidth - _spacing * (columns - 1)) / columns;
          final keyHeight =
              (constraints.maxHeight - _spacing * (rows - 1)) / rows;
          scrolls = keyHeight < _minKeyHeight;
          ratio =
              keyWidth /
              math.min(
                math.max(keyHeight, _minKeyHeight),
                keyWidth * _maxKeyHeightRatio,
              );
        }
        return GridView.builder(
          shrinkWrap: !fillHeight,
          physics: scrolls
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: keys.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: _spacing,
            crossAxisSpacing: _spacing,
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

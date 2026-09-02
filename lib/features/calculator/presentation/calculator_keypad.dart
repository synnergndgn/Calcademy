import 'dart:math' as math;

import 'package:calcademy/core/widgets/calcademy_design.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// How the keypad grid is arranged into the height it was handed.
@immutable
class KeypadLayout {
  const KeypadLayout({
    required this.columns,
    required this.rows,
    required this.keyWidth,
    required this.keyHeight,
    required this.scrolls,
  });

  final int columns;
  final int rows;
  final double keyWidth;
  final double keyHeight;

  /// Whether the rows still overflow the height, leaving the grid to scroll.
  final bool scrolls;

  double get aspectRatio => keyWidth / keyHeight;
}

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

  static const spacing = 7.0;

  /// Keys never shrink below this; the grid scrolls on its own instead. Low
  /// enough that a portrait phone fits every row, high enough that a key that
  /// small is still worth tapping rather than a sliver.
  static const minKeyHeight = 40.0;

  /// Keys never grow taller than this multiple of their width.
  static const _maxKeyHeightRatio = 1.25;

  /// Below this a key is still tappable but its longest labels -- `round`,
  /// `floor` -- are shrunk further than is comfortable to read.
  static const _minComfortableKeyWidth = 44.0;

  /// Column counts to try, in order of preference. Six divides the key list
  /// into exactly seven rows and keeps each group -- functions, constants,
  /// digits -- on rows of its own; five needs nine rows and splits the digits
  /// across them, and is only worth it when six would leave the keys too
  /// narrow to read.
  static const columnCandidates = <int>[6, 5];

  static int rowsFor(int columns) => (keys.length / columns).ceil();

  /// The least height in which some candidate can show every key at
  /// [minKeyHeight]. Callers budget the space above the keypad against this
  /// instead of discovering the overflow after layout.
  static double minimumHeight() {
    final rows = columnCandidates.map(rowsFor).reduce(math.min);
    return rows * minKeyHeight + (rows - 1) * spacing;
  }

  static KeypadLayout _layoutFor(int columns, double width, double height) {
    final rows = rowsFor(columns);
    final keyWidth = (width - spacing * (columns - 1)) / columns;
    final keyHeight = clampDouble(
      (height - spacing * (rows - 1)) / rows,
      minKeyHeight,
      math.max(minKeyHeight, keyWidth * _maxKeyHeightRatio),
    );
    return KeypadLayout(
      columns: columns,
      rows: rows,
      keyWidth: keyWidth,
      keyHeight: keyHeight,
      scrolls: rows * keyHeight + (rows - 1) * spacing > height + 0.5,
    );
  }

  /// The first candidate that shows every key at a comfortable width, else the
  /// first that shows every key at all, else the preferred one, scrolling.
  static KeypadLayout resolveLayout({
    required double width,
    required double height,
  }) {
    KeypadLayout? narrow;
    KeypadLayout? scrolling;
    for (final columns in columnCandidates) {
      final layout = _layoutFor(columns, width, height);
      if (layout.scrolls) {
        scrolling ??= layout;
        continue;
      }
      if (layout.keyWidth >= _minComfortableKeyWidth) return layout;
      narrow ??= layout;
    }
    return narrow ?? scrolling!;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        var columns = compact ? 5 : 6;
        var ratio = constraints.maxWidth > 600 ? 1.75 : (compact ? 1.0 : 1.15);
        var scrolls = false;
        if (fillHeight && constraints.hasBoundedHeight) {
          final layout = resolveLayout(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
          );
          columns = layout.columns;
          ratio = layout.aspectRatio;
          scrolls = layout.scrolls;
        }
        final grid = GridView.builder(
          shrinkWrap: !fillHeight,
          physics: scrolls
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: keys.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
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
        // Rows the viewport cannot hold are still reachable, but only a
        // visible thumb tells anyone they are there.
        if (!scrolls) return grid;
        return Scrollbar(thumbVisibility: true, child: grid);
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

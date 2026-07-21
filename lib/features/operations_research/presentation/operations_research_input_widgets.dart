import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class OrCountSelector extends StatelessWidget {
  const OrCountSelector({
    super.key,
    required this.label,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
    this.increaseKey,
  });

  final String label;
  final int value;
  final int minimum;
  final int maximum;
  final ValueChanged<int> onChanged;
  final Key? increaseKey;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(child: Text('$label: $value')),
      IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: value <= minimum ? null : () => onChanged(value - 1),
        icon: const Icon(Icons.remove_circle_outline),
      ),
      IconButton(
        key: increaseKey,
        visualDensity: VisualDensity.compact,
        onPressed: value >= maximum ? null : () => onChanged(value + 1),
        icon: const Icon(Icons.add_circle_outline),
      ),
    ],
  );
}

class OrMatrixField extends StatelessWidget {
  const OrMatrixField({
    super.key,
    required this.controller,
    required this.label,
    required this.fieldKey,
    this.width = 72,
  });

  final TextEditingController controller;
  final String label;
  final Key fieldKey;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: TextField(
      key: fieldKey,
      controller: controller,
      textAlign: TextAlign.end,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(labelText: label, isDense: true),
    ),
  );
}

class OrSelectorsLayout extends StatelessWidget {
  const OrSelectorsLayout({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth < 520
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1)
                  const SizedBox(height: AppSpacing.xs),
              ],
            ],
          )
        : Row(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                Expanded(child: children[index]),
                if (index < children.length - 1)
                  const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
  );
}

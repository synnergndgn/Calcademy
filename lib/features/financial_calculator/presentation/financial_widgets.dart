import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/features/financial_calculator/domain/financial_result.dart';
import 'package:flutter/material.dart';

class FinancialFieldGrid extends StatelessWidget {
  const FinancialFieldGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720
            ? 3
            : constraints.maxWidth >= 480
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

double parseFinancialDouble(String input) {
  final value = double.tryParse(input.trim().replaceAll(',', '.'));
  if (value == null || !value.isFinite) {
    throw const FinancialValidationException(FinancialIssue.invalidNumber);
  }
  return value;
}

int parseFinancialInt(String input, FinancialIssue issue) {
  final value = int.tryParse(input.trim());
  if (value == null) throw FinancialValidationException(issue);
  return value;
}

TextField financialField(
  String key,
  TextEditingController controller,
  String label, {
  bool decimal = true,
  String? helperText,
}) => TextField(
  key: Key(key),
  controller: controller,
  keyboardType: TextInputType.numberWithOptions(decimal: decimal, signed: true),
  decoration: InputDecoration(labelText: label, helperText: helperText),
);

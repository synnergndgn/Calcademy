import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class StatisticsFieldGrid extends StatelessWidget {
  const StatisticsFieldGrid({super.key, required this.children});

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

double parseStatisticsDouble(String value) {
  final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
  if (parsed == null || !parsed.isFinite) {
    throw const FormatException('invalid finite number');
  }
  return parsed;
}

int parseStatisticsInt(String value) {
  final parsed = int.tryParse(value.trim());
  if (parsed == null) throw const FormatException('invalid integer');
  return parsed;
}

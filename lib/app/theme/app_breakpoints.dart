import 'package:flutter/material.dart';

abstract final class AppBreakpoints {
  static const compact = 600.0;
  static const expanded = 960.0;
  static const maxContentWidth = 1200.0;

  static int gridColumns(double width) {
    if (width >= expanded) return 3;
    if (width >= compact) return 2;
    return 1;
  }

  static EdgeInsets pagePadding(double width) =>
      EdgeInsets.symmetric(horizontal: width >= compact ? 24 : 16);
}

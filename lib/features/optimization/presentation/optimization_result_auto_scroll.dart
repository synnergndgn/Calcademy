import 'package:flutter/material.dart';

const optimizationResultScrollDuration = Duration(milliseconds: 320);

/// Reveals an optimization result after its provider-driven UI has rebuilt.
///
/// The result key's context is also the lifecycle guard: if the page was
/// disposed before the callback runs, there is no context and no scroll.
void scheduleOptimizationResultAutoScroll(GlobalKey resultKey) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final resultContext = resultKey.currentContext;
    if (resultContext == null || !resultContext.mounted) return;

    Scrollable.ensureVisible(
      resultContext,
      duration: optimizationResultScrollDuration,
      curve: Curves.easeInOut,
      alignment: 0.08,
    );
  });
}

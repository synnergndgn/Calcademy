import 'package:flutter/material.dart';

/// Timing shared by every tool, so revealing a result feels the same wherever
/// it happens. Originally tuned for the optimization pages.
const resultAutoScrollDuration = Duration(milliseconds: 320);

/// Leaves a little of the input above the result, so the user can see what
/// produced it rather than landing on a bare answer.
const resultAutoScrollAlignment = 0.08;

/// Reveals a result section after the provider-driven UI has rebuilt.
///
/// Every calculation tool puts its result below a form long enough to push it
/// past the fold, so without this the user presses Calculate and nothing
/// appears to happen. The optimization pages had it; the rest did not, and that
/// inconsistency is what this generalisation removes.
///
/// The result key's context doubles as the lifecycle guard: if the page was
/// disposed before the post-frame callback runs, there is no context and no
/// scroll. Callers should still check `mounted` before calling, so an
/// abandoned async calculation cannot schedule work on a dead page.
///
/// Call this only after a **successful** calculation. Errors surface through
/// each page's own affordance — a snackbar, or an inline message the user is
/// already looking at — and yanking the viewport on a validation failure moves
/// the field they are trying to fix.
void scheduleResultAutoScroll(GlobalKey resultKey) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final resultContext = resultKey.currentContext;
    if (resultContext == null || !resultContext.mounted) return;

    Scrollable.ensureVisible(
      resultContext,
      duration: resultAutoScrollDuration,
      curve: Curves.easeInOut,
      alignment: resultAutoScrollAlignment,
    );
  });
}

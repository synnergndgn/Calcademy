import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Centres page content at a readable width.
///
/// Ten pages had no width constraint at all, so on a tablet they ran edge to
/// edge while Home, Assistant, Premium, and the account screens stayed centred.
/// Adding another literal to each file would have widened that drift rather
/// than closing it.
///
/// This only constrains and centres — it deliberately adds no padding of its
/// own, so a scrollable keeps its padding *inside* the viewport and content can
/// still scroll under the inset instead of being clipped by it. Use
/// [PageBody.scrollPadding] for that padding, and [PageBody.padded] when the
/// child does not scroll.
class PageBody extends StatelessWidget {
  const PageBody({
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    super.key,
  });

  /// Narrower default for forms, where a full-width text field is hard to scan.
  const PageBody.form({required this.child, super.key})
    : maxWidth = AppBreakpoints.compact;

  final Widget child;
  final double maxWidth;

  /// Padding for a scrollable's own `padding` property: width-aware sides plus
  /// bottom room that clears the gesture bar and any anchored ad banner.
  ///
  /// Reads `viewPadding` rather than `padding` on purpose. Inside a Scaffold
  /// body the bottom inset is already consumed, so `padding` reports zero and
  /// the gesture-bar clearance would silently disappear.
  static EdgeInsets scrollPadding(
    BuildContext context, {
    double top = AppSpacing.md,
    double bottom = AppSpacing.xl,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final sides = AppBreakpoints.pagePadding(width);
    return EdgeInsets.only(
      left: sides.left,
      right: sides.right,
      top: top,
      bottom: bottom + MediaQuery.viewPaddingOf(context).bottom,
    );
  }

  /// Constrained, centred, and padded — for content that does not scroll.
  static Widget padded({
    required BuildContext context,
    required Widget child,
    double maxWidth = AppBreakpoints.maxContentWidth,
    double top = AppSpacing.md,
    double bottom = AppSpacing.xl,
  }) => PageBody(
    maxWidth: maxWidth,
    child: Padding(
      padding: scrollPadding(context, top: top, bottom: bottom),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

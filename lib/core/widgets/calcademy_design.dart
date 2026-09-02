import 'dart:math' as math;

import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_radius.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class CalcademyScaffold extends StatelessWidget {
  const CalcademyScaffold({
    required this.body,
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.maxContentWidth = AppBreakpoints.maxContentWidth,
    this.extendBody = false,
  });

  final Widget body;
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final double maxContentWidth;
  final bool extendBody;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: extendBody,
    appBar: title == null && actions == null && leading == null
        ? null
        : AppBar(title: title, actions: actions, leading: leading),
    bottomNavigationBar: bottomNavigationBar,
    floatingActionButton: floatingActionButton,
    body: GraphPaperBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: body,
        ),
      ),
    ),
  );
}

class GraphPaperBackground extends StatelessWidget {
  const GraphPaperBackground({
    required this.child,
    super.key,
    this.intensity = 1,
  });

  final Widget child;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                isComplex: false,
                willChange: false,
                painter: _GraphPaperPainter(
                  minor: colors.outlineVariant.withValues(
                    alpha: 0.16 * intensity,
                  ),
                  major: colors.primary.withValues(alpha: 0.07 * intensity),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GraphPaperPainter extends CustomPainter {
  const _GraphPaperPainter({required this.minor, required this.major});

  final Color minor;
  final Color major;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 24.0;
    final minorPaint = Paint()
      ..color = minor
      ..strokeWidth = 0.6;
    final majorPaint = Paint()
      ..color = major
      ..strokeWidth = 0.9;
    for (var x = 0.0; x <= size.width; x += step) {
      final paint = (x / step).round() % 5 == 0 ? majorPaint : minorPaint;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      final paint = (y / step).round() % 5 == 0 ? majorPaint : minorPaint;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GraphPaperPainter oldDelegate) =>
      oldDelegate.minor != minor || oldDelegate.major != major;
}

class StudyHeader extends StatelessWidget {
  const StudyHeader({
    required this.title,
    super.key,
    this.eyebrow,
    this.subtitle,
    this.formula,
    this.trailing,
    this.compact = false,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final String? formula;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      header: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final stackTrailing = constraints.maxWidth < 520 || textScale > 1.3;
          final titleStyle = compact || stackTrailing
              ? theme.textTheme.headlineSmall
              : theme.textTheme.displaySmall;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  context.upperCase(eyebrow!),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(title, style: titleStyle?.copyWith(color: colors.onSurface)),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (formula != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  formula!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                    fontFamily: 'monospace',
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ],
          );
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primaryContainer,
                  colors.surfaceContainerLowest,
                ],
              ),
              border: Border(
                left: BorderSide(color: colors.primary, width: 4),
                bottom: BorderSide(color: colors.outlineVariant),
              ),
            ),
            padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xl),
            child: stackTrailing
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      content,
                      if (trailing != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: trailing!,
                        ),
                      ],
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: content),
                      if (trailing != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        trailing!,
                      ],
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class ToolDockItem {
  const ToolDockItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Key? key;
}

class ToolDock extends StatelessWidget {
  const ToolDock({required this.items, super.key});

  final List<ToolDockItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.inverseSurface,
        borderRadius: AppRadius.control,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final minimumItemWidth = scale > 1.3 ? 132.0 : 88.0;
          final columnCount = math.max(
            1,
            math.min(
              items.length,
              ((constraints.maxWidth + AppSpacing.xs) /
                      (minimumItemWidth + AppSpacing.xs))
                  .floor(),
            ),
          );
          final itemWidth =
              (constraints.maxWidth -
                  AppSpacing.md -
                  AppSpacing.xs * (columnCount - 1)) /
              columnCount;
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final item in items)
                  SizedBox(
                    width: itemWidth,
                    child: Semantics(
                      button: true,
                      label: item.label,
                      child: InkWell(
                        key: item.key,
                        borderRadius: AppRadius.button,
                        onTap: item.onTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxs,
                            vertical: AppSpacing.sm,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.icon,
                                color: colors.onInverseSurface,
                                size: 22,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                item.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: colors.onInverseSurface),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ExpressionDisplay extends StatelessWidget {
  const ExpressionDisplay({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onChanged,
    super.key,
    this.onSubmitted,
    this.lines = 2,
    this.growsTo = 4,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Lines the field always reserves.
  final int lines;

  /// Lines it may grow to before it scrolls its own content instead. Pass
  /// [lines] on a pinned layout, where growing would steal keypad rows.
  final int growsTo;

  static const _lineSpacing = 1.35;

  /// Padding and borders around the text, which do not scale with the text.
  static const _chrome = AppSpacing.sm + AppSpacing.xs + 3;

  /// The height this display occupies for [lines] lines of text at the
  /// ambient text scale. Lets a caller budget the space around it without
  /// laying it out first.
  static double heightFor(BuildContext context, {int lines = 2}) {
    final fontSize = Theme.of(context).textTheme.headlineSmall?.fontSize ?? 24;
    return MediaQuery.textScalerOf(context).scale(fontSize) *
            _lineSpacing *
            lines +
        _chrome;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: colors.outlineVariant),
          bottom: BorderSide(color: colors.primary, width: 2),
        ),
      ),
      child: TextField(
        key: const Key('expressionField'),
        controller: controller,
        focusNode: focusNode,
        readOnly: true,
        showCursor: true,
        minLines: lines,
        maxLines: math.max(lines, growsTo),
        scrollPadding: const EdgeInsets.all(AppSpacing.xxl),
        textAlign: TextAlign.end,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontFamily: 'monospace',
          height: 1.35,
        ),
        decoration: InputDecoration(
          filled: false,
          hintText: hintText,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}

class ResultPanel extends StatelessWidget {
  const ResultPanel({
    required this.label,
    required this.value,
    super.key,
    this.error,
    this.actions = const [],
    this.minHeight = comfortableMinHeight,
    this.actionsInHeader = false,
  });

  /// The floor the panel keeps when it has room to breathe.
  static const comfortableMinHeight = 116.0;

  /// Side of the compact icon buttons used by [actionsInHeader].
  static const _headerActionSize = 36.0;

  /// Line box for a style that leaves its height to the font. Deliberately
  /// generous: [heightFor] is a budget, and over-reserving costs a few
  /// logical pixels where under-reserving costs a row of keys.
  static const _defaultLineSpacing = 1.4;

  /// The height the panel takes for a single-line value at the ambient text
  /// scale, so a caller can budget around it before laying it out.
  static double heightFor(
    BuildContext context, {
    double minHeight = comfortableMinHeight,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    double lineOf(TextStyle? style, double fallbackSize) =>
        scaler.scale(style?.fontSize ?? fallbackSize) *
        (style?.height ?? _defaultLineSpacing);
    return math.max(
      minHeight,
      AppSpacing.md * 2 +
          math.max(_headerActionSize, lineOf(textTheme.labelMedium, 12)) +
          AppSpacing.xs +
          lineOf(textTheme.headlineMedium, 28),
    );
  }

  final String label;
  final String value;
  final String? error;
  final List<Widget> actions;

  /// Height the panel never drops below. Pinned layouts pass a smaller floor
  /// so the keypad below keeps its rows.
  final double minHeight;

  /// Puts [actions] on the label row instead of a row of their own, so the
  /// panel is the same height with and without a result. A pinned layout that
  /// sizes the keypad from the space left over cannot afford a panel that
  /// grows the moment a result lands in it.
  final bool actionsInHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasError = error != null;
    final displayValue = hasError ? error! : (value.isEmpty ? '—' : value);
    final showActions = !hasError && value.isNotEmpty && actions.isNotEmpty;
    return AnimatedContainer(
      key: const Key('resultPanel'),
      duration: const Duration(milliseconds: 180),
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasError
              ? [colors.errorContainer, colors.errorContainer]
              : [colors.primaryContainer, colors.surfaceContainerLowest],
        ),
        border: Border(
          left: BorderSide(
            color: hasError ? colors.error : colors.primary,
            width: 4,
          ),
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            // Reserves the action row's height whether or not a result is in
            // the panel, so [actionsInHeader] really does keep the panel the
            // same size in both states.
            constraints: BoxConstraints(
              minHeight: actionsInHeader ? _headerActionSize : 0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.upperCase(label),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: hasError ? colors.error : colors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                if (!hasError && value.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: colors.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                if (actionsInHeader && showActions) ...[
                  const SizedBox(width: AppSpacing.xs),
                  IconButtonTheme(
                    data: const IconButtonThemeData(
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: WidgetStatePropertyAll(
                          Size(_headerActionSize, _headerActionSize),
                        ),
                        fixedSize: WidgetStatePropertyAll(
                          Size(_headerActionSize, _headerActionSize),
                        ),
                        iconSize: WidgetStatePropertyAll(20),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(
            displayValue,
            key: const Key('resultText'),
            textAlign: TextAlign.end,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: hasError ? colors.onErrorContainer : colors.onSurface,
              fontWeight: FontWeight.w700,
              fontFamily: hasError ? null : 'monospace',
            ),
          ),
          if (!actionsInHeader && showActions) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.xxs,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

enum CalculatorKeyKind { number, operator, action, scientific, primary }

class SoftCalculatorKey extends StatefulWidget {
  const SoftCalculatorKey({
    required this.label,
    required this.onTap,
    required this.kind,
    super.key,
    this.onLongPress,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final CalculatorKeyKind kind;
  final String? semanticLabel;

  @override
  State<SoftCalculatorKey> createState() => _SoftCalculatorKeyState();
}

class _SoftCalculatorKeyState extends State<SoftCalculatorKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (background, foreground) = switch (widget.kind) {
      CalculatorKeyKind.primary => (colors.primary, colors.onPrimary),
      CalculatorKeyKind.action => (
        colors.errorContainer,
        colors.onErrorContainer,
      ),
      CalculatorKeyKind.operator => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      CalculatorKeyKind.scientific => (
        colors.primaryContainer.withValues(alpha: 0.7),
        colors.onPrimaryContainer,
      ),
      CalculatorKeyKind.number => (
        colors.surfaceContainerHigh,
        colors.onSurface,
      ),
    };
    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.label,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Material(
          color: background,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.control,
            side: BorderSide(
              color: _pressed
                  ? foreground.withValues(alpha: 0.34)
                  : colors.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: InkWell(
            borderRadius: AppRadius.control,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: Padding(
              // Keeps the longest labels off the key's border when a narrow
              // column count shrinks them to the full width of the key.
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: widget.kind == CalculatorKeyKind.number
                          ? FontWeight.w500
                          : FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TimelineCalculationItem extends StatelessWidget {
  const TimelineCalculationItem({
    required this.expression,
    required this.result,
    required this.metadata,
    required this.onTap,
    required this.actions,
    super.key,
    this.isLast = false,
  });

  final String expression;
  final String result;
  final String metadata;
  final VoidCallback onTap;
  final List<Widget> actions;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Stack(
      children: [
        if (!isLast)
          Positioned(
            left: 13.5,
            top: 12,
            bottom: 0,
            child: Container(width: 1, color: colors.outlineVariant),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 3),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                borderRadius: AppRadius.control,
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    0,
                    0,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        metadata,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        expression,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '= $result',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: AppSpacing.xxs,
                        children: actions,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class NotebookSavedItem extends StatelessWidget {
  const NotebookSavedItem({
    required this.child,
    super.key,
    this.accent,
    this.margin = const EdgeInsets.only(bottom: AppSpacing.sm),
  });

  final Widget child;
  final Color? accent;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: margin,
      child: Material(
        color: colors.surfaceContainerLowest,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: accent ?? colors.tertiary, width: 4),
              bottom: BorderSide(color: colors.outlineVariant),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GroupedSettingsSection extends StatelessWidget {
  const GroupedSettingsSection({
    required this.title,
    required this.children,
    super.key,
    this.icon,
    this.destructive = false,
  });

  final String title;
  final IconData? icon;
  final List<Widget> children;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = destructive ? colors.error : colors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(title: title, icon: icon, color: accent),
          const SizedBox(height: AppSpacing.xs),
          Material(
            color: colors.surfaceContainerLowest,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.outlineVariant),
                  bottom: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    children[index],
                    if (index != children.length - 1)
                      Divider(
                        height: 1,
                        indent: 56,
                        color: colors.outlineVariant,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyStateIllustration extends StatelessWidget {
  const EmptyStateIllustration({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 108,
                child: CustomPaint(
                  painter: _OrbitPainter(
                    color: colors.primary.withValues(alpha: 0.25),
                  ),
                  child: Icon(icon, size: 44, color: colors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (var index = 0; index < 3; index++) {
      canvas.save();
      canvas.rotate(index * math.pi / 3);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * .86,
          height: size.height * .38,
        ),
        paint,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) => oldDelegate.color != color;
}

class SectionLabel extends StatelessWidget {
  const SectionLabel({required this.title, super.key, this.icon, this.color});

  final String title;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: AppSpacing.xs),
        ],
        Expanded(
          child: Text(
            context.upperCase(title),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class AnimatedPageTransition extends StatelessWidget {
  const AnimatedPageTransition({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 260),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - value)),
        child: child,
      ),
    ),
  );
}

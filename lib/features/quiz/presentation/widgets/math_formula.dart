import 'package:calcademy/features/quiz/presentation/math_display.dart';
import 'package:flutter/material.dart';

/// One expression, painted the way it is written on paper.
///
/// The bank stores caret notation because that is what grading and a phone
/// keyboard agree on. Every quiz surface that shows mathematics -- the
/// question card, the options, the correct answer, the explanation, the review
/// entries -- puts it through here instead of printing it, so `x^(n+1)`
/// reaches the learner with a real raised `n+1` and nothing on the grading
/// side has to move.
///
/// Exponents are typeset rather than swapped for Unicode superscript glyphs.
/// That is the point of the widget: `ᵏ`, `ᵘ`, and `ₐ` are missing from most
/// monospace faces on Android, so the glyph approach degrades to a fallback
/// font or a blank box exactly on the expressions this module asks about most
/// (`e^(kx)`, `sec^2 u`, `log_a x`). Drawing the exponent as ordinary text at
/// a smaller size and a raised baseline needs no glyph coverage at all, and it
/// lifts exponents Unicode cannot spell -- `x^(1/2)`, `x^(-1/2)` -- for free.
///
/// [MathDisplay.format] still produces the plain-text spelling, which rides
/// along as the semantics label so a screen reader hears `x^2` rather than a
/// silent placeholder.
class MathFormula extends StatelessWidget {
  const MathFormula(
    this.source, {
    this.style,
    this.textAlign,
    this.selectable = false,
    super.key,
  });

  /// The expression in the bank's own notation, e.g. `d/dx (x^n)`.
  final String source;

  final TextStyle? style;
  final TextAlign? textAlign;

  /// True on the two surfaces that show the question itself, where a learner
  /// may want to copy the expression out.
  final bool selectable;

  /// How much of the surrounding font size an exponent is drawn at, and how
  /// far its baseline is lifted. The pair is chosen so a raised glyph tops out
  /// at about the ascent of the line rather than above it, which keeps the
  /// expression inside its card.
  static const _raisedScale = 0.7;
  static const _superscriptShift = -0.36;
  static const _subscriptShift = 0.16;

  @override
  Widget build(BuildContext context) {
    final resolved = DefaultTextStyle.of(context).style.merge(style);
    // The offset is a paint-time distance, so it follows the user's text
    // scale; the child's own font size does not, because the Text inside the
    // placeholder scales itself.
    final scaledSize = MediaQuery.textScalerOf(
      context,
    ).scale(resolved.fontSize ?? _fallbackFontSize);
    final span = TextSpan(
      style: resolved,
      children: _spans(resolved, scaledSize),
    );
    // A raised run is its own widget, so without a label a screen reader would
    // read an expression as the two or three fragments it is built from. Both
    // branches announce the whole thing once, in caret notation -- which is
    // also the notation the answer field wants back.
    final label = MathDisplay.format(source);
    if (selectable) {
      return Semantics(
        label: label,
        excludeSemantics: true,
        child: SelectableText.rich(span, textAlign: textAlign),
      );
    }
    return Text.rich(span, textAlign: textAlign, semanticsLabel: label);
  }

  static const _fallbackFontSize = 16.0;

  List<InlineSpan> _spans(TextStyle style, double scaledSize) => [
    for (final token in MathDisplay.tokens(source))
      switch (token.level) {
        MathLevel.base => TextSpan(text: token.text),
        MathLevel.superscript => _raised(
          token.text,
          style,
          scaledSize * _superscriptShift,
        ),
        MathLevel.subscript => _raised(
          token.text,
          style,
          scaledSize * _subscriptShift,
        ),
      },
  ];

  /// One run drawn smaller and off the baseline.
  ///
  /// The placeholder is baseline-aligned and the shift is applied inside it,
  /// so the run keeps the line's own baseline as its reference no matter what
  /// font the theme resolves to.
  static InlineSpan _raised(String text, TextStyle style, double shift) =>
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Transform.translate(
          offset: Offset(0, shift),
          child: Text(
            text,
            style: style.copyWith(
              fontSize: (style.fontSize ?? _fallbackFontSize) * _raisedScale,
              height: 1,
            ),
          ),
        ),
      );
}

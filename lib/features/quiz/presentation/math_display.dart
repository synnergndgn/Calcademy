/// Turns the bank's caret notation into the way the same expression is
/// written on paper.
///
/// The bank stores `x^(n-1)`, `sec^2 x`, and `sqrt(x)` because the answer
/// normalizer grades against that spelling and a learner can type it on a
/// phone keyboard. Nothing here changes what is stored or accepted:
/// this is the last step before a string reaches a widget, so display can be
/// polished without making grading stricter.
///
/// Two consumers share one reading of a source string. [MathDisplay.tokens] is
/// the structural one -- a flat run of pieces, each marked as ordinary text, a
/// raised exponent, or a lowered base -- and is what `MathFormula` paints with
/// real superscripts. [MathDisplay.format] is the plain-text one, which spends
/// Unicode glyphs where they exist and falls back to the source spelling where
/// they do not; it is what screen readers announce and what tests assert
/// against.
///
/// Because both start from the same tokens, the two can disagree about glyph
/// availability but never about structure: nothing can be an exponent in one
/// place and a caret in the other.
library;

/// Where a piece of an expression sits relative to the baseline.
enum MathLevel { base, superscript, subscript }

/// One run of an expression, already classified.
class MathToken {
  const MathToken(this.text, this.level, this.raw);

  const MathToken.base(String text) : this(text, MathLevel.base, text);

  /// The content itself: `n+1` for an exponent, not `^(n+1)`.
  final String text;

  final MathLevel level;

  /// The slice of the source this came from, `^(n+1)` included. It is what a
  /// plain-text rendering falls back to when a character has no raised glyph.
  final String raw;

  MathToken withText(String text) => MathToken(text, level, raw);

  @override
  String toString() => '${level.name}("$text")';
}

abstract final class MathDisplay {
  static const _superscripts = {
    '0': '⁰',
    '1': '¹',
    '2': '²',
    '3': '³',
    '4': '⁴',
    '5': '⁵',
    '6': '⁶',
    '7': '⁷',
    '8': '⁸',
    '9': '⁹',
    '+': '⁺',
    '-': '⁻',
    '(': '⁽',
    ')': '⁾',
    'a': 'ᵃ',
    'b': 'ᵇ',
    'c': 'ᶜ',
    'd': 'ᵈ',
    'e': 'ᵉ',
    'f': 'ᶠ',
    'g': 'ᵍ',
    'h': 'ʰ',
    'i': 'ⁱ',
    'j': 'ʲ',
    'k': 'ᵏ',
    'l': 'ˡ',
    'm': 'ᵐ',
    'n': 'ⁿ',
    'o': 'ᵒ',
    'p': 'ᵖ',
    'r': 'ʳ',
    's': 'ˢ',
    't': 'ᵗ',
    'u': 'ᵘ',
    'v': 'ᵛ',
    'w': 'ʷ',
    'x': 'ˣ',
    'y': 'ʸ',
    'z': 'ᶻ',
  };

  /// Only what a logarithm base needs. A missing letter falls back to the
  /// underscore spelling, which is still readable.
  static const _subscripts = {
    '0': '₀',
    '1': '₁',
    '2': '₂',
    '3': '₃',
    '4': '₄',
    '5': '₅',
    '6': '₆',
    '7': '₇',
    '8': '₈',
    '9': '₉',
    'a': 'ₐ',
    'e': 'ₑ',
    'h': 'ₕ',
    'i': 'ᵢ',
    'j': 'ⱼ',
    'k': 'ₖ',
    'l': 'ₗ',
    'm': 'ₘ',
    'n': 'ₙ',
    'o': 'ₒ',
    'p': 'ₚ',
    'r': 'ᵣ',
    's': 'ₛ',
    't': 'ₜ',
    'u': 'ᵤ',
    'v': 'ᵥ',
    'x': 'ₓ',
  };

  /// `sqrt(x)` reads as a root sign; a compound argument keeps its
  /// parentheses, because there the grouping is what makes it unambiguous.
  static final _simpleRoot = RegExp(r'sqrt\(([A-Za-z0-9]+)\)');
  static final _root = RegExp('sqrt');

  /// An exponent, either parenthesized (`^(n-1)`, `^(-1/2)`) or bare (`^3`,
  /// `^x`, `^-2`). The parenthesized group excludes brackets so a nested
  /// exponent is left alone rather than matched across the wrong one, and a
  /// bare exponent stops after one term because `x^n-1` is ambiguous.
  static final _exponent = RegExp(
    r'\^(?:\(([^()]+)\)|([+-]?(?:[0-9]+|[A-Za-z])))',
  );

  /// `_a`, `_10`. Only read as a base when a letter precedes it, so a stray
  /// underscore in prose is not mistaken for one.
  static final _base = RegExp(r'_([0-9]+|[A-Za-z])');

  /// `sec² x` is written `sec²x` and `logₐ x` as `logₐx`: the space between a
  /// function's own power or base and its argument is typographic noise.
  /// Restricted to function names so the space in `x² dx` -- where it
  /// separates two factors -- survives.
  static final _functionName = RegExp(r'(?:sin|cos|tan|cot|sec|csc|ln|log)$');

  static final _letter = RegExp('[A-Za-z]');
  static final _leadingSpace = RegExp('^ +');

  /// The structural reading of [source]: ordinary text, raised, and lowered
  /// runs in the order they appear.
  static List<MathToken> tokens(String source) {
    if (source.isEmpty) return const [];
    final value = source
        .replaceAllMapped(_simpleRoot, (match) => '√${match[1]}')
        .replaceAll(_root, '√');

    final parsed = <MathToken>[];
    final buffer = StringBuffer();
    void flush() {
      if (buffer.isEmpty) return;
      parsed.add(MathToken.base(buffer.toString()));
      buffer.clear();
    }

    var index = 0;
    while (index < value.length) {
      final character = value[index];
      if (character == '^') {
        final match = _exponent.matchAsPrefix(value, index);
        if (match != null) {
          flush();
          parsed.add(
            MathToken(match[1] ?? match[2]!, MathLevel.superscript, match[0]!),
          );
          index = match.end;
          continue;
        }
      } else if (character == '_' &&
          index > 0 &&
          _letter.hasMatch(value[index - 1])) {
        final match = _base.matchAsPrefix(value, index);
        if (match != null) {
          flush();
          parsed.add(MathToken(match[1]!, MathLevel.subscript, match[0]!));
          index = match.end;
          continue;
        }
      }
      buffer.write(character);
      index++;
    }
    flush();
    return _closeFunctionGaps(parsed);
  }

  /// The display spelling of [source] as plain text, which is left unchanged
  /// when it has nothing to raise.
  ///
  /// Anything Unicode cannot represent -- `x^(1/2)`, an exponent with a
  /// fraction in it -- stays in caret form rather than being half-converted,
  /// so a missing glyph degrades to the source spelling instead of to
  /// nonsense. `MathFormula` has no such limit; this is the plain-text
  /// fallback, not the path the learner reads.
  static String format(String source) {
    final buffer = StringBuffer();
    for (final token in tokens(source)) {
      buffer.write(switch (token.level) {
        MathLevel.base => token.text,
        MathLevel.superscript => _raise(token.text) ?? token.raw,
        MathLevel.subscript => _lower(token.text) ?? token.raw,
      });
    }
    return buffer.toString();
  }

  /// Drops the space a function's own power or base would otherwise leave in
  /// front of its argument: `sec^2 x` is one term, not two.
  static List<MathToken> _closeFunctionGaps(List<MathToken> parsed) {
    for (var index = 1; index < parsed.length - 1; index++) {
      if (parsed[index].level == MathLevel.base) continue;
      final before = parsed[index - 1];
      final after = parsed[index + 1];
      if (before.level != MathLevel.base || after.level != MathLevel.base) {
        continue;
      }
      if (!_functionName.hasMatch(before.text)) continue;
      final trimmed = after.text.replaceFirst(_leadingSpace, '');
      if (trimmed.isEmpty || trimmed == after.text) continue;
      parsed[index + 1] = after.withText(trimmed);
    }
    return parsed;
  }

  /// [text] as superscript glyphs, or null when a character has none.
  static String? _raise(String text) => _map(text, _superscripts);

  static String? _lower(String text) => _map(text, _subscripts);

  static String? _map(String text, Map<String, String> glyphs) {
    final buffer = StringBuffer();
    for (final character in text.toLowerCase().split('')) {
      final glyph = glyphs[character];
      if (glyph == null) return null;
      buffer.write(glyph);
    }
    return buffer.toString();
  }
}

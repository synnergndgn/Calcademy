/// Turns the bank's caret notation into the way the same expression is
/// written on paper.
///
/// The bank stores `x^(n-1)`, `sec^2 x`, and `sqrt(x)` because the answer
/// normalizer grades against that spelling and a learner can type it on a
/// phone keyboard. Nothing here changes what is stored or accepted:
/// this is the last step before a string reaches a widget, so display can be
/// polished without making grading stricter.
///
/// Anything the map cannot represent -- `x^(1/2)`, an exponent with a
/// fraction in it -- is left in caret form rather than half-converted, so a
/// missing glyph degrades to the source spelling instead of to nonsense.
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

  /// `x^(n-1)`. The inner group excludes parentheses so a nested exponent is
  /// left alone rather than matched across the wrong bracket.
  static final _parenthesizedExponent = RegExp(r'\^\(([^()]+)\)');

  /// `x^3`, `e^x`, `x^-2`. A bare exponent is a sign plus digits, or a single
  /// letter: `x^n-1` without parentheses is ambiguous, so only `n` is lifted.
  static final _bareExponent = RegExp(r'\^([+-]?)([0-9]+|[A-Za-z])');

  /// `log_a`, `log_10`. Anchored on a letter so a stray underscore in prose
  /// is not read as a base.
  static final _subscriptBase = RegExp(r'(?<=[A-Za-z])_([0-9]+|[A-Za-z])');

  static final _superscriptRun = RegExp('[${_superscripts.values.join()}]+');

  /// `sec² x` is written `sec²x`: the space between a raised power and the
  /// function's argument is typographic noise. Restricted to function names so
  /// the space in `x² dx` -- where it separates two factors -- survives.
  static final _functionPowerSpace = RegExp(
    '(sin|cos|tan|cot|sec|csc|ln|log)(${_superscriptRun.pattern}) +',
  );

  /// The display spelling of [source], which is left unchanged when it has
  /// nothing to raise.
  static String format(String source) {
    if (source.isEmpty) return source;
    var value = source
        .replaceAllMapped(_simpleRoot, (match) => '√${match[1]}')
        .replaceAll(_root, '√');
    value = value.replaceAllMapped(
      _parenthesizedExponent,
      (match) => _raise(match[1]!) ?? match[0]!,
    );
    value = value.replaceAllMapped(
      _bareExponent,
      (match) => _raise('${match[1]}${match[2]}') ?? match[0]!,
    );
    value = value.replaceAllMapped(
      _subscriptBase,
      (match) => _lower(match[1]!) ?? match[0]!,
    );
    return value.replaceAllMapped(
      _functionPowerSpace,
      (match) => '${match[1]}${match[2]}',
    );
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

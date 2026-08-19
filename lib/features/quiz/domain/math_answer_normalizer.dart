/// Folds the harmless ways a student can spell the same mathematical answer
/// into one canonical string.
///
/// Both sides of a comparison go through here, so the rules only need to be
/// consistent, not opinionated: `sin(x)` and `sinx` both land on `sinx`, and
/// whichever form the bank happens to store still matches typed input.
abstract final class MathAnswerNormalizer {
  /// Longest names first so `arcsin` is not consumed as `arc` + `sin`.
  static const _functionNames = [
    'arcsin',
    'arccos',
    'arctan',
    'sinh',
    'cosh',
    'tanh',
    'sqrt',
    'sin',
    'cos',
    'tan',
    'cot',
    'sec',
    'csc',
    'exp',
    'abs',
    'log',
    'ln',
  ];

  /// Every raised glyph the app can show, mapped back to what it means.
  ///
  /// The letters are here because the quiz renders `xⁿ⁻¹` and `eˣ`; a learner who
  /// copies that back into the answer field, or types it from a keyboard that
  /// offers it, is answering `x^(n-1)` and `e^x`.
  static const _superscripts = {
    '⁰': '0',
    '¹': '1',
    '²': '2',
    '³': '3',
    '⁴': '4',
    '⁵': '5',
    '⁶': '6',
    '⁷': '7',
    '⁸': '8',
    '⁹': '9',
    '⁺': '+',
    '⁻': '-',
    '⁽': '(',
    '⁾': ')',
    'ᵃ': 'a',
    'ᵇ': 'b',
    'ᶜ': 'c',
    'ᵈ': 'd',
    'ᵉ': 'e',
    'ᶠ': 'f',
    'ᵍ': 'g',
    'ʰ': 'h',
    'ⁱ': 'i',
    'ʲ': 'j',
    'ᵏ': 'k',
    'ˡ': 'l',
    'ᵐ': 'm',
    'ⁿ': 'n',
    'ᵒ': 'o',
    'ᵖ': 'p',
    'ʳ': 'r',
    'ˢ': 's',
    'ᵗ': 't',
    'ᵘ': 'u',
    'ᵛ': 'v',
    'ʷ': 'w',
    'ˣ': 'x',
    'ʸ': 'y',
    'ᶻ': 'z',
  };

  /// The mirror of [_superscripts] for a logarithm base: `logₐx` is `log_a x`.
  static const _subscripts = {
    '₀': '0',
    '₁': '1',
    '₂': '2',
    '₃': '3',
    '₄': '4',
    '₅': '5',
    '₆': '6',
    '₇': '7',
    '₈': '8',
    '₉': '9',
    'ₐ': 'a',
    'ₑ': 'e',
    'ₕ': 'h',
    'ᵢ': 'i',
    'ⱼ': 'j',
    'ₖ': 'k',
    'ₗ': 'l',
    'ₘ': 'm',
    'ₙ': 'n',
    'ₒ': 'o',
    'ₚ': 'p',
    'ᵣ': 'r',
    'ₛ': 's',
    'ₜ': 't',
    'ᵤ': 'u',
    'ᵥ': 'v',
    'ₓ': 'x',
  };

  /// Every dash-like glyph a keyboard, a textbook, or a copy-paste can produce.
  static const _minusVariants = [
    '−', // minus sign
    '–', // en dash
    '—', // em dash
    '‒', // figure dash
    '‐', // hyphen
    '‑', // non-breaking hyphen
    '－', // fullwidth hyphen-minus
  ];

  /// Multiplication is optional: `3*x`, `3·x`, and `3x` are one answer.
  static const _multiplicationVariants = ['*', '×', '⋅', '·', '∗'];

  static final _superscriptRun = RegExp('[${_superscripts.keys.join()}]+');
  static final _subscriptRun = RegExp('[${_subscripts.keys.join()}]+');
  static final _whitespace = RegExp(r'\s+');
  static final _leadingAssignment = RegExp(r"^(y|f\(x\)|f'\(x\)|dy/dx)?=");
  // No `^` anchor: this is matched with `matchAsPrefix` at an offset, which
  // anchors on its own, while a pattern anchor would only ever match index 0.
  static final _exponent = RegExp(r'\^-?[0-9]+');
  static final _simpleArgument = RegExp(r'^[a-z0-9.]+$');
  // `+` is in the class so `x^(n+1)` and the superscript form the quiz
  // displays, `xⁿ⁺¹`, land on the same string; without it only the second
  // one lost its parentheses and the two stopped matching.
  static final _parenthesizedExponent = RegExp(r'\^\(([a-z0-9.+/-]+)\)');

  static String normalize(String raw) {
    var value = raw.trim().toLowerCase();
    if (value.isEmpty) return '';
    value = _foldCharacters(value);
    value = value.replaceAll('**', '^');
    value = value.replaceAll(_whitespace, '');
    for (final symbol in _multiplicationVariants) {
      value = value.replaceAll(symbol, '');
    }
    value = value.replaceFirst(_leadingAssignment, '');
    // `exp(u)` is `e^(u)` spelled out. Rewriting it before the parenthesis
    // rules lets the existing exponent handling carry it the rest of the way,
    // so `exp(2x)` and `e^(2x)` land together instead of on `expx` and `e^2x`.
    value = value.replaceAll('exp(', 'e^(');
    value = _stripFunctionParentheses(value);
    value = value.replaceAllMapped(
      _parenthesizedExponent,
      (match) => '^${match[1]}',
    );
    value = _stripOuterParentheses(value);
    if (value.startsWith('+')) value = value.substring(1);
    return value;
  }

  static String _foldCharacters(String value) {
    var folded = value;
    for (final dash in _minusVariants) {
      folded = folded.replaceAll(dash, '-');
    }
    folded = folded
        .replaceAll('÷', '/')
        .replaceAll('√', 'sqrt')
        .replaceAll('π', 'pi');
    folded = folded.replaceAllMapped(
      _superscriptRun,
      (match) => _lower(match[0]!, '^', _superscripts),
    );
    return folded.replaceAllMapped(
      _subscriptRun,
      (match) => _lower(match[0]!, '_', _subscripts),
    );
  }

  /// One run of raised or lowered glyphs, written back as the [marker] plus
  /// the plain characters it stood for.
  static String _lower(String run, String marker, Map<String, String> glyphs) {
    final buffer = StringBuffer(marker);
    for (final character in run.split('')) {
      buffer.write(glyphs[character]);
    }
    return buffer.toString();
  }

  /// Drops the parentheses around a single-token function argument, so
  /// `cos(x)` and `cosx` agree. Anything with structure inside -- an operator,
  /// a nested call -- keeps its parentheses, because there the grouping is
  /// load bearing.
  static String _stripFunctionParentheses(String value) {
    final buffer = StringBuffer();
    var index = 0;
    while (index < value.length) {
      final name = _functionNameAt(value, index);
      if (name == null) {
        buffer.write(value[index]);
        index++;
        continue;
      }
      buffer.write(name);
      var cursor = index + name.length;
      final exponent = _exponent.matchAsPrefix(value, cursor)?[0];
      if (exponent != null) {
        buffer.write(exponent);
        cursor += exponent.length;
      }
      if (cursor < value.length && value[cursor] == '(') {
        final close = _closingParenthesis(value, cursor);
        if (close != null) {
          final argument = value.substring(cursor + 1, close);
          if (_simpleArgument.hasMatch(argument)) {
            buffer.write(argument);
            index = close + 1;
            continue;
          }
        }
      }
      index = cursor;
    }
    return buffer.toString();
  }

  static String? _functionNameAt(String value, int index) {
    for (final name in _functionNames) {
      if (value.startsWith(name, index)) return name;
    }
    return null;
  }

  static int? _closingParenthesis(String value, int open) {
    var depth = 0;
    for (var index = open; index < value.length; index++) {
      if (value[index] == '(') depth++;
      if (value[index] == ')') {
        depth--;
        if (depth == 0) return index;
      }
    }
    return null;
  }

  static String _stripOuterParentheses(String value) {
    var current = value;
    while (current.length > 1 &&
        current.startsWith('(') &&
        current.endsWith(')') &&
        _closingParenthesis(current, 0) == current.length - 1) {
      current = current.substring(1, current.length - 1);
    }
    return current;
  }
}

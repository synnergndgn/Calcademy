import 'package:calcademy/features/equation_solver/domain/equation_parser.dart';
import 'package:calcademy/features/equation_solver/domain/equation_solver_result.dart';
import 'package:calcademy/features/equation_solver/domain/root_finding.dart';

/// Entry points for the explicit numerical-methods screen: parse the
/// user's f(x), then run the requested primitive. Parse errors surface as
/// non-converged results with a typed failure, matching the shape the
/// result card renders.
class NumericalMethodService {
  const NumericalMethodService();

  NumericalMethodResult bisection({
    required String function,
    required double lower,
    required double upper,
    required double tolerance,
    required int maxIterations,
  }) => _withParsed(
    function,
    EquationSolveMethod.bisection,
    (f) => RootFinding.bisection(
      f,
      lower: lower,
      upper: upper,
      tolerance: tolerance,
      maxIterations: maxIterations,
    ),
  );

  NumericalMethodResult newtonRaphson({
    required String function,
    required double initialGuess,
    required double tolerance,
    required int maxIterations,
  }) => _withParsed(
    function,
    EquationSolveMethod.newtonRaphson,
    (f) => RootFinding.newtonRaphson(
      f,
      initialGuess: initialGuess,
      tolerance: tolerance,
      maxIterations: maxIterations,
    ),
  );

  NumericalMethodResult secant({
    required String function,
    required double firstGuess,
    required double secondGuess,
    required double tolerance,
    required int maxIterations,
  }) => _withParsed(
    function,
    EquationSolveMethod.secant,
    (f) => RootFinding.secant(
      f,
      firstGuess: firstGuess,
      secondGuess: secondGuess,
      tolerance: tolerance,
      maxIterations: maxIterations,
    ),
  );

  NumericalMethodResult _withParsed(
    String function,
    EquationSolveMethod method,
    NumericalMethodResult Function(RealFunction f) run,
  ) {
    try {
      final parsed = ParsedEquation.parse(function);
      return run(parsed.evaluate);
    } on EquationParseException catch (exception) {
      return NumericalMethodResult(
        method: method,
        converged: false,
        iterations: 0,
        failure: exception.failure,
      );
    }
  }
}

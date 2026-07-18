import 'dart:collection';

import 'package:calcademy/features/linear_programming/domain/simplex_tableau.dart';
import 'package:calcademy/features/linear_programming/domain/standard_form.dart';

enum LinearProgramStatus {
  optimal,
  multipleOptimal,
  unbounded,
  infeasible,
  iterationLimit,
  numericError,
}

class ConstraintAnalysis {
  const ConstraintAnalysis({
    required this.name,
    required this.activity,
    required this.slackOrSurplus,
    required this.active,
  });

  final String name;
  final double activity;
  final double slackOrSurplus;
  final bool active;
}

sealed class LinearProgramResult {
  LinearProgramResult({
    required this.status,
    required this.method,
    required this.iterationCount,
    required List<SimplexIteration> iterations,
    required List<String> standardizationSteps,
    this.warning,
  }) : iterations = UnmodifiableListView(iterations),
       standardizationSteps = UnmodifiableListView(standardizationSteps);

  final LinearProgramStatus status;
  final SimplexMethod method;
  final int iterationCount;
  final List<SimplexIteration> iterations;
  final List<String> standardizationSteps;
  final String? warning;
}

class FeasibleLinearProgramResult extends LinearProgramResult {
  FeasibleLinearProgramResult({
    required super.status,
    required super.method,
    required super.iterationCount,
    required super.iterations,
    required super.standardizationSteps,
    required this.objectiveValue,
    required Map<String, double> variableValues,
    required List<ConstraintAnalysis> constraintAnalysis,
    required List<String> basicVariables,
    required Map<String, double> reducedCosts,
    required this.degenerate,
    super.warning,
  }) : variableValues = UnmodifiableMapView(variableValues),
       constraintAnalysis = UnmodifiableListView(constraintAnalysis),
       basicVariables = UnmodifiableListView(basicVariables),
       reducedCosts = UnmodifiableMapView(reducedCosts);

  final double objectiveValue;
  final Map<String, double> variableValues;
  final List<ConstraintAnalysis> constraintAnalysis;
  final List<String> basicVariables;
  final Map<String, double> reducedCosts;
  final bool degenerate;
}

class FailedLinearProgramResult extends LinearProgramResult {
  FailedLinearProgramResult({
    required super.status,
    required super.method,
    required super.iterationCount,
    required super.iterations,
    required super.standardizationSteps,
    super.warning,
  });
}

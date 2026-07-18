enum MatrixOperationType {
  add,
  subtract,
  scalarMultiply,
  multiply,
  transpose,
  trace,
  determinant,
  inverse,
  rank,
  swapRows,
  scaleRow,
  addRowMultiple,
  rowEchelon,
  reducedRowEchelon,
  solveLinearSystem,
}

extension MatrixOperationTypeInfo on MatrixOperationType {
  String get localizationKey => switch (this) {
    MatrixOperationType.add => 'matrixAdd',
    MatrixOperationType.subtract => 'matrixSubtract',
    MatrixOperationType.scalarMultiply => 'matrixScalarMultiply',
    MatrixOperationType.multiply => 'matrixMultiply',
    MatrixOperationType.transpose => 'matrixTranspose',
    MatrixOperationType.trace => 'matrixTrace',
    MatrixOperationType.determinant => 'matrixDeterminant',
    MatrixOperationType.inverse => 'matrixInverse',
    MatrixOperationType.rank => 'matrixRank',
    MatrixOperationType.swapRows => 'matrixSwapRows',
    MatrixOperationType.scaleRow => 'matrixScaleRow',
    MatrixOperationType.addRowMultiple => 'matrixAddRowMultiple',
    MatrixOperationType.rowEchelon => 'matrixGauss',
    MatrixOperationType.reducedRowEchelon => 'matrixGaussJordan',
    MatrixOperationType.solveLinearSystem => 'matrixLinearSystem',
  };

  String get notation => switch (this) {
    MatrixOperationType.add => 'A + B',
    MatrixOperationType.subtract => 'A - B',
    MatrixOperationType.scalarMultiply => 'kA',
    MatrixOperationType.multiply => 'A \u00d7 B',
    MatrixOperationType.transpose => 'A\u1d40',
    MatrixOperationType.trace => 'trace(A)',
    MatrixOperationType.determinant => 'det(A)',
    MatrixOperationType.inverse => 'A\u207b\u00b9',
    MatrixOperationType.rank => 'rank(A)',
    MatrixOperationType.swapRows => 'R\u1d62 \u2194 R\u2c7c',
    MatrixOperationType.scaleRow => 'R\u1d62 \u2190 kR\u1d62',
    MatrixOperationType.addRowMultiple => 'R\u2c7c \u2190 R\u2c7c + kR\u1d62',
    MatrixOperationType.rowEchelon => 'REF',
    MatrixOperationType.reducedRowEchelon => 'RREF',
    MatrixOperationType.solveLinearSystem => 'Ax = b',
  };

  bool get needsSecondMatrix =>
      this == MatrixOperationType.add ||
      this == MatrixOperationType.subtract ||
      this == MatrixOperationType.multiply;

  bool get isRowOperation =>
      this == MatrixOperationType.swapRows ||
      this == MatrixOperationType.scaleRow ||
      this == MatrixOperationType.addRowMultiple;
}

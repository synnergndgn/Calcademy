enum MatrixErrorCode {
  invalidDimensions,
  incompatibleDimensions,
  squareRequired,
  singular,
  invalidNumber,
  invalidAugmentedMatrix,
  invalidRowOperation,
}

class MatrixException implements Exception {
  const MatrixException(this.code);

  final MatrixErrorCode code;

  @override
  String toString() => 'MatrixException(${code.name})';
}

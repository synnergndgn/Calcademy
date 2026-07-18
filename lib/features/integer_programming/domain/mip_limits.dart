import 'package:calcademy/features/integer_programming/domain/mip_constants.dart';

/// Central, overridable safety limits for a single Branch-and-Bound run.
/// Defaults mirror [MipConstants]; tests use tighter limits to exercise
/// truncated searches without solving thousands of nodes.
class MipLimits {
  const MipLimits({
    this.maxNodes = MipConstants.maxNodes,
    this.maxDepth = MipConstants.maxDepth,
    this.maxTotalIterations = MipConstants.maxTotalIterations,
  });

  final int maxNodes;
  final int maxDepth;
  final int maxTotalIterations;
}

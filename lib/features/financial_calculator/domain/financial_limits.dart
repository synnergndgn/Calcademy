abstract final class FinancialLimits {
  static const minInterestRatePercent = -99.99;
  static const maxInterestRatePercent = 1000.0;
  static const maxPeriodCount = 1000;
  static const maxCashFlowCount = 1000;
  static const maxLoanSchedulePeriods = 600;
  static const minCompoundingFrequency = 1;
  static const maxCompoundingFrequency = 365;
  static const minPaymentsPerYear = 1;
  static const maxPaymentsPerYear = 52;
  static const calculationTolerance = 1e-10;
  static const irrRateFloor = -0.9999;
  static const irrRateCeiling = 10.0;
  static const irrScanSteps = 4096;
  static const irrMaxIterations = 200;
  static const displayPrecision = 8;
}

abstract final class OperationsResearchLimits {
  static const int minTransportationSources = 2;
  static const int minTransportationDestinations = 2;
  static const int maxTransportationSources = 8;
  static const int maxTransportationDestinations = 8;
  static const int minAssignmentRows = 2;
  static const int minAssignmentColumns = 2;
  static const int maxAssignmentRows = 10;
  static const int maxAssignmentColumns = 10;
  static const int minGoalVariables = 1;
  static const int maxGoalVariables = 8;
  static const int minHardConstraints = 0;
  static const int maxHardConstraints = 12;
  static const int minGoals = 1;
  static const int maxGoals = 8;
  static const int minActivities = 1;
  static const int maxActivities = 30;
  static const int maxPredecessorsPerActivity = 10;
  static const int maxCriticalPaths = 32;
  static const int maxIterations = 500;
  static const int maxDisplayedTableCells = 64;
  static const int displayPrecision = 6;
  static const double tolerance = 1e-9;
}

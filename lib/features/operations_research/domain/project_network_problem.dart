import 'dart:collection';

enum ProjectScheduleMode { cpm, pert }

class ProjectActivity {
  ProjectActivity({
    required this.id,
    List<String> predecessors = const [],
    this.duration,
    this.optimistic,
    this.mostLikely,
    this.pessimistic,
  }) : predecessors = UnmodifiableListView(predecessors);

  final String id;
  final List<String> predecessors;
  final double? duration;
  final double? optimistic;
  final double? mostLikely;
  final double? pessimistic;
}

class ProjectNetworkProblem {
  ProjectNetworkProblem({
    required this.mode,
    required List<ProjectActivity> activities,
  }) : activities = UnmodifiableListView(activities);

  final ProjectScheduleMode mode;
  final List<ProjectActivity> activities;
}

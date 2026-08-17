import 'package:calcademy/core/widgets/calcademy_design.dart';
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return EmptyStateIllustration(
      icon: icon,
      title: title,
      body: body,
      action: action,
    );
  }
}

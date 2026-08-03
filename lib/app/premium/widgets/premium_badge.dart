import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => Chip(
    key: Key(active ? 'premium-badge-active' : 'premium-badge-locked'),
    avatar: Icon(
      active ? Icons.workspace_premium : Icons.lock_outline,
      size: 18,
    ),
    label: Text(context.l10n.t(active ? 'premiumActive' : 'premiumRequired')),
  );
}

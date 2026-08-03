import 'package:calcademy/app/premium/usage_quota.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class UsageQuotaCard extends StatelessWidget {
  const UsageQuotaCard({super.key, required this.title, required this.quota});

  final String title;
  final UsageQuota quota;

  @override
  Widget build(BuildContext context) {
    final remaining = quota.remainingToday;
    return Card(
      key: Key('usage-quota-${quota.feature.name}'),
      child: ListTile(
        leading: const Icon(Icons.speed_rounded),
        title: Text(title),
        subtitle: Text(
          remaining == null
              ? context.l10n.t('usageUnlimited')
              : context.l10n
                    .t('usageRemaining')
                    .replaceFirst('{count}', '$remaining'),
        ),
      ),
    );
  }
}

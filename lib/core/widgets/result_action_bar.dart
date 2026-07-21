import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResultActionBar extends StatelessWidget {
  const ResultActionBar({
    required this.copyText,
    this.copyButtonKey,
    this.saveAction,
    super.key,
  });

  final String copyText;
  final Key? copyButtonKey;
  final Widget? saveAction;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: copyText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.t('copied'))));
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      children: [
        TextButton.icon(
          key: copyButtonKey,
          onPressed: copyText.isEmpty ? null : () => _copy(context),
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: Text(context.l10n.t('copyResult')),
        ),
        ?saveAction,
      ],
    ),
  );
}

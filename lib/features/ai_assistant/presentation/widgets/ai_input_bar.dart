import 'package:calcademy/features/ai_assistant/domain/ai_assistant_limits.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AiInputBar extends StatelessWidget {
  const AiInputBar({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 3,
    color: Theme.of(context).colorScheme.surface,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const Key('ai-assistant-input'),
              controller: controller,
              enabled: enabled,
              onChanged: onChanged,
              onSubmitted: (_) {
                if (controller.text.trim().isNotEmpty) onSend();
              },
              minLines: 1,
              maxLines: 5,
              maxLength: AiAssistantLimits.maxInputCharacters,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: context.l10n.t('aiAssistantInputHint'),
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const Key('ai-assistant-send'),
            tooltip: context.l10n.t('aiAssistantSend'),
            onPressed: enabled && controller.text.trim().isNotEmpty
                ? onSend
                : null,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    ),
  );
}

import 'package:calcademy/app/premium/usage_quota.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_assistant_message.dart';

class AiAssistantState {
  const AiAssistantState({
    this.messages = const [],
    this.isSending = false,
    this.errorKey,
    this.quota,
  });

  final List<AiAssistantMessage> messages;
  final bool isSending;
  final String? errorKey;

  /// The remote allowance as of the last backend response, or `null` before
  /// any remote call has been answered in this session.
  final UsageQuota? quota;

  AiAssistantState copyWith({
    List<AiAssistantMessage>? messages,
    bool? isSending,
    String? errorKey,
    UsageQuota? quota,
    bool clearError = false,
  }) => AiAssistantState(
    messages: messages ?? this.messages,
    isSending: isSending ?? this.isSending,
    errorKey: clearError ? null : errorKey ?? this.errorKey,
    quota: quota ?? this.quota,
  );
}

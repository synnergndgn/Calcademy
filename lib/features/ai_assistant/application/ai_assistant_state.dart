import 'package:calcademy/features/ai_assistant/domain/ai_assistant_message.dart';

class AiAssistantState {
  const AiAssistantState({
    this.messages = const [],
    this.isSending = false,
    this.errorKey,
  });

  final List<AiAssistantMessage> messages;
  final bool isSending;
  final String? errorKey;

  AiAssistantState copyWith({
    List<AiAssistantMessage>? messages,
    bool? isSending,
    String? errorKey,
    bool clearError = false,
  }) => AiAssistantState(
    messages: messages ?? this.messages,
    isSending: isSending ?? this.isSending,
    errorKey: clearError ? null : errorKey ?? this.errorKey,
  );
}

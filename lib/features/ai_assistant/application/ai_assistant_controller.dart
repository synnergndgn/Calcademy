import 'package:calcademy/features/ai_assistant/application/ai_assistant_state.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_assistant_limits.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_assistant_message.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_assistant_role.dart';
import 'package:calcademy/features/ai_assistant/infrastructure/ai_assistant_service.dart';
import 'package:calcademy/features/ai_assistant/infrastructure/mock_ai_assistant_service.dart';
import 'package:calcademy/features/settings/presentation/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiAssistantServiceProvider = Provider<AiAssistantService>(
  (ref) => const MockAiAssistantService(),
);

final aiAssistantControllerProvider =
    NotifierProvider<AiAssistantController, AiAssistantState>(
      AiAssistantController.new,
    );

class AiAssistantController extends Notifier<AiAssistantState> {
  @override
  AiAssistantState build() {
    final languageCode = ref.watch(settingsProvider).languageCode;
    return AiAssistantState(messages: [_localModeMessage(languageCode)]);
  }

  Future<bool> send(String input, {String? languageCode}) async {
    final normalized = input.trim();
    if (normalized.isEmpty) {
      state = state.copyWith(errorKey: 'aiAssistantEmptyInput');
      return false;
    }
    if (normalized.length > AiAssistantLimits.maxInputCharacters) {
      state = state.copyWith(errorKey: 'aiAssistantCharacterLimit');
      return false;
    }
    if (state.isSending) return false;

    final now = DateTime.now();
    final userMessage = AiAssistantMessage(
      id: 'user-${now.microsecondsSinceEpoch}',
      role: AiAssistantRole.user,
      text: normalized,
      createdAt: now,
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isSending: true,
      clearError: true,
    );
    try {
      final result = await ref
          .read(aiAssistantServiceProvider)
          .analyze(
            normalized,
            languageCode:
                languageCode ?? ref.read(settingsProvider).languageCode,
          );
      state = state.copyWith(
        messages: [...state.messages, ...result.messages],
        isSending: false,
        errorKey: result.success ? null : 'aiAssistantUnsupported',
        clearError: result.success,
      );
      return result.success;
    } on Exception {
      state = state.copyWith(
        isSending: false,
        errorKey: 'aiAssistantUnsupported',
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  void reset() {
    final languageCode = ref.read(settingsProvider).languageCode;
    state = AiAssistantState(messages: [_localModeMessage(languageCode)]);
  }

  static AiAssistantMessage _localModeMessage(String languageCode) {
    final now = DateTime.now();
    return AiAssistantMessage(
      id: 'system-${now.microsecondsSinceEpoch}',
      role: AiAssistantRole.system,
      text: languageCode == 'tr'
          ? 'Bu erken sürümde asistan, desteklenen Calcademy araçlarını seçmek için yerel kurallar kullanır. Gerçek AI API entegrasyonu sonraki sürümde eklenecektir.'
          : 'In this early version, the assistant uses local rules to select supported Calcademy tools. Real AI API integration will be added in a future version.',
      createdAt: now,
    );
  }
}

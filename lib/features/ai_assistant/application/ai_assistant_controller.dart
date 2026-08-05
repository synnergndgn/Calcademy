import 'package:calcademy/app/auth/auth_gate_controller.dart';
import 'package:calcademy/app/auth/auth_status.dart';
import 'package:calcademy/app/premium/premium_feature.dart';
import 'package:calcademy/app/premium/premium_gate_controller.dart';
import 'package:calcademy/features/ai_assistant/application/ai_assistant_state.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_assistant_limits.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_assistant_message.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_assistant_role.dart';
import 'package:calcademy/features/ai_assistant/infrastructure/ai_assistant_service.dart';
import 'package:calcademy/features/ai_assistant/infrastructure/mock_ai_assistant_service.dart';
import 'package:calcademy/features/ai_assistant/infrastructure/remote_ai_assistant_service.dart';
import 'package:calcademy/features/settings/presentation/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether this build and account *could* use the remote assistant, ignoring
/// consent. Used to decide whether the opt-in is even worth offering.
final remoteAssistantEligibleProvider = Provider<bool>((ref) {
  if (ref.watch(supabaseClientProvider) == null) return false;
  if (ref.watch(authGateControllerProvider).status != AuthStatus.signedIn) {
    return false;
  }
  final entitlement = ref.watch(premiumGateControllerProvider);
  return ref
      .watch(premiumFeatureGateProvider)
      .canAccess(entitlement, PremiumFeature.geminiAssistant);
});

/// Every condition that must hold before a question may leave the device.
///
/// All of them are required. Consent alone is not enough, and neither is
/// Premium: a signed-out user, an unconfigured build, or a withdrawn consent
/// each keep the assistant fully local.
final canUseRemoteAssistantProvider = Provider<bool>(
  (ref) =>
      ref.watch(remoteAssistantEligibleProvider) &&
      ref.watch(settingsProvider).remoteAssistantEnabled,
);

final aiAssistantServiceProvider = Provider<AiAssistantService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const MockAiAssistantService();
  return RemoteAiAssistantService(
    client: client,
    fallback: const MockAiAssistantService(),
    canUseRemote: () => ref.read(canUseRemoteAssistantProvider),
  );
});

final aiAssistantControllerProvider =
    NotifierProvider<AiAssistantController, AiAssistantState>(
      AiAssistantController.new,
    );

class AiAssistantController extends Notifier<AiAssistantState> {
  @override
  AiAssistantState build() {
    final languageCode = ref.watch(settingsProvider).languageCode;
    final isRemote = ref.watch(canUseRemoteAssistantProvider);
    return AiAssistantState(messages: [_modeMessage(languageCode, isRemote)]);
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
    final isRemote = ref.read(canUseRemoteAssistantProvider);
    state = AiAssistantState(messages: [_modeMessage(languageCode, isRemote)]);
  }

  static AiAssistantMessage _modeMessage(String languageCode, bool isRemote) {
    final isTurkish = languageCode == 'tr';
    final now = DateTime.now();
    return AiAssistantMessage(
      id: 'system-${now.microsecondsSinceEpoch}',
      role: AiAssistantRole.system,
      text: isRemote
          ? (isTurkish
                ? 'Gelişmiş asistan açık. Yazdığınız soru, yanıtı üretmek için Calcademy sunucusu üzerinden Google Gemini API’sine gönderilir. Ulaşılamadığında cihazdaki yerel kurallara geri dönülür.'
                : 'The advanced assistant is on. Your question is sent through the Calcademy backend to the Google Gemini API to produce an answer. If it is unreachable, the on-device local rules take over.')
          : (isTurkish
                ? 'Asistan şu anda yalnızca cihazdaki yerel kurallarla çalışıyor. Hiçbir soru harici bir AI sağlayıcısına gönderilmiyor.'
                : 'The assistant is currently running on on-device local rules only. No question is sent to an external AI provider.'),
      createdAt: now,
    );
  }
}

import 'package:calcademy/app/tools/calcademy_tool_registry.dart';
import 'package:calcademy/features/ai_assistant/application/ai_response_composer.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_assistant_limits.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_assistant_message.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_assistant_result.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_assistant_role.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_problem_intent.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_remote_failure.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_solution_plan.dart';
import 'package:calcademy/features/ai_assistant/infrastructure/ai_assistant_service.dart';
import 'package:calcademy/features/formula_library/domain/formula_registry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Whether a remote call may be attempted at all. Evaluated per request so a
/// sign-out, a lapsed entitlement, or a withdrawn consent takes effect
/// immediately.
typedef RemoteAssistantGate = bool Function();

/// Injected so tests can drive the transport without a Supabase client.
typedef AssistantInvoker =
    Future<FunctionResponse> Function({
      required String prompt,
      required String languageCode,
    });

/// Calls the `ai-assist` Edge Function and degrades to the local rule-based
/// pipeline whenever the remote path is unavailable, refused, or unusable.
///
/// The function already validates the model's output server-side. The registry
/// checks here are a second, independent gate: the app never renders a
/// navigation action for a tool or formula it cannot resolve locally, no matter
/// what the backend returned.
class RemoteAiAssistantService implements AiAssistantService {
  RemoteAiAssistantService({
    required this.fallback,
    this.client,
    this.invoker,
    this.canUseRemote,
    this.composer = const AiResponseComposer(),
  });

  final AiAssistantService fallback;
  final SupabaseClient? client;
  final AssistantInvoker? invoker;
  final RemoteAssistantGate? canUseRemote;
  final AiResponseComposer composer;

  AiRemoteFailure? _lastFailure;

  /// Why the most recent call fell back, or `null` if it was answered
  /// remotely.
  AiRemoteFailure? get lastFailure => _lastFailure;

  @override
  Future<AiAssistantResult> analyze(
    String input, {
    required String languageCode,
  }) async {
    if (!(canUseRemote?.call() ?? true)) {
      return _fallbackTo(AiRemoteFailure.notAttempted, input, languageCode);
    }
    final invoke = invoker ?? _defaultInvoker;
    if (invoke == null) {
      return _fallbackTo(AiRemoteFailure.notAttempted, input, languageCode);
    }

    try {
      final response = await invoke(prompt: input, languageCode: languageCode);
      if (response.status < 200 || response.status >= 300) {
        return _fallbackTo(
          _failureForStatus(response.status),
          input,
          languageCode,
        );
      }
      final plan = _planFrom(response.data, languageCode);
      if (plan == null) {
        return _fallbackTo(AiRemoteFailure.unavailable, input, languageCode);
      }
      _lastFailure = null;
      return AiAssistantResult(
        success: true,
        messages: [composer.compose(plan, languageCode)],
        plan: plan,
      );
    } on FunctionException catch (error) {
      return _fallbackTo(_failureForStatus(error.status), input, languageCode);
    } catch (_) {
      return _fallbackTo(AiRemoteFailure.unavailable, input, languageCode);
    }
  }

  AssistantInvoker? get _defaultInvoker {
    final client = this.client;
    if (client == null) return null;
    return ({required String prompt, required String languageCode}) =>
        client.functions.invoke(
          'ai-assist',
          method: HttpMethod.post,
          body: {'prompt': prompt, 'languageCode': languageCode},
        );
  }

  static AiRemoteFailure _failureForStatus(int status) => switch (status) {
    403 => AiRemoteFailure.premiumRequired,
    429 => AiRemoteFailure.quotaExceeded,
    _ => AiRemoteFailure.unavailable,
  };

  Future<AiAssistantResult> _fallbackTo(
    AiRemoteFailure failure,
    String input,
    String languageCode,
  ) async {
    _lastFailure = failure;
    final result = await fallback.analyze(input, languageCode: languageCode);
    final notice = _noticeFor(failure, languageCode);
    if (notice == null) return result;
    return AiAssistantResult(
      success: result.success,
      messages: [notice, ...result.messages],
      plan: result.plan,
      error: result.error,
    );
  }

  static AiAssistantMessage? _noticeFor(
    AiRemoteFailure failure,
    String languageCode,
  ) {
    final isTurkish = languageCode == 'tr';
    final text = switch (failure) {
      AiRemoteFailure.notAttempted => null,
      AiRemoteFailure.premiumRequired =>
        isTurkish
            ? 'Gelişmiş asistan Premium aboneliğe bağlıdır. Aşağıdaki yanıt cihazdaki yerel kurallarla hazırlandı.'
            : 'The advanced assistant requires a Premium subscription. The answer below was produced by the on-device local rules.',
      AiRemoteFailure.quotaExceeded =>
        isTurkish
            ? 'Bugünkü gelişmiş asistan hakkınız doldu. Aşağıdaki yanıt cihazdaki yerel kurallarla hazırlandı.'
            : 'Your advanced assistant allowance for today is used up. The answer below was produced by the on-device local rules.',
      AiRemoteFailure.unavailable =>
        isTurkish
            ? 'Gelişmiş asistana şu anda ulaşılamıyor. Aşağıdaki yanıt cihazdaki yerel kurallarla hazırlandı.'
            : 'The advanced assistant is unreachable right now. The answer below was produced by the on-device local rules.',
    };
    if (text == null) return null;
    final now = DateTime.now();
    return AiAssistantMessage(
      id: 'system-${now.microsecondsSinceEpoch}',
      role: AiAssistantRole.system,
      text: text,
      createdAt: now,
    );
  }

  /// The backend answers in one language only, so both plan fields carry the
  /// same text. `AiSolutionPlan.summary` then returns it for either code.
  AiSolutionPlan? _planFrom(Object? data, String languageCode) {
    if (data is! Map) return null;
    if (data['success'] != true) return null;
    final summary = data['summary'];
    if (summary is! String || summary.trim().isEmpty) return null;

    final intent = _intentFrom(data['intent']);
    final steps = _stringList(data['steps']);
    final toolIds = _stringList(data['toolIds'])
        .where((id) => CalcademyToolRegistry.byId(id) != null)
        .toList(growable: false);
    final formulaIds = _stringList(data['formulaIds'])
        .where((id) => FormulaRegistry.byId(id) != null)
        .take(AiAssistantLimits.maxFormulaSuggestions)
        .toList(growable: false);
    final isOutOfScope =
        intent == AiProblemIntent.unsupported ||
        intent == AiProblemIntent.outOfScope;

    return AiSolutionPlan(
      intent: intent,
      confidence: isOutOfScope ? 0 : 0.9,
      summaryEn: summary.trim(),
      summaryTr: summary.trim(),
      stepsEn: steps,
      stepsTr: steps,
      relatedToolIds: isOutOfScope ? const [] : toolIds,
      relatedFormulaIds: isOutOfScope ? const [] : formulaIds,
      canOpenTool: !isOutOfScope && toolIds.isNotEmpty,
      canOpenFormula: !isOutOfScope && formulaIds.isNotEmpty,
      warning: intent == AiProblemIntent.finance ? 'financial' : null,
    );
  }

  static List<String> _stringList(Object? value) => value is List
      ? value
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false)
      : const [];

  static AiProblemIntent _intentFrom(Object? value) => switch (value) {
    'scientificCalculation' => AiProblemIntent.scientificCalculation,
    'graphing' => AiProblemIntent.graphing,
    'matrix' => AiProblemIntent.matrix,
    'equationSolving' => AiProblemIntent.equationSolving,
    'calculus' => AiProblemIntent.calculus,
    'statistics' => AiProblemIntent.statistics,
    'finance' => AiProblemIntent.finance,
    'linearProgramming' => AiProblemIntent.linearProgramming,
    'integerProgramming' => AiProblemIntent.integerProgramming,
    'operationsResearch' => AiProblemIntent.operationsResearch,
    'formulaLookup' => AiProblemIntent.formulaLookup,
    'outOfScope' => AiProblemIntent.outOfScope,
    _ => AiProblemIntent.unsupported,
  };
}

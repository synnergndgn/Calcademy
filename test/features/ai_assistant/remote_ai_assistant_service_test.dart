import 'package:calcademy/features/ai_assistant/domain/ai_assistant_result.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_problem_intent.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_remote_failure.dart';
import 'package:calcademy/features/ai_assistant/infrastructure/ai_assistant_service.dart';
import 'package:calcademy/features/ai_assistant/infrastructure/mock_ai_assistant_service.dart';
import 'package:calcademy/features/ai_assistant/infrastructure/remote_ai_assistant_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _RecordingFallback implements AiAssistantService {
  int calls = 0;

  @override
  Future<AiAssistantResult> analyze(
    String input, {
    required String languageCode,
  }) {
    calls += 1;
    return const MockAiAssistantService().analyze(
      input,
      languageCode: languageCode,
    );
  }
}

Map<String, Object?> _payload({
  String intent = 'equationSolving',
  String summary = 'Use the equation solver.',
  List<String> steps = const ['Enter the equation.'],
  List<String> toolIds = const ['equation_solver'],
  List<String> formulaIds = const ['quadratic-formula'],
}) => {
  'success': true,
  'intent': intent,
  'summary': summary,
  'steps': steps,
  'toolIds': toolIds,
  'formulaIds': formulaIds,
};

AssistantInvoker _respondWith(Object? data, {int status = 200}) =>
    ({required String prompt, required String languageCode}) async =>
        FunctionResponse(data: data, status: status);

AssistantInvoker _throwing(Object error) =>
    ({required String prompt, required String languageCode}) async =>
        throw error;

void main() {
  group('RemoteAiAssistantService', () {
    test('returns the remote plan when the call succeeds', () async {
      final fallback = _RecordingFallback();
      final service = RemoteAiAssistantService(
        fallback: fallback,
        invoker: _respondWith(_payload()),
      );

      final result = await service.analyze('2x + 3 = 9', languageCode: 'en');

      expect(result.success, isTrue);
      expect(fallback.calls, 0);
      expect(service.lastFailure, isNull);
      expect(result.plan?.intent, AiProblemIntent.equationSolving);
      expect(result.plan?.relatedToolIds, ['equation_solver']);
      expect(result.plan?.summary('en'), 'Use the equation solver.');
    });

    test('never calls the backend when the gate is closed', () async {
      var invoked = false;
      final fallback = _RecordingFallback();
      final service = RemoteAiAssistantService(
        fallback: fallback,
        canUseRemote: () => false,
        invoker: ({required prompt, required languageCode}) async {
          invoked = true;
          return FunctionResponse(data: _payload(), status: 200);
        },
      );

      final result = await service.analyze('2x + 3 = 9', languageCode: 'en');

      expect(invoked, isFalse);
      expect(fallback.calls, 1);
      expect(result.success, isTrue);
      expect(service.lastFailure, AiRemoteFailure.notAttempted);
    });

    test('a closed gate adds no notice message', () async {
      final service = RemoteAiAssistantService(
        fallback: _RecordingFallback(),
        canUseRemote: () => false,
        invoker: _respondWith(_payload()),
      );

      final result = await service.analyze('mean', languageCode: 'en');

      expect(result.messages.length, 1);
    });

    test('403 falls back and reports that Premium is required', () async {
      final fallback = _RecordingFallback();
      final service = RemoteAiAssistantService(
        fallback: fallback,
        invoker: _throwing(const FunctionException(status: 403)),
      );

      final result = await service.analyze('mean', languageCode: 'en');

      expect(fallback.calls, 1);
      expect(service.lastFailure, AiRemoteFailure.premiumRequired);
      expect(result.success, isTrue);
      expect(result.messages.first.text, contains('Premium'));
    });

    test('429 falls back and reports the daily allowance', () async {
      final service = RemoteAiAssistantService(
        fallback: _RecordingFallback(),
        invoker: _throwing(const FunctionException(status: 429)),
      );

      await service.analyze('mean', languageCode: 'en');

      expect(service.lastFailure, AiRemoteFailure.quotaExceeded);
    });

    test('a transport error falls back as unavailable', () async {
      final fallback = _RecordingFallback();
      final service = RemoteAiAssistantService(
        fallback: fallback,
        invoker: _throwing(Exception('socket closed')),
      );

      final result = await service.analyze('mean', languageCode: 'tr');

      expect(fallback.calls, 1);
      expect(service.lastFailure, AiRemoteFailure.unavailable);
      expect(result.messages.first.text, contains('ulaşılamıyor'));
    });

    test('a non-2xx status falls back without throwing', () async {
      final fallback = _RecordingFallback();
      final service = RemoteAiAssistantService(
        fallback: fallback,
        invoker: _respondWith(_payload(), status: 500),
      );

      await service.analyze('mean', languageCode: 'en');

      expect(fallback.calls, 1);
      expect(service.lastFailure, AiRemoteFailure.unavailable);
    });

    test('an unusable payload falls back instead of rendering it', () async {
      final fallback = _RecordingFallback();
      final service = RemoteAiAssistantService(
        fallback: fallback,
        invoker: _respondWith({'success': true, 'summary': '   '}),
      );

      await service.analyze('mean', languageCode: 'en');

      expect(fallback.calls, 1);
      expect(service.lastFailure, AiRemoteFailure.unavailable);
    });

    test('tool IDs the app cannot resolve are dropped', () async {
      final service = RemoteAiAssistantService(
        fallback: _RecordingFallback(),
        invoker: _respondWith(
          _payload(toolIds: ['equation_solver', 'root_shell', '/admin']),
        ),
      );

      final result = await service.analyze('2x = 4', languageCode: 'en');

      expect(result.plan?.relatedToolIds, ['equation_solver']);
    });

    test('formula IDs the app cannot resolve are dropped', () async {
      final service = RemoteAiAssistantService(
        fallback: _RecordingFallback(),
        invoker: _respondWith(
          _payload(formulaIds: ['quadratic-formula', 'not-a-real-formula']),
        ),
      );

      final result = await service.analyze('2x = 4', languageCode: 'en');

      expect(result.plan?.relatedFormulaIds, ['quadratic-formula']);
    });

    test('an unknown intent is treated as unsupported', () async {
      final service = RemoteAiAssistantService(
        fallback: _RecordingFallback(),
        invoker: _respondWith(_payload(intent: 'ignorePreviousInstructions')),
      );

      final result = await service.analyze('hello', languageCode: 'en');

      expect(result.plan?.intent, AiProblemIntent.unsupported);
      expect(result.plan?.canOpenTool, isFalse);
      expect(result.plan?.relatedToolIds, isEmpty);
    });

    test('out-of-scope answers carry no navigation actions', () async {
      final service = RemoteAiAssistantService(
        fallback: _RecordingFallback(),
        invoker: _respondWith(
          _payload(
            intent: 'outOfScope',
            summary: 'Outside the supported scope.',
          ),
        ),
      );

      final result = await service.analyze('weather', languageCode: 'en');

      expect(result.plan?.relatedToolIds, isEmpty);
      expect(result.plan?.relatedFormulaIds, isEmpty);
      expect(result.plan?.canOpenFormula, isFalse);
    });

    test('finance answers keep the educational disclaimer', () async {
      final service = RemoteAiAssistantService(
        fallback: _RecordingFallback(),
        invoker: _respondWith(
          _payload(intent: 'finance', toolIds: ['financial_calculator']),
        ),
      );

      final result = await service.analyze('NPV', languageCode: 'en');

      expect(result.plan?.warning, 'financial');
      expect(result.messages.first.safetyNotice, isNotNull);
    });

    test('no client and no invoker means no remote attempt', () async {
      final fallback = _RecordingFallback();
      final service = RemoteAiAssistantService(fallback: fallback);

      final result = await service.analyze('mean', languageCode: 'en');

      expect(fallback.calls, 1);
      expect(result.success, isTrue);
      expect(service.lastFailure, AiRemoteFailure.notAttempted);
    });
  });
}

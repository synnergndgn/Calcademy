import 'package:calcademy/app/premium/usage_limit.dart';
import 'package:calcademy/features/ai_assistant/infrastructure/mock_ai_assistant_service.dart';
import 'package:calcademy/features/ai_assistant/infrastructure/remote_ai_assistant_service.dart';
import 'package:calcademy/features/ai_assistant/infrastructure/remote_assistant_quota_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

AssistantInvoker _respondWith(Object? data, {int status = 200}) =>
    ({required String prompt, required String languageCode}) async =>
        FunctionResponse(data: data, status: status);

Map<String, Object?> _successBody({Map<String, Object?>? quota}) => {
  'success': true,
  'intent': 'equationSolving',
  'summary': 'Use the equation solver.',
  'steps': const ['Enter the equation.'],
  'toolIds': const ['equation_solver'],
  'formulaIds': const <String>[],
  if (quota case final Map<String, Object?> value) 'quota': value,
};

void main() {
  group('quota reported by the backend', () {
    test('a successful call carries the remaining allowance', () async {
      final service = RemoteAiAssistantService(
        fallback: const MockAiAssistantService(),
        invoker: _respondWith(
          _successBody(
            quota: {
              'used': 3,
              'limit': 20,
              'resetsAt': '2026-08-06T00:00:00.000Z',
            },
          ),
        ),
      );

      final result = await service.analyze('2x = 4', languageCode: 'en');

      expect(result.quota?.dailyLimit, 20);
      expect(result.quota?.usedToday, 3);
      expect(result.quota?.remainingToday, 17);
      expect(result.quota?.feature, UsageFeature.geminiAssistant);
    });

    test('a 429 body still reports the exhausted allowance', () async {
      final service = RemoteAiAssistantService(
        fallback: const MockAiAssistantService(),
        invoker: ({required prompt, required languageCode}) async =>
            throw const FunctionException(
              status: 429,
              details: {
                'error': 'quota_exceeded',
                'quota': {
                  'used': 20,
                  'limit': 20,
                  'resetsAt': '2026-08-06T00:00:00.000Z',
                },
              },
            ),
      );

      final result = await service.analyze('2x = 4', languageCode: 'en');

      expect(result.quota?.remainingToday, 0);
      expect(result.quota?.canUse, isFalse);
      // The user still gets a local answer alongside the exhausted quota.
      expect(result.success, isTrue);
    });

    test('a response without a quota block leaves it null', () async {
      final service = RemoteAiAssistantService(
        fallback: const MockAiAssistantService(),
        invoker: _respondWith(_successBody()),
      );

      final result = await service.analyze('2x = 4', languageCode: 'en');

      expect(result.quota, isNull);
    });

    test('a malformed quota block is ignored rather than shown', () async {
      final service = RemoteAiAssistantService(
        fallback: const MockAiAssistantService(),
        invoker: _respondWith(
          _successBody(quota: {'used': 'three', 'limit': 20}),
        ),
      );

      final result = await service.analyze('2x = 4', languageCode: 'en');

      expect(result.quota, isNull);
    });

    test('the local pipeline never reports a quota', () async {
      final result = await const MockAiAssistantService().analyze(
        '2x = 4',
        languageCode: 'en',
      );

      expect(result.quota, isNull);
    });
  });

  group('get_my_usage_quota parsing', () {
    test('reads a populated row', () {
      final quota = SupabaseRemoteAssistantQuotaRepository.parseRpcResponse([
        {
          'feature': 'gemini_assistant',
          'used_count': 5,
          'limit_count': 20,
          'period_end': '2026-08-06T00:00:00.000Z',
        },
      ]);

      expect(quota?.usedToday, 5);
      expect(quota?.remainingToday, 15);
    });

    test('an unwrapped map is accepted', () {
      final quota = SupabaseRemoteAssistantQuotaRepository.parseRpcResponse({
        'used_count': 0,
        'limit_count': 20,
        'period_end': '2026-08-06T00:00:00.000Z',
      });

      expect(quota?.remainingToday, 20);
    });

    test('a zero limit means "no row yet", not "no requests left"', () {
      // The SQL coalesces a missing window to limit_count = 0. Showing that as
      // zero remaining would tell a user who has made no requests that their
      // allowance is gone.
      final quota = SupabaseRemoteAssistantQuotaRepository.parseRpcResponse([
        {'used_count': 0, 'limit_count': 0, 'period_end': null},
      ]);

      expect(quota, isNull);
    });

    test('an empty result set is null', () {
      expect(
        SupabaseRemoteAssistantQuotaRepository.parseRpcResponse(const []),
        isNull,
      );
    });

    test('a missing period end still yields a usable reset time', () {
      final quota = SupabaseRemoteAssistantQuotaRepository.parseRpcResponse({
        'used_count': 1,
        'limit_count': 20,
        'period_end': null,
      });

      expect(quota, isNotNull);
      expect(quota!.resetsAt.isAfter(DateTime.now().toUtc()), isTrue);
    });
  });
}

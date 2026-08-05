import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/ai_assistant/application/ai_assistant_controller.dart';
import 'package:calcademy/features/ai_assistant/infrastructure/mock_ai_assistant_service.dart';
import 'package:calcademy/features/settings/presentation/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container({
  bool eligible = true,
  Map<String, Object> preferences = const {},
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      remoteAssistantEligibleProvider.overrideWithValue(eligible),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('remote assistant consent gate', () {
    test('consent is off on a fresh install', () async {
      final container = await _container();
      expect(container.read(settingsProvider).remoteAssistantEnabled, isFalse);
    });

    test('an eligible account without consent stays local', () async {
      final container = await _container();
      expect(container.read(canUseRemoteAssistantProvider), isFalse);
    });

    test('consent without eligibility stays local', () async {
      final container = await _container(
        eligible: false,
        preferences: {'settings.remoteAssistant': true},
      );
      expect(container.read(canUseRemoteAssistantProvider), isFalse);
    });

    test('eligibility plus consent opens the remote path', () async {
      final container = await _container(
        preferences: {'settings.remoteAssistant': true},
      );
      expect(container.read(canUseRemoteAssistantProvider), isTrue);
    });

    test('withdrawing consent closes the remote path again', () async {
      final container = await _container(
        preferences: {'settings.remoteAssistant': true},
      );
      expect(container.read(canUseRemoteAssistantProvider), isTrue);

      await container
          .read(settingsProvider.notifier)
          .setRemoteAssistantEnabled(false);

      expect(container.read(canUseRemoteAssistantProvider), isFalse);
    });

    test('consent survives a restart through preferences', () async {
      final container = await _container(
        preferences: {'settings.remoteAssistant': true},
      );
      expect(container.read(settingsProvider).remoteAssistantEnabled, isTrue);
    });

    test('a build without Supabase always uses the local service', () async {
      SharedPreferences.setMockInitialValues({
        'settings.remoteAssistant': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      // supabaseClientProvider defaults to null, so no remote path exists even
      // with consent stored.
      expect(container.read(remoteAssistantEligibleProvider), isFalse);
      expect(container.read(canUseRemoteAssistantProvider), isFalse);
      expect(
        container.read(aiAssistantServiceProvider),
        isA<MockAiAssistantService>(),
      );
    });
  });
}

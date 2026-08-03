import 'package:calcademy/core/services/preferences.dart';
import 'package:calcademy/features/ai_assistant/application/ai_assistant_controller.dart';
import 'package:calcademy/features/ai_assistant/domain/ai_assistant_role.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'settings.language': 'en'});
    final preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
  });

  tearDown(() => container.dispose());

  test('empty input is rejected without adding a message', () async {
    final controller = container.read(aiAssistantControllerProvider.notifier);
    final before = container
        .read(aiAssistantControllerProvider)
        .messages
        .length;
    expect(await controller.send('   '), isFalse);
    final state = container.read(aiAssistantControllerProvider);
    expect(state.messages.length, before);
    expect(state.errorKey, 'aiAssistantEmptyInput');
  });

  test('input over 1000 characters is rejected', () async {
    final controller = container.read(aiAssistantControllerProvider.notifier);
    expect(await controller.send(List.filled(1001, 'a').join()), isFalse);
    expect(
      container.read(aiAssistantControllerProvider).errorKey,
      'aiAssistantCharacterLimit',
    );
  });

  test(
    'valid input adds user and assistant messages plus local notice',
    () async {
      final controller = container.read(aiAssistantControllerProvider.notifier);
      expect(await controller.send('npv hesapla'), isTrue);
      final messages = container.read(aiAssistantControllerProvider).messages;
      expect(messages.map((item) => item.role), [
        AiAssistantRole.system,
        AiAssistantRole.user,
        AiAssistantRole.assistant,
      ]);
      expect(messages.first.text, contains('local rules'));
      expect(messages.last.relatedToolIds, contains('financial_calculator'));
      expect(messages.last.safetyNotice, contains('not financial advice'));
    },
  );

  test('unsupported input returns the exact scope notice', () async {
    final controller = container.read(aiAssistantControllerProvider.notifier);
    expect(await controller.send('hava durumu'), isTrue);
    expect(
      container.read(aiAssistantControllerProvider).messages.last.text,
      'This assistant is designed to help only with Calcademy calculation, formula, and learning tools.',
    );
  });
}

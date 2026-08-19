import 'package:calcademy/features/quiz/data/quiz_question_repository.dart';
import 'package:calcademy/features/quiz/data/quiz_topic_registry.dart';
import 'package:calcademy/features/quiz/domain/quiz_answer_validator.dart';
import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/domain/quiz_subject.dart';
import 'package:calcademy/features/quiz/domain/quiz_topic.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const english = AppLocalizations(Locale('en'));
  const turkish = AppLocalizations(Locale('tr'));

  test('quiz localization keys have English and Turkish parity', () {
    // No key is exempt. The module used to leave "Quiz" standing in Turkish;
    // there is no whitelist to put it back into.
    for (final key in _quizKeys) {
      expect(english.t(key), isNot(key), reason: 'English missing $key');
      expect(turkish.t(key), isNot(key), reason: 'Turkish missing $key');
      expect(
        english.t(key),
        isNot(turkish.t(key)),
        reason: '$key is untranslated in Turkish',
      );
    }
  });

  test('the Turkish section label is Testler, never Quiz', () {
    expect(english.t('quiz'), 'Quiz');
    expect(turkish.t('quiz'), 'Testler');
    // Every key, not a hand-picked few. The empty-state strings were left
    // saying "quiz" in Turkish precisely because they were off the old list.
    for (final key in _quizKeys) {
      expect(
        turkish.t(key).toLowerCase(),
        isNot(contains('quiz')),
        reason: '$key still says "Quiz" in Turkish',
      );
    }
  });

  test('every prompt key resolves in both locales', () {
    for (final prompt in QuizPrompt.values) {
      expect(english.t(prompt.localizationKey), isNot(prompt.localizationKey));
      expect(turkish.t(prompt.localizationKey), isNot(prompt.localizationKey));
    }
  });

  test('subjects, topics, and subtopics carry both languages', () {
    for (final subject in QuizSubject.values) {
      expect(subject.titleEn.trim(), isNotEmpty);
      expect(subject.titleTr.trim(), isNotEmpty);
      expect(subject.subtitleEn.trim(), isNotEmpty, reason: subject.id);
      expect(subject.subtitleTr.trim(), isNotEmpty, reason: subject.id);
      expect(subject.title('tr'), subject.titleTr);
      expect(subject.title('en'), subject.titleEn);
      expect(subject.subtitle('tr'), subject.subtitleTr);
      expect(subject.subtitle('en'), subject.subtitleEn);
    }
    for (final topic in QuizTopicRegistry.topics) {
      expect(topic.titleTr, isNot(topic.titleEn), reason: topic.id);
      expect(topic.descriptionEn.trim(), isNotEmpty, reason: topic.id);
      expect(topic.descriptionTr.trim(), isNotEmpty, reason: topic.id);
    }
    for (final subtopic in QuizSubtopic.values) {
      expect(subtopic.titleEn.trim(), isNotEmpty, reason: subtopic.id);
      expect(subtopic.titleTr.trim(), isNotEmpty, reason: subtopic.id);
    }
  });

  test('the calculus subject is named for its scope in Turkish', () {
    const calculus = QuizSubject.calculus;
    expect(calculus.titleEn, 'Calculus');
    expect(calculus.titleTr, 'Türev & İntegral');
    expect(
      calculus.subtitleTr,
      'Limitler, türevler, integraller ve temel formüller',
    );
    for (final subject in QuizSubject.values) {
      expect(
        '${subject.titleTr} ${subject.subtitleTr}'.toLowerCase(),
        isNot(contains('kalkülüs')),
        reason: '${subject.id} uses "Kalkülüs" in the Turkish UI',
      );
    }
  });

  group('explanations', () {
    test('every question carries both languages and resolves by locale', () {
      for (final question in QuizQuestionBank.all) {
        expect(question.explanationEn.trim(), isNotEmpty, reason: question.id);
        expect(question.explanationTr.trim(), isNotEmpty, reason: question.id);
        expect(question.explanation('tr'), question.explanationTr);
        expect(question.explanation('en'), question.explanationEn);
        // An unknown locale falls back to English rather than to a key.
        expect(question.explanation('de'), question.explanationEn);
      }
    });

    test('no Turkish explanation is left in English', () {
      for (final question in QuizQuestionBank.all) {
        for (final marker in _englishMarkers) {
          expect(
            RegExp(
              '\\b$marker\\b',
              caseSensitive: false,
            ).hasMatch(question.explanationTr),
            isFalse,
            reason:
                '${question.id} has English "$marker" in its Turkish '
                'explanation: ${question.explanationTr}',
          );
        }
      }
    });

    test('shuffling options carries both explanations along', () {
      final question = QuizQuestionBank.all.first;
      final reordered = question.withOptions(
        question.options.reversed.toList(),
      );
      expect(reordered.explanationEn, question.explanationEn);
      expect(reordered.explanationTr, question.explanationTr);
    });
  });

  test('the bank stores no prose for prompts, only keys and math', () {
    for (final question in QuizQuestionBank.all) {
      expect(
        english.t(question.prompt.localizationKey),
        isNot(question.prompt.localizationKey),
        reason: question.id,
      );
    }
  });

  group('upper-cased Turkish labels keep the dotted i', () {
    // The question card, the section labels, and the panel headings are all
    // set in caps. Dart's locale-neutral toUpperCase maps every `i` to `I`,
    // which in Turkish is a different letter: "Türevi bulun" rendered as
    // "TÜREVI BULUN".
    test('localizedUpperCase follows Turkish rules', () {
      expect(localizedUpperCase('Türevi bulun', 'tr'), 'TÜREVİ BULUN');
      expect(
        localizedUpperCase('İntegrali hesaplayın', 'tr'),
        'İNTEGRALİ HESAPLAYIN',
      );
      expect(localizedUpperCase('Bir ders seçin', 'tr'), 'BİR DERS SEÇİN');
      expect(localizedUpperCase('Geri bildirim', 'tr'), 'GERİ BİLDİRİM');
      // The dotless i already upper-cases correctly and must stay dotless.
      expect(localizedUpperCase('Alıştırma', 'tr'), 'ALIŞTIRMA');
      // English is untouched.
      expect(
        localizedUpperCase('Find the derivative', 'en'),
        'FIND THE DERIVATIVE',
      );
    });

    test('no capitalised Turkish quiz label loses its dotted i', () {
      const capitalised = [
        'quizPromptDerivative',
        'quizPromptIntegral',
        'quizChooseSubject',
        'quizChooseTopic',
        'quizFeedback',
        'quizScore',
        'quizNote',
        'quizExplanation',
        'quizHomeEyebrow',
      ];
      for (final key in capitalised) {
        final value = turkish.t(key);
        if (!value.contains('i')) continue;
        expect(
          localizedUpperCase(value, 'tr'),
          contains('İ'),
          reason: '$key drops the dotted i when capitalised: "$value"',
        );
      }
    });
  });

  test('the missing-constant note reads naturally in both locales', () {
    const key = QuizAnswerValidator.missingConstantNoteKey;
    expect(english.t(key), contains('+ C'));
    expect(turkish.t(key), contains('+ C'));
    expect(turkish.t(key), contains('belirsiz integral'));
    expect(
      RegExp(r'\bremember\b', caseSensitive: false).hasMatch(turkish.t(key)),
      isFalse,
    );
  });
}

/// Every quiz key the module renders. Shared by the parity check and the
/// Turkish-naming check so a new key cannot be added to one and not the other.
const _quizKeys = [
  'quiz',
  'quizDescription',
  'categoryPractice',
  'categoryPracticeDescription',
  'quizHomeEyebrow',
  'quizHomeSubtitle',
  'quizChooseSubject',
  'quizSubjectLocked',
  'quizChooseTopic',
  'quizAllTopics',
  'quizAllTopicsDescription',
  'quizTopics',
  'quizQuestionsAvailable',
  'quizChooseMode',
  'quizModeMultipleChoice',
  'quizModeMultipleChoiceDescription',
  'quizModeWritten',
  'quizModeWrittenDescription',
  'quizFeedback',
  'quizFeedbackImmediate',
  'quizFeedbackEndOfSession',
  'quizStartSession',
  'quizPromptDerivative',
  'quizPromptIntegral',
  'quizQuestionLabel',
  'quizAnswerHint',
  'quizSubmit',
  'quizNext',
  'quizSeeResult',
  'quizCorrect',
  'quizIncorrect',
  'quizAnswerRecorded',
  'quizCorrectAnswer',
  'quizYourAnswer',
  'quizNoAnswer',
  'quizExplanation',
  'quizNote',
  'quizNoteMissingConstant',
  'quizExitTitle',
  'quizExitBody',
  'quizExitConfirm',
  'quizResultTitle',
  'quizScore',
  'quizResultExcellent',
  'quizResultGood',
  'quizResultNeedsWork',
  'quizReviewWrong',
  'quizRetry',
  'quizBackToTopics',
  'quizReviewTitle',
  'quizReviewSubtitle',
  'quizAllCorrectTitle',
  'quizAllCorrectBody',
  'quizNoSessionTitle',
  'quizNoSessionBody',
  'quizNoQuestionsTitle',
  'quizNoQuestionsBody',
  'quizDifficultyEasy',
  'quizDifficultyMedium',
  'quizDifficultyHard',
];

/// Words that only appear in English teaching prose. A formula-only
/// explanation such as `d/dx (sin x) = cos x.` is identical in both languages
/// and trips none of them, which is the point: the check catches untranslated
/// sentences, not shared notation.
const _englishMarkers = [
  'the',
  'and',
  'is',
  'are',
  'so',
  'with',
  'from',
  'for',
  'its',
  'each',
  'every',
  'which',
  'because',
  'since',
  'gives',
  'stays',
  'holds',
  'fails',
  'follow',
  'raise',
  'divide',
  'never',
  'rule',
  'derivative',
  'antiderivative',
  'coefficient',
  'exponent',
  'constant',
  'power',
  'chain',
  'product',
  'inner',
  'outer',
  'integration',
  'sign',
  'term',
  'base',
];

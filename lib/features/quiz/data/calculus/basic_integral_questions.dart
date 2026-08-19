import 'package:calcademy/features/quiz/data/quiz_topic_registry.dart';
import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/domain/quiz_subject.dart';
import 'package:calcademy/features/quiz/domain/quiz_topic.dart';

const _topicId = CalculusTopicIds.basicIntegrals;

/// The standard antiderivative table, asked as rules rather than as exercises.
///
/// Written answers list only spellings that carry the constant of
/// integration. Dropping `+ C` still scores, but as
/// [QuizAnswerOutcome.correctWithNote] rather than a silent pass: the
/// validator derives the constant-less form, so no row has to repeat it.
const basicIntegralQuestions = <QuizQuestion>[
  QuizQuestion(
    id: 'bi-mc-01',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.powerRuleIntegral,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.integral,
    expression: '∫ x^n dx, n ≠ -1',
    correctAnswer: 'x^(n+1)/(n+1) + C',
    explanationEn:
        'The power rule for integrals raises the exponent by one and divides '
        'by the new exponent. n = -1 is excluded because it would divide by 0.',
    explanationTr:
        'İntegralde kuvvet kuralı üssü bir artırır ve yeni üsse böler. '
        'n = -1 dışarıda bırakılır, çünkü 0’a bölme çıkar.',
    options: [
      QuizOption(id: 'a', text: 'x^(n+1)/(n+1) + C'),
      QuizOption(id: 'b', text: 'x^(n-1)/(n-1) + C'),
      QuizOption(id: 'c', text: 'n x^(n-1) + C'),
      QuizOption(id: 'd', text: 'x^n/n + C'),
    ],
  ),
  QuizQuestion(
    id: 'bi-mc-02',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.basicAntiderivative,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.integral,
    expression: '∫ (1/x) dx',
    correctAnswer: 'ln|x| + C',
    explanationEn:
        'The power rule fails at n = -1; the antiderivative is ln|x|, and the '
        'absolute value is what covers negative x.',
    explanationTr:
        'Kuvvet kuralı n = -1 için geçersizdir; ters türev ln|x| olur ve '
        'mutlak değer, negatif x değerlerini kapsar.',
    options: [
      QuizOption(id: 'a', text: 'ln|x| + C'),
      QuizOption(id: 'b', text: '-1/x^2 + C'),
      QuizOption(id: 'c', text: '1/x^2 + C'),
      QuizOption(id: 'd', text: 'x ln|x| + C'),
    ],
  ),
  QuizQuestion(
    id: 'bi-mc-03',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.trigIntegral,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.integral,
    expression: '∫ sin x dx',
    correctAnswer: '-cos x + C',
    explanationEn:
        'Since d/dx (cos x) = -sin x, the antiderivative of sin x is -cos x.',
    explanationTr:
        'd/dx (cos x) = -sin x olduğundan sin x ifadesinin ters türevi -cos x '
        'olur.',
    options: [
      QuizOption(id: 'a', text: '-cos x + C'),
      QuizOption(id: 'b', text: 'cos x + C'),
      QuizOption(id: 'c', text: 'sin x + C'),
      QuizOption(id: 'd', text: '-sin x + C'),
    ],
  ),
  QuizQuestion(
    id: 'bi-mc-04',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.trigIntegral,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.integral,
    expression: '∫ cos x dx',
    correctAnswer: 'sin x + C',
    explanationEn:
        'Integration reverses d/dx (sin x) = cos x, and no sign appears.',
    explanationTr:
        'İntegral, d/dx (sin x) = cos x eşitliğini tersine çevirir; işaret '
        'değişmez.',
    options: [
      QuizOption(id: 'a', text: 'sin x + C'),
      QuizOption(id: 'b', text: '-sin x + C'),
      QuizOption(id: 'c', text: 'cos x + C'),
      QuizOption(id: 'd', text: '-cos x + C'),
    ],
  ),
  QuizQuestion(
    id: 'bi-mc-05',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.trigIntegral,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.integral,
    expression: '∫ sec^2 x dx',
    correctAnswer: 'tan x + C',
    explanationEn: 'Integration reverses d/dx (tan x) = sec^2 x.',
    explanationTr:
        'İntegral, d/dx (tan x) = sec^2 x eşitliğini tersine çevirir.',
    options: [
      QuizOption(id: 'a', text: 'tan x + C'),
      QuizOption(id: 'b', text: 'sec x + C'),
      QuizOption(id: 'c', text: '-cot x + C'),
      QuizOption(id: 'd', text: 'sec x tan x + C'),
    ],
  ),
  QuizQuestion(
    id: 'bi-mc-06',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.trigIntegral,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.integral,
    expression: '∫ csc^2 x dx',
    correctAnswer: '-cot x + C',
    explanationEn:
        'Integration reverses d/dx (cot x) = -csc^2 x, so the minus sign '
        'survives the trip back.',
    explanationTr:
        'İntegral, d/dx (cot x) = -csc^2 x eşitliğini tersine çevirir; eksi '
        'işareti geri dönüşte de kalır.',
    options: [
      QuizOption(id: 'a', text: '-cot x + C'),
      QuizOption(id: 'b', text: 'cot x + C'),
      QuizOption(id: 'c', text: '-csc x + C'),
      QuizOption(id: 'd', text: 'tan x + C'),
    ],
  ),
  QuizQuestion(
    id: 'bi-mc-07',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.trigIntegral,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.integral,
    expression: '∫ sec x tan x dx',
    correctAnswer: 'sec x + C',
    explanationEn:
        'This product is exactly d/dx (sec x), so its antiderivative is sec x.',
    explanationTr:
        'Bu çarpım tam olarak d/dx (sec x) ifadesidir; ters türevi sec x olur.',
    options: [
      QuizOption(id: 'a', text: 'sec x + C'),
      QuizOption(id: 'b', text: 'tan x + C'),
      QuizOption(id: 'c', text: 'sec^2 x + C'),
      QuizOption(id: 'd', text: '-csc x + C'),
    ],
  ),
  QuizQuestion(
    id: 'bi-mc-08',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.trigIntegral,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.integral,
    expression: '∫ csc x cot x dx',
    correctAnswer: '-csc x + C',
    explanationEn:
        'This product is d/dx (csc x) without its minus sign, so the '
        'antiderivative carries the minus instead.',
    explanationTr:
        'Bu çarpım, eksi işareti olmadan d/dx (csc x) ifadesidir; eksi bu kez '
        'ters türevde yer alır.',
    options: [
      QuizOption(id: 'a', text: '-csc x + C'),
      QuizOption(id: 'b', text: 'csc x + C'),
      QuizOption(id: 'c', text: '-cot x + C'),
      QuizOption(id: 'd', text: '-csc^2 x + C'),
    ],
  ),
  QuizQuestion(
    id: 'bi-mc-09',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.basicAntiderivative,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.integral,
    expression: '∫ k dx',
    correctAnswer: 'k x + C',
    explanationEn:
        'A constant integrates to the constant times x, because d/dx (kx) = k.',
    explanationTr:
        'Bir sabitin integrali, sabit çarpı x olur; çünkü d/dx (kx) = k.',
    options: [
      QuizOption(id: 'a', text: 'k x + C'),
      QuizOption(id: 'b', text: 'k + C'),
      QuizOption(id: 'c', text: 'x + C'),
      QuizOption(id: 'd', text: 'k x^2/2 + C'),
    ],
  ),
  QuizQuestion(
    id: 'bi-mc-10',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.constantMultiple,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.integral,
    expression: '∫ c f(x) dx',
    correctAnswer: 'c ∫ f(x) dx',
    explanationEn:
        'A constant factor can be moved outside the integral sign, which is '
        'the mirror of the constant multiple rule for derivatives.',
    explanationTr:
        'Sabit çarpan integral işaretinin dışına alınabilir; bu, türevdeki '
        'sabitle çarpım kuralının aynasıdır.',
    options: [
      QuizOption(id: 'a', text: 'c ∫ f(x) dx'),
      QuizOption(id: 'b', text: '∫ f(x) dx'),
      QuizOption(id: 'c', text: 'c f(x) + C'),
      QuizOption(id: 'd', text: '(∫ f(x) dx)/c'),
    ],
  ),
  QuizQuestion(
    id: 'bi-wr-01',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.powerRuleIntegral,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.written,
    prompt: QuizPrompt.integral,
    expression: '∫ x^n dx, n ≠ -1',
    correctAnswer: 'x^(n+1)/(n+1) + C',
    acceptedAnswers: ['(1/(n+1))x^(n+1) + C'],
    explanationEn:
        'Raise the exponent by one, then divide by the new exponent: '
        'x^(n+1)/(n+1) + C.',
    explanationTr:
        'Üssü bir artırın, sonra yeni üsse bölün: x^(n+1)/(n+1) + C.',
  ),
  QuizQuestion(
    id: 'bi-wr-02',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.basicAntiderivative,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.written,
    prompt: QuizPrompt.integral,
    expression: '∫ (1/x) dx',
    correctAnswer: 'ln|x| + C',
    // `ln x + C` is deliberately absent: it is the antiderivative on
    // x > 0 only, and accepting it would teach the narrower rule.
    acceptedAnswers: ['ln(|x|) + C'],
    explanationEn:
        'The power rule fails at n = -1. The general antiderivative is '
        'ln|x| + C, with the absolute value: ln x alone only covers x > 0.',
    explanationTr:
        'Kuvvet kuralı n = -1 için geçersizdir; genel ters türev, mutlak '
        'değerli hâliyle ln|x| + C olur.',
  ),
  QuizQuestion(
    id: 'bi-wr-03',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.trigIntegral,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.integral,
    expression: '∫ sin x dx',
    correctAnswer: '-cos x + C',
    explanationEn: 'The minus sign is the part most often dropped: -cos x + C.',
    explanationTr: 'En sık unutulan kısım eksi işaretidir: -cos x + C.',
  ),
  QuizQuestion(
    id: 'bi-wr-04',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.trigIntegral,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.integral,
    expression: '∫ cos x dx',
    correctAnswer: 'sin x + C',
    explanationEn: 'Integration reverses d/dx (sin x) = cos x.',
    explanationTr: 'İntegral, d/dx (sin x) = cos x eşitliğini tersine çevirir.',
  ),
  QuizQuestion(
    id: 'bi-wr-05',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.trigIntegral,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.integral,
    expression: '∫ sec^2 x dx',
    correctAnswer: 'tan x + C',
    explanationEn: 'Integration reverses d/dx (tan x) = sec^2 x.',
    explanationTr:
        'İntegral, d/dx (tan x) = sec^2 x eşitliğini tersine çevirir.',
  ),
  QuizQuestion(
    id: 'bi-wr-06',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.trigIntegral,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.written,
    prompt: QuizPrompt.integral,
    expression: '∫ csc^2 x dx',
    correctAnswer: '-cot x + C',
    explanationEn:
        'The co-function pair again: d/dx (cot x) = -csc^2 x, so the integral '
        'is -cot x + C.',
    explanationTr:
        'Yine eş fonksiyon çifti: d/dx (cot x) = -csc^2 x olduğundan integral '
        '-cot x + C olur.',
  ),
  QuizQuestion(
    id: 'bi-wr-07',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.trigIntegral,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.written,
    prompt: QuizPrompt.integral,
    expression: '∫ sec x tan x dx',
    correctAnswer: 'sec x + C',
    explanationEn: 'sec x tan x is d/dx (sec x), so the integral is sec x + C.',
    explanationTr:
        'sec x tan x ifadesi d/dx (sec x) olduğundan integral sec x + C olur.',
  ),
  QuizQuestion(
    id: 'bi-wr-08',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.trigIntegral,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.written,
    prompt: QuizPrompt.integral,
    expression: '∫ csc x cot x dx',
    correctAnswer: '-csc x + C',
    explanationEn:
        'd/dx (csc x) = -csc x cot x, so integrating csc x cot x gives '
        '-csc x + C.',
    explanationTr:
        'd/dx (csc x) = -csc x cot x olduğundan csc x cot x integrali '
        '-csc x + C verir.',
  ),
  QuizQuestion(
    id: 'bi-wr-09',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.basicAntiderivative,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.integral,
    expression: '∫ k dx',
    correctAnswer: 'k x + C',
    explanationEn: 'A constant integrates to that constant times x.',
    explanationTr: 'Bir sabitin integrali, o sabit çarpı x olur.',
  ),
  QuizQuestion(
    id: 'bi-wr-10',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.basicAntiderivative,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.integral,
    expression: '∫ 1 dx',
    correctAnswer: 'x + C',
    explanationEn:
        'The k = 1 case of the constant rule, and the reverse of d/dx (x) = 1.',
    explanationTr:
        'Sabit kuralının k = 1 hâli ve d/dx (x) = 1 eşitliğinin tersi.',
  ),
];

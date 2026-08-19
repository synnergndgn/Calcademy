import 'package:calcademy/features/quiz/data/quiz_topic_registry.dart';
import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/domain/quiz_subject.dart';
import 'package:calcademy/features/quiz/domain/quiz_topic.dart';

const _topicId = CalculusTopicIds.basicDerivatives;

/// The rules every derivative is built from, asked in their general form.
///
/// Nothing here asks for a computed polynomial: the module drills what a
/// learner has to recall on sight before an exam, so `d/dx (x^n)` is a
/// question and `d/dx (x^3 - 2)` is not. Ten questions of each type, so
/// either mode can fill a full ten-question session from this topic alone.
const basicDerivativeQuestions = <QuizQuestion>[
  QuizQuestion(
    id: 'bd-mc-01',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.constantRule,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (c)',
    correctAnswer: '0',
    explanationEn:
        'A constant never changes, so its rate of change is 0: d/dx (c) = 0.',
    explanationTr:
        'Sabit bir sayı hiç değişmez; değişim hızı 0’dır: d/dx (c) = 0.',
    options: [
      QuizOption(id: 'a', text: '0'),
      QuizOption(id: 'b', text: 'c'),
      QuizOption(id: 'c', text: 'c x'),
      QuizOption(id: 'd', text: '1'),
    ],
  ),
  QuizQuestion(
    id: 'bd-mc-02',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.powerRule,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (x)',
    correctAnswer: '1',
    explanationEn:
        'x is x^1, and the power rule gives 1 x^0 = 1: the line y = x rises '
        'one unit for every unit of x.',
    explanationTr:
        'x aslında x^1’dir; kuvvet kuralı 1·x^0 = 1 verir. y = x doğrusu her '
        'birim x için bir birim yükselir.',
    options: [
      QuizOption(id: 'a', text: '1'),
      QuizOption(id: 'b', text: '0'),
      QuizOption(id: 'c', text: 'x'),
      QuizOption(id: 'd', text: 'x^2/2'),
    ],
  ),
  QuizQuestion(
    id: 'bd-mc-03',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.powerRule,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (x^n)',
    correctAnswer: 'n x^(n-1)',
    explanationEn:
        'The power rule brings the exponent down in front and lowers it by '
        'one: d/dx (x^n) = n x^(n-1).',
    explanationTr:
        'Kuvvet kuralında üs öne çarpan olarak iner ve bir azalır: '
        'd/dx (x^n) = n x^(n-1).',
    options: [
      QuizOption(id: 'a', text: 'n x^(n-1)'),
      QuizOption(id: 'b', text: 'x^(n-1)'),
      QuizOption(id: 'c', text: '(n-1) x^n'),
      QuizOption(id: 'd', text: 'x^(n+1)/(n+1)'),
    ],
  ),
  QuizQuestion(
    id: 'bd-mc-04',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.constantMultiple,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (c f(x))',
    correctAnswer: 'c f\'(x)',
    explanationEn:
        'A constant factor rides along untouched: d/dx (c f(x)) = c f\'(x).',
    explanationTr: 'Sabit çarpan aynen taşınır: d/dx (c f(x)) = c f\'(x).',
    options: [
      QuizOption(id: 'a', text: 'c f\'(x)'),
      QuizOption(id: 'b', text: 'f\'(x)'),
      QuizOption(id: 'c', text: 'c f(x)'),
      QuizOption(id: 'd', text: 'f\'(x)/c'),
    ],
  ),
  QuizQuestion(
    id: 'bd-mc-05',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.sumRule,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (f(x) + g(x))',
    correctAnswer: 'f\'(x) + g\'(x)',
    explanationEn:
        'The derivative of a sum is the sum of the derivatives, so a long '
        'expression can be differentiated one piece at a time.',
    explanationTr:
        'Toplamın türevi, türevlerin toplamıdır; uzun bir ifadenin türevi '
        'parça parça alınabilir.',
    options: [
      QuizOption(id: 'a', text: 'f\'(x) + g\'(x)'),
      QuizOption(id: 'b', text: 'f\'(x) g\'(x)'),
      QuizOption(id: 'c', text: 'f\'(x) - g\'(x)'),
      QuizOption(id: 'd', text: 'f(x) + g\'(x)'),
    ],
  ),
  QuizQuestion(
    id: 'bd-mc-06',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.sumRule,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (f(x) - g(x))',
    correctAnswer: 'f\'(x) - g\'(x)',
    explanationEn:
        'The difference rule is the sum rule with a minus sign, and the order '
        'of the two terms is kept.',
    explanationTr:
        'Fark kuralı, eksi işaretli hâliyle toplam kuralıdır; iki terimin '
        'sırası korunur.',
    options: [
      QuizOption(id: 'a', text: 'f\'(x) - g\'(x)'),
      QuizOption(id: 'b', text: 'g\'(x) - f\'(x)'),
      QuizOption(id: 'c', text: 'f\'(x) + g\'(x)'),
      QuizOption(id: 'd', text: 'f\'(x) g\'(x)'),
    ],
  ),
  QuizQuestion(
    id: 'bd-mc-07',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.constantMultiple,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (k x)',
    correctAnswer: 'k',
    explanationEn:
        'kx is a constant multiple of x, and d/dx (x) = 1, so only k is left: '
        'the slope of a straight line is its coefficient.',
    explanationTr:
        'kx, x’in sabit katıdır; d/dx (x) = 1 olduğundan geriye yalnızca k '
        'kalır. Bir doğrunun eğimi, katsayısına eşittir.',
    options: [
      QuizOption(id: 'a', text: 'k'),
      QuizOption(id: 'b', text: 'k x'),
      QuizOption(id: 'c', text: '1'),
      QuizOption(id: 'd', text: '0'),
    ],
  ),
  QuizQuestion(
    id: 'bd-mc-08',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.powerRule,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (1/x)',
    correctAnswer: '-1/x^2',
    explanationEn:
        '1/x is x^-1, so the power rule holds with n = -1: -1 x^-2 = -1/x^2.',
    explanationTr:
        '1/x = x^-1 olduğundan kuvvet kuralı n = -1 için de geçerlidir: '
        '-1·x^-2 = -1/x^2.',
    options: [
      QuizOption(id: 'a', text: '-1/x^2'),
      QuizOption(id: 'b', text: '1/x^2'),
      QuizOption(id: 'c', text: '-1/x'),
      QuizOption(id: 'd', text: 'ln|x|'),
    ],
  ),
  QuizQuestion(
    id: 'bd-mc-09',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.powerRule,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (sqrt(x))',
    correctAnswer: '1/(2sqrt(x))',
    explanationEn:
        'sqrt(x) is x^(1/2), so the power rule gives (1/2)x^(-1/2), which is '
        '1/(2sqrt(x)).',
    explanationTr:
        'sqrt(x) = x^(1/2) olduğundan kuvvet kuralı (1/2)x^(-1/2), yani '
        '1/(2sqrt(x)) verir.',
    options: [
      QuizOption(id: 'a', text: '1/(2sqrt(x))'),
      QuizOption(id: 'b', text: '2sqrt(x)'),
      QuizOption(id: 'c', text: '1/sqrt(x)'),
      QuizOption(id: 'd', text: 'sqrt(x)/2'),
    ],
  ),
  QuizQuestion(
    id: 'bd-mc-10',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.productRule,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (f(x) g(x))',
    correctAnswer: 'f\'(x) g(x) + f(x) g\'(x)',
    explanationEn:
        'The product rule differentiates one factor at a time and adds the '
        'two results: f\'(x) g(x) + f(x) g\'(x).',
    explanationTr:
        'Çarpım kuralında her seferinde bir çarpanın türevi alınır ve iki '
        'sonuç toplanır: f\'(x) g(x) + f(x) g\'(x).',
    options: [
      QuizOption(id: 'a', text: 'f\'(x) g(x) + f(x) g\'(x)'),
      QuizOption(id: 'b', text: 'f\'(x) g\'(x)'),
      QuizOption(id: 'c', text: 'f\'(x) g(x) - f(x) g\'(x)'),
      QuizOption(id: 'd', text: 'f(x) g\'(x)'),
    ],
  ),
  QuizQuestion(
    id: 'bd-wr-01',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.constantRule,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (c)',
    correctAnswer: '0',
    explanationEn:
        'Every constant, positive or negative, has derivative 0: there is no '
        'change to measure.',
    explanationTr:
        'Pozitif ya da negatif, her sabitin türevi 0’dır: ölçülecek bir '
        'değişim yoktur.',
  ),
  QuizQuestion(
    id: 'bd-wr-02',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.powerRule,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (x)',
    correctAnswer: '1',
    explanationEn: 'x is x^1, and the power rule gives 1 x^0 = 1.',
    explanationTr: 'x aslında x^1’dir; kuvvet kuralı 1·x^0 = 1 verir.',
  ),
  QuizQuestion(
    id: 'bd-wr-03',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.powerRule,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (x^n)',
    correctAnswer: 'n x^(n-1)',
    explanationEn:
        'The power rule in general form: bring n down in front, then lower '
        'the exponent by one.',
    explanationTr:
        'Genel hâliyle kuvvet kuralı: n’yi öne indirin, sonra üssü bir '
        'azaltın.',
  ),
  QuizQuestion(
    id: 'bd-wr-04',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.constantMultiple,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (k x)',
    correctAnswer: 'k',
    explanationEn:
        'A constant multiple of x differentiates to the constant itself.',
    explanationTr: 'x’in sabit katının türevi, sabitin kendisidir.',
  ),
  QuizQuestion(
    id: 'bd-wr-05',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.constantMultiple,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (c f(x))',
    correctAnswer: 'c f\'(x)',
    acceptedAnswers: ['c df/dx'],
    explanationEn:
        'The constant multiple rule: a factor that does not depend on x stays '
        'in front of the derivative.',
    explanationTr:
        'Sabitle çarpım kuralı: x’e bağlı olmayan çarpan, türevin önünde '
        'kalır.',
  ),
  QuizQuestion(
    id: 'bd-wr-06',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.sumRule,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (f(x) + g(x))',
    correctAnswer: 'f\'(x) + g\'(x)',
    acceptedAnswers: ['g\'(x) + f\'(x)', 'df/dx + dg/dx'],
    explanationEn: 'The sum rule: differentiate each term and add the results.',
    explanationTr:
        'Toplam kuralı: her terimin türevini alıp sonuçları toplayın.',
  ),
  QuizQuestion(
    id: 'bd-wr-07',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.sumRule,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (f(x) - g(x))',
    correctAnswer: 'f\'(x) - g\'(x)',
    acceptedAnswers: ['df/dx - dg/dx'],
    explanationEn:
        'The difference rule works term by term as well, and the order of the '
        'two derivatives matters.',
    explanationTr:
        'Fark kuralı da terim terim işler ve iki türevin sırası önemlidir.',
  ),
  QuizQuestion(
    id: 'bd-wr-08',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.powerRule,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (1/x)',
    correctAnswer: '-1/x^2',
    acceptedAnswers: ['-x^-2'],
    explanationEn:
        'Rewrite 1/x as x^-1 first: the power rule then gives -1 x^-2.',
    explanationTr:
        'Önce 1/x ifadesini x^-1 olarak yazın; kuvvet kuralı -1·x^-2 verir.',
  ),
  QuizQuestion(
    id: 'bd-wr-09',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.powerRule,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (sqrt(x))',
    correctAnswer: '1/(2sqrt(x))',
    acceptedAnswers: ['(1/2)x^(-1/2)', '0.5x^(-1/2)'],
    explanationEn:
        'A root is a fractional power: sqrt(x) = x^(1/2), so the derivative '
        'is (1/2)x^(-1/2) = 1/(2sqrt(x)).',
    explanationTr:
        'Kök, kesirli bir üstür: sqrt(x) = x^(1/2) olduğundan türev '
        '(1/2)x^(-1/2) = 1/(2sqrt(x)) olur.',
  ),
  QuizQuestion(
    id: 'bd-wr-10',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.sumRule,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (a f(x) + b g(x))',
    correctAnswer: 'a f\'(x) + b g\'(x)',
    acceptedAnswers: ['b g\'(x) + a f\'(x)'],
    explanationEn:
        'The sum and constant multiple rules together: differentiation is '
        'linear, so constants stay put and terms stay separate.',
    explanationTr:
        'Toplam ve sabitle çarpım kuralları birlikte: türev doğrusaldır, '
        'yani sabitler yerinde kalır ve terimler ayrı ayrı işlenir.',
  ),
];

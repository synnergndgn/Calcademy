import 'package:calcademy/features/quiz/data/quiz_topic_registry.dart';
import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/domain/quiz_subject.dart';
import 'package:calcademy/features/quiz/domain/quiz_topic.dart';

const _topicId = CalculusTopicIds.trigDerivatives;

/// The six trigonometric derivatives, the constant multiple that rides on top
/// of them, and the chain rule stated in general form.
///
/// The chain-rule rows ask for the rule with a general inner function u, not
/// for the derivative of a particular composition: recalling
/// `d/dx (sin u) = cos u · u'` is memorization, working out `d/dx (sin(3x))`
/// is arithmetic.
const trigonometricDerivativeQuestions = <QuizQuestion>[
  QuizQuestion(
    id: 'td-mc-01',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.primaryTrig,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (sin x)',
    correctAnswer: 'cos x',
    explanationEn: 'sin and cos rotate into each other: d/dx (sin x) = cos x.',
    explanationTr: 'sin ile cos birbirine dönüşür: d/dx (sin x) = cos x.',
    options: [
      QuizOption(id: 'a', text: 'cos x'),
      QuizOption(id: 'b', text: '-cos x'),
      QuizOption(id: 'c', text: 'sin x'),
      QuizOption(id: 'd', text: '-sin x'),
    ],
  ),
  QuizQuestion(
    id: 'td-mc-02',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.primaryTrig,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (cos x)',
    correctAnswer: '-sin x',
    explanationEn:
        'Differentiating cos picks up a minus sign, which is the half of this '
        'pair most often dropped: d/dx (cos x) = -sin x.',
    explanationTr:
        'cos türevi alınırken eksi işareti öne çıkar; bu çiftte en sık '
        'unutulan kısım budur: d/dx (cos x) = -sin x.',
    options: [
      QuizOption(id: 'a', text: '-sin x'),
      QuizOption(id: 'b', text: 'sin x'),
      QuizOption(id: 'c', text: '-cos x'),
      QuizOption(id: 'd', text: 'cos x'),
    ],
  ),
  QuizQuestion(
    id: 'td-mc-03',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.primaryTrig,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (tan x)',
    correctAnswer: 'sec^2 x',
    explanationEn:
        'The quotient rule on sin x / cos x collapses to sec^2 x, which is '
        'also 1/cos^2 x.',
    explanationTr:
        'sin x / cos x üzerinde bölüm kuralı sadeleşip sec^2 x verir; bu da '
        '1/cos^2 x demektir.',
    options: [
      QuizOption(id: 'a', text: 'sec^2 x'),
      QuizOption(id: 'b', text: '-csc^2 x'),
      QuizOption(id: 'c', text: 'sec x tan x'),
      QuizOption(id: 'd', text: 'cot x'),
    ],
  ),
  QuizQuestion(
    id: 'td-mc-04',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.reciprocalTrig,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (cot x)',
    correctAnswer: '-csc^2 x',
    explanationEn:
        'cot is the co-function of tan, so it mirrors sec^2 x with a minus '
        'sign: -csc^2 x.',
    explanationTr:
        'cot, tan fonksiyonunun eş fonksiyonudur; bu yüzden sec^2 x '
        'ifadesinin eksi işaretli karşılığını verir: -csc^2 x.',
    options: [
      QuizOption(id: 'a', text: '-csc^2 x'),
      QuizOption(id: 'b', text: 'csc^2 x'),
      QuizOption(id: 'c', text: '-sec^2 x'),
      QuizOption(id: 'd', text: '-csc x cot x'),
    ],
  ),
  QuizQuestion(
    id: 'td-mc-05',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.reciprocalTrig,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (sec x)',
    correctAnswer: 'sec x tan x',
    explanationEn:
        'sec x = 1/cos x, and differentiating it leaves the product '
        'sec x tan x.',
    explanationTr:
        'sec x = 1/cos x olduğundan türevi geriye sec x tan x çarpımını '
        'bırakır.',
    options: [
      QuizOption(id: 'a', text: 'sec x tan x'),
      QuizOption(id: 'b', text: '-sec x tan x'),
      QuizOption(id: 'c', text: 'csc x cot x'),
      QuizOption(id: 'd', text: 'sec^2 x'),
    ],
  ),
  QuizQuestion(
    id: 'td-mc-06',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.reciprocalTrig,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (csc x)',
    correctAnswer: '-csc x cot x',
    explanationEn:
        'Every co-function derivative carries a minus sign, so csc mirrors '
        'sec: -csc x cot x.',
    explanationTr:
        'Eş fonksiyonların türevi eksi işareti taşır; csc, sec fonksiyonunun '
        'aynasıdır: -csc x cot x.',
    options: [
      QuizOption(id: 'a', text: '-csc x cot x'),
      QuizOption(id: 'b', text: 'csc x cot x'),
      QuizOption(id: 'c', text: '-sec x tan x'),
      QuizOption(id: 'd', text: '-csc^2 x'),
    ],
  ),
  QuizQuestion(
    id: 'td-mc-07',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.constantMultiple,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (a sin x)',
    correctAnswer: 'a cos x',
    explanationEn:
        'The constant multiple rule keeps a in front while sin x becomes '
        'cos x.',
    explanationTr:
        'Sabitle çarpım kuralı a çarpanını önde tutar; sin x ise cos x olur.',
    options: [
      QuizOption(id: 'a', text: 'a cos x'),
      QuizOption(id: 'b', text: 'cos x'),
      QuizOption(id: 'c', text: '-a cos x'),
      QuizOption(id: 'd', text: 'a sin x'),
    ],
  ),
  QuizQuestion(
    id: 'td-mc-08',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.constantMultiple,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (a cos x)',
    correctAnswer: '-a sin x',
    explanationEn:
        'The constant stays and the minus sign from cos comes with it: '
        '-a sin x.',
    explanationTr:
        'Sabit yerinde kalır ve cos türevinden gelen eksi işareti de ona '
        'eşlik eder: -a sin x.',
    options: [
      QuizOption(id: 'a', text: '-a sin x'),
      QuizOption(id: 'b', text: 'a sin x'),
      QuizOption(id: 'c', text: '-a cos x'),
      QuizOption(id: 'd', text: '-sin x'),
    ],
  ),
  QuizQuestion(
    id: 'td-mc-09',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.chainRule,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (sin u)',
    correctAnswer: 'cos u · u\'',
    explanationEn:
        'The chain rule in general form: differentiate the outer function, '
        'then multiply by the derivative of the inner one.',
    explanationTr:
        'Genel hâliyle zincir kuralı: önce dış fonksiyonun türevini alın, '
        'sonra içteki fonksiyonun türeviyle çarpın.',
    options: [
      QuizOption(id: 'a', text: 'cos u · u\''),
      QuizOption(id: 'b', text: 'cos u'),
      QuizOption(id: 'c', text: '-sin u · u\''),
      QuizOption(id: 'd', text: 'sin u · u\''),
    ],
  ),
  QuizQuestion(
    id: 'td-mc-10',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.chainRule,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (tan u)',
    correctAnswer: 'sec^2 u · u\'',
    explanationEn:
        'Each trigonometric rule keeps its shape under the chain rule, with '
        'u in place of x and a factor of u\' at the end.',
    explanationTr:
        'Her trigonometrik kural, zincir kuralı altında biçimini korur: x '
        'yerine u yazılır ve sona u\' çarpanı eklenir.',
    options: [
      QuizOption(id: 'a', text: 'sec^2 u · u\''),
      QuizOption(id: 'b', text: 'sec^2 u'),
      QuizOption(id: 'c', text: '-csc^2 u · u\''),
      QuizOption(id: 'd', text: 'sec u tan u · u\''),
    ],
  ),
  QuizQuestion(
    id: 'td-wr-01',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.primaryTrig,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (sin x)',
    correctAnswer: 'cos x',
    explanationEn: 'd/dx (sin x) = cos x, with no sign change.',
    explanationTr: 'd/dx (sin x) = cos x; işaret değişmez.',
  ),
  QuizQuestion(
    id: 'td-wr-02',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.primaryTrig,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (cos x)',
    correctAnswer: '-sin x',
    explanationEn: 'd/dx (cos x) = -sin x. The minus sign is part of the rule.',
    explanationTr: 'd/dx (cos x) = -sin x. Eksi işareti kuralın parçasıdır.',
  ),
  QuizQuestion(
    id: 'td-wr-03',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.primaryTrig,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (tan x)',
    correctAnswer: 'sec^2 x',
    acceptedAnswers: ['1/cos^2 x', 'sec(x)^2'],
    explanationEn: 'd/dx (tan x) = sec^2 x, equivalently 1/cos^2 x.',
    explanationTr: 'd/dx (tan x) = sec^2 x, yani 1/cos^2 x.',
  ),
  QuizQuestion(
    id: 'td-wr-04',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.reciprocalTrig,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (cot x)',
    correctAnswer: '-csc^2 x',
    acceptedAnswers: ['-1/sin^2 x', '-csc(x)^2'],
    explanationEn: 'd/dx (cot x) = -csc^2 x, equivalently -1/sin^2 x.',
    explanationTr: 'd/dx (cot x) = -csc^2 x, yani -1/sin^2 x.',
  ),
  QuizQuestion(
    id: 'td-wr-05',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.reciprocalTrig,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (sec x)',
    correctAnswer: 'sec x tan x',
    acceptedAnswers: ['tan x sec x'],
    explanationEn: 'd/dx (sec x) = sec x tan x, a product of two functions.',
    explanationTr: 'd/dx (sec x) = sec x tan x; iki fonksiyonun çarpımı.',
  ),
  QuizQuestion(
    id: 'td-wr-06',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.reciprocalTrig,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (csc x)',
    correctAnswer: '-csc x cot x',
    acceptedAnswers: ['-cot x csc x'],
    explanationEn: 'd/dx (csc x) = -csc x cot x, the co-function of sec x.',
    explanationTr: 'd/dx (csc x) = -csc x cot x; sec x eş fonksiyonudur.',
  ),
  QuizQuestion(
    id: 'td-wr-07',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.constantMultiple,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (a sin x)',
    correctAnswer: 'a cos x',
    explanationEn: 'The constant multiple rule leaves a untouched: a cos x.',
    explanationTr: 'Sabitle çarpım kuralı a çarpanına dokunmaz: a cos x.',
  ),
  QuizQuestion(
    id: 'td-wr-08',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.constantMultiple,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (a cos x)',
    correctAnswer: '-a sin x',
    explanationEn:
        'Keep the constant and take the derivative of cos, minus sign '
        'included: -a sin x.',
    explanationTr:
        'Sabiti koruyup cos türevini alın; eksi işareti de dâhildir: '
        '-a sin x.',
  ),
  QuizQuestion(
    id: 'td-wr-09',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.chainRule,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (sin u)',
    correctAnswer: 'cos u · u\'',
    acceptedAnswers: ['cos u du/dx', 'u\' cos u'],
    explanationEn:
        'The chain rule form of the sine rule: cos u, times the derivative of '
        'the inner function u.',
    explanationTr:
        'Sinüs kuralının zincir hâli: cos u ile içteki u fonksiyonunun '
        'türevinin çarpımı.',
  ),
  QuizQuestion(
    id: 'td-wr-10',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.chainRule,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (cos u)',
    correctAnswer: '-sin u · u\'',
    acceptedAnswers: ['-sin u du/dx', '-u\' sin u'],
    explanationEn:
        'The chain rule form of the cosine rule, minus sign and all: '
        '-sin u · u\'.',
    explanationTr:
        'Kosinüs kuralının zincir hâli, eksi işaretiyle birlikte: '
        '-sin u · u\'.',
  ),
];

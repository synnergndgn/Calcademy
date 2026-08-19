import 'package:calcademy/features/quiz/data/quiz_topic_registry.dart';
import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/domain/quiz_subject.dart';
import 'package:calcademy/features/quiz/domain/quiz_topic.dart';

const _topicId = CalculusTopicIds.expLogDerivatives;

/// Exponential and logarithmic rules in both directions: the derivatives and
/// the antiderivatives a learner is expected to recall without deriving them.
///
/// The general bases are here because they are the ones that collapse into
/// the base-e cases under pressure -- `d/dx (a^x) = a^x ln a` is exactly the
/// factor that gets dropped.
const exponentialLogarithmicDerivativeQuestions = <QuizQuestion>[
  QuizQuestion(
    id: 'el-mc-01',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.exponential,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (e^x)',
    correctAnswer: 'e^x',
    explanationEn:
        'e^x is its own derivative, the only function (up to a constant '
        'factor) with that property.',
    explanationTr:
        'e^x kendi türevine eşittir; bu özelliği taşıyan tek fonksiyondur '
        '(sabit çarpanlar dışında).',
    options: [
      QuizOption(id: 'a', text: 'e^x'),
      QuizOption(id: 'b', text: 'x e^(x-1)'),
      QuizOption(id: 'c', text: 'e^x/x'),
      QuizOption(id: 'd', text: 'x e^x'),
    ],
  ),
  QuizQuestion(
    id: 'el-mc-02',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.exponential,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (a^x)',
    correctAnswer: 'a^x ln a',
    explanationEn:
        'A general base picks up ln of the base: d/dx (a^x) = a^x ln a. With '
        'a = e the factor is ln e = 1, which is why e^x looks simpler.',
    explanationTr:
        'Genel tabanda, tabanın doğal logaritması çarpan olarak gelir: '
        'd/dx (a^x) = a^x ln a. a = e için ln e = 1 olduğundan e^x daha yalın '
        'görünür.',
    options: [
      QuizOption(id: 'a', text: 'a^x ln a'),
      QuizOption(id: 'b', text: 'x a^(x-1)'),
      QuizOption(id: 'c', text: 'a^x'),
      QuizOption(id: 'd', text: 'a^x / ln a'),
    ],
  ),
  QuizQuestion(
    id: 'el-mc-03',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.logarithmic,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (ln x)',
    correctAnswer: '1/x',
    explanationEn:
        'd/dx (ln x) = 1/x, the one power the power rule cannot '
        'produce.',
    explanationTr:
        'd/dx (ln x) = 1/x; kuvvet kuralının üretemediği tek üs budur.',
    options: [
      QuizOption(id: 'a', text: '1/x'),
      QuizOption(id: 'b', text: 'ln x'),
      QuizOption(id: 'c', text: 'x ln x'),
      QuizOption(id: 'd', text: '-1/x^2'),
    ],
  ),
  QuizQuestion(
    id: 'el-mc-04',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.logarithmic,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (log_a x)',
    correctAnswer: '1/(x ln a)',
    explanationEn:
        'log_a x = ln x / ln a, and ln a is a constant, so the derivative is '
        '1/(x ln a).',
    explanationTr:
        'log_a x = ln x / ln a olur; ln a sabit olduğundan türev 1/(x ln a) '
        'çıkar.',
    options: [
      QuizOption(id: 'a', text: '1/(x ln a)'),
      QuizOption(id: 'b', text: '1/x'),
      QuizOption(id: 'c', text: 'ln a / x'),
      QuizOption(id: 'd', text: '1/(a x)'),
    ],
  ),
  QuizQuestion(
    id: 'el-mc-05',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.exponential,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.integral,
    expression: '∫ e^x dx',
    correctAnswer: 'e^x + C',
    explanationEn:
        'e^x is unchanged by integration as well as differentiation, so only '
        'the constant of integration is added.',
    explanationTr:
        'e^x, türev almada olduğu gibi integral almada da değişmez; yalnızca '
        'integral sabiti eklenir.',
    options: [
      QuizOption(id: 'a', text: 'e^x + C'),
      QuizOption(id: 'b', text: 'x e^x + C'),
      QuizOption(id: 'c', text: 'e^x/x + C'),
      QuizOption(id: 'd', text: 'e^(x+1)/(x+1) + C'),
    ],
  ),
  QuizQuestion(
    id: 'el-mc-06',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.exponential,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.integral,
    expression: '∫ a^x dx',
    correctAnswer: 'a^x/ln a + C',
    explanationEn:
        'Integration undoes d/dx (a^x) = a^x ln a, so the ln a that appears '
        'as a factor there appears as a divisor here.',
    explanationTr:
        'İntegral, d/dx (a^x) = a^x ln a eşitliğini tersine çevirir; orada '
        'çarpan olan ln a burada bölen olur.',
    options: [
      QuizOption(id: 'a', text: 'a^x/ln a + C'),
      QuizOption(id: 'b', text: 'a^x ln a + C'),
      QuizOption(id: 'c', text: 'a^x + C'),
      QuizOption(id: 'd', text: 'a^(x+1)/(x+1) + C'),
    ],
  ),
  QuizQuestion(
    id: 'el-mc-07',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.chainRule,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (e^u)',
    correctAnswer: 'e^u · u\'',
    explanationEn:
        'The chain rule form: e^u is unchanged, and the derivative of the '
        'inner function comes along as a factor.',
    explanationTr:
        'Zincir hâli: e^u değişmez ve içteki fonksiyonun türevi çarpan olarak '
        'eklenir.',
    options: [
      QuizOption(id: 'a', text: 'e^u · u\''),
      QuizOption(id: 'b', text: 'e^u'),
      QuizOption(id: 'c', text: 'u e^(u-1)'),
      QuizOption(id: 'd', text: 'e^u / u\''),
    ],
  ),
  QuizQuestion(
    id: 'el-mc-08',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.chainRule,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (ln u)',
    correctAnswer: 'u\'/u',
    explanationEn:
        'The chain rule form of the logarithm rule: 1/u times u\', which is '
        'written u\'/u.',
    explanationTr:
        'Logaritma kuralının zincir hâli: 1/u ile u\' çarpımı, yani u\'/u.',
    options: [
      QuizOption(id: 'a', text: 'u\'/u'),
      QuizOption(id: 'b', text: '1/u'),
      QuizOption(id: 'c', text: 'u/u\''),
      QuizOption(id: 'd', text: 'ln u · u\''),
    ],
  ),
  QuizQuestion(
    id: 'el-mc-09',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.chainRule,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (e^(kx))',
    correctAnswer: 'k e^(kx)',
    explanationEn:
        'The standard growth rule: a constant k in the exponent comes down as '
        'a factor and the exponential itself is unchanged.',
    explanationTr:
        'Standart büyüme kuralı: üsteki k sabiti çarpan olarak öne iner, '
        'üstel ifade ise değişmez.',
    options: [
      QuizOption(id: 'a', text: 'k e^(kx)'),
      QuizOption(id: 'b', text: 'e^(kx)'),
      QuizOption(id: 'c', text: 'e^(kx)/k'),
      QuizOption(id: 'd', text: 'kx e^(kx-1)'),
    ],
  ),
  QuizQuestion(
    id: 'el-mc-10',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.exponential,
    difficulty: QuizDifficulty.hard,
    type: QuestionType.multipleChoice,
    prompt: QuizPrompt.integral,
    expression: '∫ e^(kx) dx',
    correctAnswer: 'e^(kx)/k + C',
    explanationEn:
        'Integration reverses the growth rule, so the k that multiplies on '
        'the way out divides on the way back.',
    explanationTr:
        'İntegral, büyüme kuralını tersine çevirir: türevde çarpan olan k, '
        'integralde bölen olur.',
    options: [
      QuizOption(id: 'a', text: 'e^(kx)/k + C'),
      QuizOption(id: 'b', text: 'k e^(kx) + C'),
      QuizOption(id: 'c', text: 'e^(kx) + C'),
      QuizOption(id: 'd', text: 'e^(kx)/(kx) + C'),
    ],
  ),
  QuizQuestion(
    id: 'el-wr-01',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.exponential,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (e^x)',
    correctAnswer: 'e^x',
    explanationEn: 'e^x is its own derivative.',
    explanationTr: 'e^x kendi türevine eşittir.',
  ),
  QuizQuestion(
    id: 'el-wr-02',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.logarithmic,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (ln x)',
    correctAnswer: '1/x',
    acceptedAnswers: ['x^-1'],
    explanationEn: 'd/dx (ln x) = 1/x.',
    explanationTr: 'd/dx (ln x) = 1/x.',
  ),
  QuizQuestion(
    id: 'el-wr-03',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.exponential,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (a^x)',
    correctAnswer: 'a^x ln a',
    acceptedAnswers: ['(ln a) a^x'],
    explanationEn:
        'A general base picks up ln of the base as a factor: a^x ln a.',
    explanationTr:
        'Genel tabanda, tabanın doğal logaritması çarpan olarak gelir: '
        'a^x ln a.',
  ),
  QuizQuestion(
    id: 'el-wr-04',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.logarithmic,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (log_a x)',
    correctAnswer: '1/(x ln a)',
    acceptedAnswers: ['1/(ln a · x)'],
    explanationEn:
        'Change the base first: log_a x = ln x / ln a, so the derivative is '
        '1/(x ln a).',
    explanationTr:
        'Önce taban değiştirin: log_a x = ln x / ln a olduğundan türev '
        '1/(x ln a) olur.',
  ),
  QuizQuestion(
    id: 'el-wr-05',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.exponential,
    difficulty: QuizDifficulty.easy,
    type: QuestionType.written,
    prompt: QuizPrompt.integral,
    expression: '∫ e^x dx',
    correctAnswer: 'e^x + C',
    explanationEn: 'e^x is its own antiderivative, so only + C is added.',
    explanationTr: 'e^x kendi ters türevine eşittir; yalnızca + C eklenir.',
  ),
  QuizQuestion(
    id: 'el-wr-06',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.exponential,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.written,
    prompt: QuizPrompt.integral,
    expression: '∫ a^x dx',
    correctAnswer: 'a^x/ln a + C',
    acceptedAnswers: ['a^x/(ln a) + C'],
    explanationEn:
        'ln a multiplies when a^x is differentiated, so it divides when a^x '
        'is integrated.',
    explanationTr: 'a^x türevinde çarpan olan ln a, integralinde bölen olur.',
  ),
  QuizQuestion(
    id: 'el-wr-07',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.chainRule,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (e^u)',
    correctAnswer: 'e^u · u\'',
    acceptedAnswers: ['e^u du/dx'],
    explanationEn:
        'The exponential is unchanged and the inner derivative is attached as '
        'a factor.',
    explanationTr:
        'Üstel ifade değişmez, içteki fonksiyonun türevi çarpan olarak '
        'eklenir.',
  ),
  QuizQuestion(
    id: 'el-wr-08',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.chainRule,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (ln u)',
    correctAnswer: 'u\'/u',
    acceptedAnswers: ['(du/dx)/u'],
    explanationEn:
        'The logarithm rule under the chain rule: the inner derivative over '
        'the inner function.',
    explanationTr:
        'Zincir kuralı altında logaritma kuralı: içteki fonksiyonun türevi '
        'bölü fonksiyonun kendisi.',
  ),
  QuizQuestion(
    id: 'el-wr-09',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.chainRule,
    difficulty: QuizDifficulty.medium,
    type: QuestionType.written,
    prompt: QuizPrompt.derivative,
    expression: 'd/dx (e^(kx))',
    correctAnswer: 'k e^(kx)',
    explanationEn:
        'The constant in the exponent becomes a factor in front; the '
        'exponential itself is unchanged.',
    explanationTr:
        'Üsteki sabit, öne çarpan olarak geçer; üstel ifade aynı kalır.',
  ),
  QuizQuestion(
    id: 'el-wr-10',
    subject: QuizSubject.calculus,
    topicId: _topicId,
    subtopic: QuizSubtopic.exponential,
    difficulty: QuizDifficulty.hard,
    type: QuestionType.written,
    prompt: QuizPrompt.integral,
    expression: '∫ e^(kx) dx',
    correctAnswer: 'e^(kx)/k + C',
    acceptedAnswers: ['(1/k)e^(kx) + C'],
    explanationEn:
        'Dividing by k is what undoes the factor of k the chain rule would '
        'produce.',
    explanationTr:
        'k’ye bölmek, zincir kuralının üreteceği k çarpanını geri alır.',
  ),
];

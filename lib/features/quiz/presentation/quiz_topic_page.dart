import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/calcademy_design.dart';
import 'package:calcademy/core/widgets/empty_state.dart';
import 'package:calcademy/features/quiz/data/quiz_question_repository.dart';
import 'package:calcademy/features/quiz/data/quiz_topic_registry.dart';
import 'package:calcademy/features/quiz/domain/quiz_subject.dart';
import 'package:calcademy/features/quiz/presentation/widgets/quiz_choice_card.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Topic picker for one subject, with a mixed option at the top.
///
/// The mixed option is routed as the reserved topic id [mixedTopicId], which
/// the mode screen turns into an empty topic filter.
class QuizTopicPage extends StatelessWidget {
  const QuizTopicPage({required this.subjectId, super.key});

  static const mixedTopicId = 'all';

  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final subject = QuizSubject.byId(subjectId);
    final topics = subject == null
        ? const []
        : QuizTopicRegistry.forSubject(subject);
    final language = Localizations.localeOf(context).languageCode;
    if (subject == null || topics.isEmpty) {
      return CalcademyScaffold(
        title: Text(context.l10n.t('quiz')),
        body: Center(
          child: EmptyState(
            key: const Key('quiz-topic-empty'),
            icon: Icons.school_outlined,
            title: context.l10n.t('quizNoQuestionsTitle'),
            body: context.l10n.t('quizNoQuestionsBody'),
          ),
        ),
      );
    }

    const repository = QuizQuestionRepository();
    final questionsByTopic = <String, int>{
      for (final topic in topics)
        topic.id: repository.questions
            .where((question) => question.topicId == topic.id)
            .length,
    };

    return CalcademyScaffold(
      title: Text(subject.title(language)),
      body: SafeArea(
        key: const Key('quiz-topic-safe-area'),
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            key: const Key('quiz-topic-scroll'),
            padding: AppBreakpoints.pagePadding(
              constraints.maxWidth,
            ).copyWith(top: AppSpacing.md, bottom: AppSpacing.xl),
            children: [
              StudyHeader(
                compact: true,
                eyebrow: subject.title(language),
                title: context.l10n.t('quizChooseTopic'),
              ),
              const SizedBox(height: AppSpacing.lg),
              QuizChoiceCard(
                key: const Key('quiz-topic-all'),
                title: context.l10n.t('quizAllTopics'),
                subtitle: context.l10n.t('quizAllTopicsDescription'),
                icon: Icons.shuffle_rounded,
                trailingText:
                    '${questionsByTopic.values.fold(0, (sum, count) => sum + count)} '
                    '${context.l10n.t('quizQuestionsAvailable')}',
                onTap: () => context.push(
                  '/quiz/subject/$subjectId/topic/$mixedTopicId',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SectionLabel(
                title: context.l10n.t('quizChooseTopic'),
                icon: Icons.list_alt_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final topic in topics) ...[
                QuizChoiceCard(
                  key: Key('quiz-topic-${topic.id}'),
                  title: topic.title(language),
                  subtitle: topic.description(language),
                  icon: Icons.functions_rounded,
                  trailingText:
                      '${questionsByTopic[topic.id]} '
                      '${context.l10n.t('quizQuestionsAvailable')}',
                  onTap: () => context.push(
                    '/quiz/subject/$subjectId/topic/${topic.id}',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

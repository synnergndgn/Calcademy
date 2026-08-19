import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/calcademy_design.dart';
import 'package:calcademy/core/widgets/empty_state.dart';
import 'package:calcademy/features/quiz/application/quiz_session_controller.dart';
import 'package:calcademy/features/quiz/data/quiz_topic_registry.dart';
import 'package:calcademy/features/quiz/domain/quiz_question.dart';
import 'package:calcademy/features/quiz/domain/quiz_session.dart';
import 'package:calcademy/features/quiz/domain/quiz_subject.dart';
import 'package:calcademy/features/quiz/presentation/quiz_labels.dart';
import 'package:calcademy/features/quiz/presentation/quiz_topic_page.dart';
import 'package:calcademy/features/quiz/presentation/widgets/quiz_choice_card.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Picks the answer mode and the feedback timing, then builds the session.
///
/// This is the only screen that writes a new session, which keeps the session
/// screen free of construction logic.
class QuizModeSelectionPage extends ConsumerStatefulWidget {
  const QuizModeSelectionPage({
    required this.subjectId,
    required this.topicId,
    super.key,
  });

  final String subjectId;
  final String topicId;

  @override
  ConsumerState<QuizModeSelectionPage> createState() =>
      _QuizModeSelectionPageState();
}

class _QuizModeSelectionPageState extends ConsumerState<QuizModeSelectionPage> {
  QuestionType _type = QuestionType.multipleChoice;
  QuizFeedbackMode _feedback = QuizFeedbackMode.immediate;

  QuizSessionConfig get _config => QuizSessionConfig(
    subject: QuizSubject.byId(widget.subjectId)!,
    topicIds: widget.topicId == QuizTopicPage.mixedTopicId
        ? const {}
        : {widget.topicId},
    questionType: _type,
    feedbackMode: _feedback,
  );

  @override
  Widget build(BuildContext context) {
    final subject = QuizSubject.byId(widget.subjectId);
    final topic = QuizTopicRegistry.byId(widget.topicId);
    final language = Localizations.localeOf(context).languageCode;
    if (subject == null ||
        (widget.topicId != QuizTopicPage.mixedTopicId && topic == null)) {
      return CalcademyScaffold(
        title: Text(context.l10n.t('quiz')),
        body: Center(
          child: EmptyState(
            key: const Key('quiz-mode-empty'),
            icon: Icons.school_outlined,
            title: context.l10n.t('quizNoQuestionsTitle'),
            body: context.l10n.t('quizNoQuestionsBody'),
          ),
        ),
      );
    }

    final available = ref.read(quizRepositoryProvider).availableCount(_config);
    final title = topic?.title(language) ?? context.l10n.t('quizAllTopics');

    return CalcademyScaffold(
      title: Text(title),
      body: SafeArea(
        key: const Key('quiz-mode-safe-area'),
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            key: const Key('quiz-mode-scroll'),
            padding: AppBreakpoints.pagePadding(
              constraints.maxWidth,
            ).copyWith(top: AppSpacing.md, bottom: AppSpacing.xl),
            children: [
              StudyHeader(
                compact: true,
                eyebrow: subject.title(language),
                title: context.l10n.t('quizChooseMode'),
                subtitle: title,
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final type in QuestionType.values) ...[
                QuizChoiceCard(
                  key: Key('quiz-mode-${type.name}'),
                  title: quizQuestionTypeLabel(context, type),
                  subtitle: quizQuestionTypeDescription(context, type),
                  icon: type == QuestionType.multipleChoice
                      ? Icons.checklist_rounded
                      : Icons.edit_note_rounded,
                  selected: _type == type,
                  onTap: () => setState(() => _type = type),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.xs),
              SectionLabel(
                title: context.l10n.t('quizFeedback'),
                icon: Icons.tune_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<QuizFeedbackMode>(
                key: const Key('quiz-feedback-selector'),
                showSelectedIcon: false,
                segments: [
                  for (final mode in QuizFeedbackMode.values)
                    ButtonSegment(
                      value: mode,
                      label: Text(
                        quizFeedbackModeLabel(context, mode),
                        key: Key('quiz-feedback-${mode.name}'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                selected: {_feedback},
                onSelectionChanged: (selection) =>
                    setState(() => _feedback = selection.single),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '$available ${context.l10n.t('quizQuestionsAvailable')}',
                key: const Key('quiz-mode-available'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                key: const Key('quiz-mode-start'),
                onPressed: available == 0 ? null : _start,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(context.l10n.t('quizStartSession')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _start() {
    ref.read(quizSessionProvider.notifier).start(_config);
    context.push('/quiz/session');
  }
}

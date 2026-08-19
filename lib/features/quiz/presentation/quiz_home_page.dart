import 'package:calcademy/app/theme/app_breakpoints.dart';
import 'package:calcademy/app/theme/app_spacing.dart';
import 'package:calcademy/core/widgets/calcademy_design.dart';
import 'package:calcademy/features/quiz/data/quiz_topic_registry.dart';
import 'package:calcademy/features/quiz/domain/quiz_subject.dart';
import 'package:calcademy/features/quiz/presentation/quiz_navigation.dart';
import 'package:calcademy/features/quiz/presentation/widgets/quiz_choice_card.dart';
import 'package:calcademy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Entry point of the quiz module: pick a subject.
///
/// Subjects without a question bank stay visible but unselectable, so the
/// roadmap is legible without pretending the content is there.
///
/// This is also where every exit from a session lands, so it carries a back
/// affordance of its own: reached with nothing underneath it -- a deep link,
/// or a stack that was reset -- it supplies both the app bar button and the
/// system back gesture, rather than leaving the learner on a page whose only
/// way back is out of the app.
class QuizHomePage extends StatelessWidget {
  const QuizHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final back = quizBackAffordance(context);
    return PopScope(
      canPop: back.canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) back.onBack?.call();
      },
      child: _body(context, language, back),
    );
  }

  Widget _body(BuildContext context, String language, QuizBackAffordance back) {
    return CalcademyScaffold(
      title: Text(context.l10n.t('quiz')),
      leading: back.onBack == null
          ? null
          : IconButton(
              key: const Key('quiz-home-back'),
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: back.onBack,
            ),
      body: SafeArea(
        key: const Key('quiz-home-safe-area'),
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            key: const Key('quiz-home-scroll'),
            padding: AppBreakpoints.pagePadding(
              constraints.maxWidth,
            ).copyWith(top: AppSpacing.md, bottom: AppSpacing.xl),
            children: [
              StudyHeader(
                eyebrow: context.l10n.t('quizHomeEyebrow'),
                title: context.l10n.t('quiz'),
                subtitle: context.l10n.t('quizHomeSubtitle'),
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionLabel(
                title: context.l10n.t('quizChooseSubject'),
                icon: Icons.library_books_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final subject in QuizSubject.values) ...[
                _SubjectCard(subject: subject, language: language),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.language});

  final QuizSubject subject;
  final String language;

  @override
  Widget build(BuildContext context) {
    final topics = QuizTopicRegistry.forSubject(subject);
    final available = topics.isNotEmpty;
    return QuizChoiceCard(
      key: Key('quiz-subject-${subject.id}'),
      title: subject.title(language),
      // The scope line is what tells a learner whether this is the right
      // subject; the topic count is a detail, so it rides below it.
      subtitle: available
          ? subject.subtitle(language)
          : context.l10n.t('quizSubjectLocked'),
      trailingText: available
          ? '${topics.length} ${context.l10n.t('quizTopics')}'
          : null,
      icon: _icon(subject),
      enabled: available,
      onTap: () => context.push('/quiz/subject/${subject.id}'),
    );
  }

  static IconData _icon(QuizSubject subject) => switch (subject) {
    QuizSubject.calculus => Icons.area_chart_rounded,
    QuizSubject.linearAlgebra => Icons.grid_on_rounded,
    QuizSubject.statistics => Icons.bar_chart_rounded,
    QuizSubject.differentialEquations => Icons.timeline_rounded,
    QuizSubject.financeMath => Icons.account_balance_wallet_rounded,
  };
}

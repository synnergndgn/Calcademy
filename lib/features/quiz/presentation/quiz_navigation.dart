import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Where the quiz module starts, and where every way out of a session lands.
const quizHomeLocation = '/quiz';

/// The page the app falls back to when the quiz is the only thing on the
/// stack, e.g. after a deep link straight into `/quiz`.
const quizFallbackLocation = '/home';

/// Leaves the session flow for [location], unwinding the pages the funnel
/// pushed instead of replacing the stack.
///
/// `go()` looks like the obvious call here and is what left the module with
/// its navigation bug: it rebuilds the stack from the route hierarchy, so the
/// Home page the learner pushed from is discarded. The Quiz page then comes
/// back as the only route -- no back button in the app bar, and a system back
/// gesture that leaves the app. Popping keeps everything below the funnel
/// exactly where it was.
///
/// How many pops that takes is worked out from the route stack before the
/// first one, not by watching the location change: a pop is only reflected in
/// the router's configuration once the outgoing route is really gone, so a
/// loop that re-read the location would pop straight past its target and
/// empty the stack.
void leaveQuizFlow(BuildContext context, {String location = quizHomeLocation}) {
  final router = GoRouter.of(context);
  final pops = _popsBackTo(
    router.routerDelegate.currentConfiguration,
    location,
  );
  if (pops <= 0) {
    // Nothing on the stack to unwind to -- a deep link into the session, or a
    // configuration that has already been reset. Rebuilding it is the only
    // way left, and [quizBackAffordance] is what keeps that survivable.
    router.go(location);
    return;
  }
  for (var index = 0; index < pops; index++) {
    if (!router.canPop()) break;
    router.pop();
  }
}

/// How many routes sit above [location] in [configuration], or -1 when that
/// page is not on the stack at all.
int _popsBackTo(RouteMatchList configuration, String location) {
  final matches = configuration.matches;
  final index = matches.lastIndexWhere(
    (match) => match.matchedLocation == location,
  );
  return index < 0 ? -1 : matches.length - 1 - index;
}

/// How a quiz page should offer "back" given what is underneath it.
///
/// When there is something to pop, the app bar's own leading button already
/// does the right thing and the system gesture follows it. When there is not
/// -- a deep link, or a stack that was reset -- the page has to supply both,
/// or the learner is left on a page with no way back and an Android back
/// gesture that quits the app.
class QuizBackAffordance {
  const QuizBackAffordance({required this.canPop, required this.onBack});

  final bool canPop;

  /// Null exactly when [canPop] is true, i.e. when the framework's own back
  /// handling is already correct.
  final VoidCallback? onBack;
}

QuizBackAffordance quizBackAffordance(
  BuildContext context, {
  String fallbackLocation = quizFallbackLocation,
}) {
  final canPop = Navigator.of(context).canPop();
  return QuizBackAffordance(
    canPop: canPop,
    onBack: canPop ? null : () => GoRouter.of(context).go(fallbackLocation),
  );
}

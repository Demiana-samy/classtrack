import 'package:flutter/material.dart';
import '../../common/todo_screen.dart';
import '../../quiz/data/quiz_question_draft.dart';

/// #7 Start Session — owner: Leader
///
/// In quiz mode, [questions] is the list returned by Quiz Builder (#8).
/// Send it unchanged to `SessionRepository.startSession` (`text`, `options`, `correctIndex`).
class StartSessionScreen extends StatelessWidget {
  const StartSessionScreen({
    super.key,
    required this.classId,
    this.questions,
  });

  final String classId;
  final List<QuizQuestionDraft>? questions;

  @override
  Widget build(BuildContext context) {
    final quizCount = questions?.length ?? 0;
    return TodoScreen(
      number: 7,
      title: 'Start Session',
      owner: 'Leader',
      detail:
          'classId=$classId. Mode, radius, GPS, then startSession. '
          'Quiz payload: $quizCount question(s).',
    );
  }
}

import 'package:flutter/material.dart';
import '../data/quiz_question_draft.dart';
import 'pages/quiz_screen.dart' as pages;

/// #14 Quiz
///
/// Student answers 5 questions.
class QuizScreen extends StatelessWidget {
  const QuizScreen({
    super.key,
    this.sessionId,
    this.questions,
  });

  final String? sessionId;
  final List<QuizQuestionDraft>? questions;

  @override
  Widget build(BuildContext context) {
    return pages.QuizScreen(
      sessionId: sessionId,
      questions: questions,
    );
  }
}

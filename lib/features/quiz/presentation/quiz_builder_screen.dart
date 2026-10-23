import 'package:flutter/material.dart';
import '../../common/todo_screen.dart';

/// #8 Quiz Builder — owner: Member 3
///
/// Must pop `List<QuizQuestionDraft>` of exactly 5 validated questions.
/// Start Session (#7) receives that list via `GoRouter` extra (already wired).
class QuizBuilderScreen extends StatelessWidget {
  const QuizBuilderScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return TodoScreen(
      number: 8,
      title: 'Quiz Builder',
      owner: 'Member 3',
      detail:
          'classId=$classId. Return List<QuizQuestionDraft> of 5 items. '
          'Use QuizDraftValidator before popping.',
    );
  }
}

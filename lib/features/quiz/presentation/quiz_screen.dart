import 'package:flutter/material.dart';
import '../../common/todo_screen.dart';

/// #14 Quiz — owner: Member 2
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return TodoScreen(
      number: 14,
      title: 'Quiz',
      owner: 'Member 2',
      detail: 'sessionId=$sessionId. Student answers 5 questions, then submitAttendance.',
    );
  }
}

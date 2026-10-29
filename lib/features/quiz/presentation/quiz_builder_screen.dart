import 'package:flutter/material.dart';
import 'pages/quiz_build_screen.dart';

/// #8 Quiz Builder
///
/// Teacher creates a quiz with 5 questions.
class QuizBuilderScreen extends StatelessWidget {
  const QuizBuilderScreen({super.key, this.classId});

  final String? classId;

  @override
  Widget build(BuildContext context) {
    return QuizBuildScreen(classId: classId);
  }
}
